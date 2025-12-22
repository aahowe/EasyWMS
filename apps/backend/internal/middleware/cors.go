package middleware

import (
	"easywms/internal/config"

	"github.com/gin-gonic/gin"
)

// CORS 跨域中间件
func CORS(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		method := c.Request.Method
		origin := c.Request.Header.Get("Origin")

		// 设置CORS头
		c.Header("Access-Control-Allow-Origin", origin)
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")
		c.Header("Access-Control-Expose-Headers", "Content-Length")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Header("Access-Control-Max-Age", "43200")

		// 处理OPTIONS请求
		if method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
