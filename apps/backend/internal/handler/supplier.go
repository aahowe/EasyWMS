package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Supplier 供应商模型
type Supplier struct {
	ID        int64  `json:"id" gorm:"column:id;primaryKey"`
	Name      string `json:"name" gorm:"column:name"`
	Contact   string `json:"contact" gorm:"column:contact"`
	Phone     string `json:"phone" gorm:"column:phone"`
	Address   string `json:"address" gorm:"column:address"`
	Status    int    `json:"status" gorm:"column:status"`
	CreatedAt string `json:"createTime" gorm:"column:created_at"`
	UpdatedAt string `json:"updateTime" gorm:"column:updated_at"`
}

func (Supplier) TableName() string {
	return "base_supplier"
}

// SupplierHandler 供应商处理器
type SupplierHandler struct {
	db *gorm.DB
}

// NewSupplierHandler 创建供应商处理器
func NewSupplierHandler(db *gorm.DB) *SupplierHandler {
	return &SupplierHandler{db: db}
}

// GetSupplierList 获取供应商列表
func (h *SupplierHandler) GetSupplierList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "20"))
	keyword := c.Query("keyword")
	statusStr := c.Query("status")

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize
	query := h.db.Model(&Supplier{})

	if keyword != "" {
		query = query.Where("name LIKE ? OR contact LIKE ?", "%"+keyword+"%", "%"+keyword+"%")
	}

	if statusStr != "" {
		status, err := strconv.Atoi(statusStr)
		if err == nil {
			query = query.Where("status = ?", status)
		}
	}

	var total int64
	query.Count(&total)

	var suppliers []Supplier
	query.Order("id DESC").Offset(offset).Limit(pageSize).Find(&suppliers)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"items": suppliers,
			"total": total,
		},
	})
}

// GetSupplier 获取供应商详情
func (h *SupplierHandler) GetSupplier(c *gin.Context) {
	id := c.Param("id")
	var supplier Supplier
	if err := h.db.First(&supplier, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "供应商不存在"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"code": 0, "data": supplier})
}

// CreateSupplier 创建供应商
func (h *SupplierHandler) CreateSupplier(c *gin.Context) {
	var req struct {
		Name    string `json:"name"`
		Contact string `json:"contact"`
		Phone   string `json:"phone"`
		Address string `json:"address"`
		Status  int    `json:"status"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	supplier := Supplier{
		Name:    req.Name,
		Contact: req.Contact,
		Phone:   req.Phone,
		Address: req.Address,
		Status:  req.Status,
	}

	if err := h.db.Create(&supplier).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "创建成功", "data": supplier})
}

// UpdateSupplier 更新供应商
func (h *SupplierHandler) UpdateSupplier(c *gin.Context) {
	id := c.Param("id")
	var supplier Supplier
	if err := h.db.First(&supplier, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "供应商不存在"})
		return
	}

	var req struct {
		Name    string `json:"name"`
		Contact string `json:"contact"`
		Phone   string `json:"phone"`
		Address string `json:"address"`
		Status  int    `json:"status"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	h.db.Model(&supplier).Updates(map[string]interface{}{
		"name":    req.Name,
		"contact": req.Contact,
		"phone":   req.Phone,
		"address": req.Address,
		"status":  req.Status,
	})

	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "更新成功"})
}

// DeleteSupplier 删除供应商
func (h *SupplierHandler) DeleteSupplier(c *gin.Context) {
	id := c.Param("id")
	if err := h.db.Delete(&Supplier{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "删除失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "删除成功"})
}

