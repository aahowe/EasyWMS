package middleware

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
)

// Logger 日志中间件
func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		startTime := time.Now()

		// 处理请求
		c.Next()

		// 计算耗时
		latency := time.Since(startTime)

		// 获取状态码
		statusCode := c.Writer.Status()

		// 记录日志
		log.Printf("[%s] %s %s %d %v",
			c.Request.Method,
			c.Request.RequestURI,
			c.ClientIP(),
			statusCode,
			latency,
		)
	}
}
