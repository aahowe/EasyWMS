package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Product 产品模型
type Product struct {
	ID             int64   `json:"id" gorm:"column:id;primaryKey"`
	CategoryID     int64   `json:"categoryId" gorm:"column:category_id"`
	SkuCode        string  `json:"code" gorm:"column:sku_code"`
	Name           string  `json:"name" gorm:"column:name"`
	Specification  string  `json:"specification" gorm:"column:specification"`
	Unit           string  `json:"unit" gorm:"column:unit"`
	StockQty       float64 `json:"stockQty" gorm:"column:stock_qty"`
	AlertThreshold float64 `json:"alertThreshold" gorm:"column:alert_threshold"`
	Status         int     `json:"status" gorm:"column:status"`
	CreatedAt      string  `json:"createTime" gorm:"column:created_at"`
	UpdatedAt      string  `json:"updateTime" gorm:"column:updated_at"`
	// 关联字段
	CategoryName string `json:"category" gorm:"-"`
}

func (Product) TableName() string {
	return "base_product"
}

// Category 分类模型
type Category struct {
	ID       int64  `json:"id" gorm:"column:id;primaryKey"`
	Name     string `json:"name" gorm:"column:name"`
	ParentID int64  `json:"parentId" gorm:"column:parent_id"`
}

func (Category) TableName() string {
	return "base_category"
}

// ProductHandler 产品处理器
type ProductHandler struct {
	db *gorm.DB
}

// NewProductHandler 创建产品处理器
func NewProductHandler(db *gorm.DB) *ProductHandler {
	return &ProductHandler{db: db}
}

// GetProductList 获取产品列表
func (h *ProductHandler) GetProductList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "20"))
	keyword := c.Query("keyword")
	categoryStr := c.Query("category")
	statusStr := c.Query("status")

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize

	// 构建查询
	query := h.db.Model(&Product{})

	// 关键字搜索
	if keyword != "" {
		query = query.Where("sku_code LIKE ? OR name LIKE ?", "%"+keyword+"%", "%"+keyword+"%")
	}

	// 分类过滤
	if categoryStr != "" {
		categoryID, err := strconv.ParseInt(categoryStr, 10, 64)
		if err == nil && categoryID > 0 {
			query = query.Where("category_id = ?", categoryID)
		}
	}

	// 状态过滤
	if statusStr != "" {
		status, err := strconv.Atoi(statusStr)
		if err == nil {
			query = query.Where("status = ?", status)
		}
	}

	// 查询总数
	var total int64
	if err := query.Count(&total).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "查询失败: " + err.Error(),
		})
		return
	}

	// 查询数据
	var products []Product
	if err := query.Order("id DESC").Offset(offset).Limit(pageSize).Find(&products).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "查询失败: " + err.Error(),
		})
		return
	}

	// 加载分类名称
	categoryIDs := make([]int64, 0)
	for _, p := range products {
		categoryIDs = append(categoryIDs, p.CategoryID)
	}

	categoryMap := make(map[int64]string)
	if len(categoryIDs) > 0 {
		var categories []Category
		h.db.Where("id IN ?", categoryIDs).Find(&categories)
		for _, cat := range categories {
			categoryMap[cat.ID] = cat.Name
		}
	}

	// 填充分类名称
	for i := range products {
		products[i].CategoryName = categoryMap[products[i].CategoryID]
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"items": products,
			"total": total,
		},
	})
}

// GetProduct 获取产品详情
func (h *ProductHandler) GetProduct(c *gin.Context) {
	id := c.Param("id")

	var product Product
	if err := h.db.First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    404,
			"message": "产品不存在",
		})
		return
	}

	// 获取分类名称
	var category Category
	h.db.First(&category, product.CategoryID)
	product.CategoryName = category.Name

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": product,
	})
}

// CreateProduct 创建产品
func (h *ProductHandler) CreateProduct(c *gin.Context) {
	var req struct {
		CategoryID     int64   `json:"categoryId"`
		SkuCode        string  `json:"code"`
		Name           string  `json:"name"`
		Specification  string  `json:"specification"`
		Unit           string  `json:"unit"`
		AlertThreshold float64 `json:"alertThreshold"`
		Status         int     `json:"status"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "参数错误: " + err.Error(),
		})
		return
	}

	product := Product{
		CategoryID:     req.CategoryID,
		SkuCode:        req.SkuCode,
		Name:           req.Name,
		Specification:  req.Specification,
		Unit:           req.Unit,
		AlertThreshold: req.AlertThreshold,
		Status:         req.Status,
	}

	if err := h.db.Create(&product).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "创建失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "创建成功",
		"data":    product,
	})
}

// UpdateProduct 更新产品
func (h *ProductHandler) UpdateProduct(c *gin.Context) {
	id := c.Param("id")

	var product Product
	if err := h.db.First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    404,
			"message": "产品不存在",
		})
		return
	}

	var req struct {
		CategoryID     int64   `json:"categoryId"`
		SkuCode        string  `json:"code"`
		Name           string  `json:"name"`
		Specification  string  `json:"specification"`
		Unit           string  `json:"unit"`
		AlertThreshold float64 `json:"alertThreshold"`
		Status         int     `json:"status"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "参数错误: " + err.Error(),
		})
		return
	}

	updates := map[string]interface{}{
		"category_id":     req.CategoryID,
		"sku_code":        req.SkuCode,
		"name":            req.Name,
		"specification":   req.Specification,
		"unit":            req.Unit,
		"alert_threshold": req.AlertThreshold,
		"status":          req.Status,
	}

	if err := h.db.Model(&product).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "更新失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "更新成功",
	})
}

// DeleteProduct 删除产品
func (h *ProductHandler) DeleteProduct(c *gin.Context) {
	id := c.Param("id")

	var product Product
	if err := h.db.First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    404,
			"message": "产品不存在",
		})
		return
	}

	if err := h.db.Delete(&product).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "删除失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "删除成功",
	})
}
