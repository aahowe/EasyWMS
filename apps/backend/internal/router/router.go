package router

import (
	"easywms/internal/config"
	"easywms/internal/middleware"

	"github.com/gin-gonic/gin"
)

// SetupRouter 设置路由
func SetupRouter(cfg *config.Config) *gin.Engine {
	r := gin.Default()

	// 应用中间件
	r.Use(middleware.CORS(cfg))
	r.Use(middleware.Logger())

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"message": "EasyWMS API is running",
		})
	})

	// API路由组
	api := r.Group("/api")
	{
		// 认证路由（无需JWT）
		auth := api.Group("/auth")
		{
			auth.POST("/login", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Login endpoint"})
			})
			auth.POST("/logout", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Logout endpoint"})
			})
		}

		// 需要认证的路由
		authorized := api.Group("")
		authorized.Use(middleware.JWTAuth(cfg))
		{
			// 基础数据管理
			authorized.GET("/products", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Get products"})
			})
			authorized.POST("/products", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Create product"})
			})

			// 采购管理
			authorized.GET("/procurements", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Get procurements"})
			})
			authorized.POST("/procurements", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Create procurement"})
			})

			// 入库管理
			authorized.GET("/inbounds", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Get inbounds"})
			})
			authorized.POST("/inbounds", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Create inbound"})
			})

			// 出库管理
			authorized.GET("/outbounds", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Get outbounds"})
			})
			authorized.POST("/outbounds", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Create outbound"})
			})

			// 统计与盘点
			authorized.GET("/inventory/stock", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Get stock"})
			})
			authorized.POST("/inventory/checks", func(c *gin.Context) {
				c.JSON(200, gin.H{"message": "Create inventory check"})
			})
		}
	}

	return r
}
