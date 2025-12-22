package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Response 统一响应结构
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Success 成功响应
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    0,
		Message: "success",
		Data:    data,
	})
}

// SuccessWithMessage 带消息的成功响应
func SuccessWithMessage(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    0,
		Message: message,
		Data:    data,
	})
}

// Error 错误响应
func Error(c *gin.Context, code int, message string) {
	c.JSON(http.StatusOK, Response{
		Code:    code,
		Message: message,
	})
}

// BadRequest 400错误
func BadRequest(c *gin.Context, message string) {
	c.JSON(http.StatusBadRequest, Response{
		Code:    400,
		Message: message,
	})
}

// Unauthorized 401错误
func Unauthorized(c *gin.Context, message string) {
	c.JSON(http.StatusUnauthorized, Response{
		Code:    401,
		Message: message,
	})
}

// Forbidden 403错误
func Forbidden(c *gin.Context, message string) {
	c.JSON(http.StatusForbidden, Response{
		Code:    403,
		Message: message,
	})
}

// NotFound 404错误
func NotFound(c *gin.Context, message string) {
	c.JSON(http.StatusNotFound, Response{
		Code:    404,
		Message: message,
	})
}

// InternalServerError 500错误
func InternalServerError(c *gin.Context, message string) {
	c.JSON(http.StatusInternalServerError, Response{
		Code:    500,
		Message: message,
	})
}
