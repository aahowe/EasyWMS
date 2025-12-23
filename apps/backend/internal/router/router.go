package router

import (
	"easywms/internal/config"
	"easywms/internal/handler"
	"easywms/internal/middleware"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// SetupRouter 设置路由
func SetupRouter(cfg *config.Config, db *gorm.DB) *gin.Engine {
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

	// 创建处理器
	authHandler := handler.NewAuthHandler(db, cfg)
	dashboardHandler := handler.NewDashboardHandler(db)
	productHandler := handler.NewProductHandler(db)
	supplierHandler := handler.NewSupplierHandler(db)
	categoryHandler := handler.NewCategoryHandler(db)
	procurementHandler := handler.NewProcurementHandler(db)
	inboundHandler := handler.NewInboundHandler(db)
	outboundHandler := handler.NewOutboundHandler(db)
	stockHandler := handler.NewStockHandler(db)
	inventoryCheckHandler := handler.NewInventoryCheckHandler(db)

	// API路由组
	api := r.Group("/api")
	{
		// 认证路由（无需JWT）
		auth := api.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)
			auth.POST("/logout", authHandler.Logout)
		}

		// 需要认证的路由
		authorized := api.Group("")
		authorized.Use(middleware.JWTAuth(cfg))
		{
			// 用户相关
			authorized.GET("/user/info", authHandler.GetUserInfo)
			authorized.GET("/auth/codes", authHandler.GetAccessCodes)

			// 仪表盘统计接口
			authorized.GET("/dashboard/overview", dashboardHandler.GetOverviewStats)
			authorized.GET("/dashboard/stock-trend", dashboardHandler.GetStockTrend)
			authorized.GET("/dashboard/category-stock", dashboardHandler.GetCategoryStock)
			authorized.GET("/dashboard/low-stock", dashboardHandler.GetLowStockProducts)
			authorized.GET("/dashboard/activities", dashboardHandler.GetRecentActivities)

			// 基础数据管理 - 产品
			authorized.GET("/products", productHandler.GetProductList)
			authorized.GET("/products/:id", productHandler.GetProduct)
			authorized.POST("/products", productHandler.CreateProduct)
			authorized.PUT("/products/:id", productHandler.UpdateProduct)
			authorized.DELETE("/products/:id", productHandler.DeleteProduct)

			// 基础数据管理 - 供应商
			authorized.GET("/suppliers", supplierHandler.GetSupplierList)
			authorized.GET("/suppliers/:id", supplierHandler.GetSupplier)
			authorized.POST("/suppliers", supplierHandler.CreateSupplier)
			authorized.PUT("/suppliers/:id", supplierHandler.UpdateSupplier)
			authorized.DELETE("/suppliers/:id", supplierHandler.DeleteSupplier)

			// 基础数据管理 - 分类
			authorized.GET("/categories", categoryHandler.GetCategoryList)
			authorized.GET("/categories/tree", categoryHandler.GetCategoryTree)
			authorized.GET("/categories/:id", categoryHandler.GetCategory)
			authorized.POST("/categories", categoryHandler.CreateCategory)
			authorized.PUT("/categories/:id", categoryHandler.UpdateCategory)
			authorized.DELETE("/categories/:id", categoryHandler.DeleteCategory)

			// 采购管理
			authorized.GET("/procurements", procurementHandler.GetProcurementList)
			authorized.GET("/procurements/:id", procurementHandler.GetProcurement)
			authorized.POST("/procurements", procurementHandler.CreateProcurement)
			authorized.PUT("/procurements/:id", procurementHandler.UpdateProcurement)
			authorized.DELETE("/procurements/:id", procurementHandler.DeleteProcurement)

			// 入库管理
			authorized.GET("/inbounds", inboundHandler.GetInboundList)
			authorized.GET("/inbounds/:id", inboundHandler.GetInbound)
			authorized.POST("/inbounds", inboundHandler.CreateInbound)
			authorized.PUT("/inbounds/:id", inboundHandler.UpdateInbound)
			authorized.DELETE("/inbounds/:id", inboundHandler.DeleteInbound)

			// 出库管理
			authorized.GET("/outbounds", outboundHandler.GetOutboundList)
			authorized.GET("/outbounds/:id", outboundHandler.GetOutbound)
			authorized.POST("/outbounds", outboundHandler.CreateOutbound)
			authorized.PUT("/outbounds/:id", outboundHandler.UpdateOutbound)
			authorized.DELETE("/outbounds/:id", outboundHandler.DeleteOutbound)

			// 库存管理
			authorized.GET("/inventory/stock", stockHandler.GetStockList)
			authorized.GET("/inventory/stock/:id", stockHandler.GetStock)
			authorized.GET("/inventory/logs", stockHandler.GetStockLogs)

			// 盘点管理
			authorized.GET("/inventory/checks", inventoryCheckHandler.GetInventoryCheckList)
			authorized.GET("/inventory/checks/:id", inventoryCheckHandler.GetInventoryCheck)
			authorized.POST("/inventory/checks", inventoryCheckHandler.CreateInventoryCheck)
			authorized.PUT("/inventory/checks/:id", inventoryCheckHandler.UpdateInventoryCheck)
			authorized.DELETE("/inventory/checks/:id", inventoryCheckHandler.DeleteInventoryCheck)

			// 菜单接口
			authorized.GET("/menu/all", authHandler.GetMenus)
		}
	}

	return r
}
