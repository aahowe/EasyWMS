package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// StockLog 库存流水模型
type StockLog struct {
	ID          int64     `json:"id" gorm:"column:id;primaryKey"`
	ProductID   int64     `json:"productId" gorm:"column:product_id"`
	Type        string    `json:"type" gorm:"column:type"`
	ChangeQty   float64   `json:"changeQty" gorm:"column:change_qty"`
	SnapshotQty float64   `json:"snapshotQty" gorm:"column:snapshot_qty"`
	RelatedNo   string    `json:"relatedNo" gorm:"column:related_no"`
	OperatorID  *int64    `json:"operatorId" gorm:"column:operator_id"`
	CreatedAt   time.Time `json:"createTime" gorm:"column:created_at;autoCreateTime"`
}

func (StockLog) TableName() string {
	return "biz_stock_log"
}

// StockHandler 库存处理器
type StockHandler struct {
	db *gorm.DB
}

// NewStockHandler 创建库存处理器
func NewStockHandler(db *gorm.DB) *StockHandler {
	return &StockHandler{db: db}
}

// GetStockList 获取库存列表
func (h *StockHandler) GetStockList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "20"))
	productName := c.Query("productName")
	lowStock := c.Query("lowStock")

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize
	query := h.db.Model(&Product{})

	if productName != "" {
		query = query.Where("name LIKE ? OR sku_code LIKE ?", "%"+productName+"%", "%"+productName+"%")
	}

	if lowStock == "true" {
		query = query.Where("stock_qty <= alert_threshold")
	}

	var total int64
	query.Count(&total)

	var products []Product
	query.Order("id DESC").Offset(offset).Limit(pageSize).Find(&products)

	// 加载分类信息
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

	// 构建库存数据
	type StockItem struct {
		ID                int64   `json:"id"`
		ProductID         int64   `json:"productId"`
		ProductCode       string  `json:"productCode"`
		ProductName       string  `json:"productName"`
		Category          string  `json:"category"`
		Specification     string  `json:"specification"`
		Unit              string  `json:"unit"`
		WarehouseID       string  `json:"warehouseId"`
		WarehouseName     string  `json:"warehouseName"`
		Quantity          float64 `json:"quantity"`
		AvailableQuantity float64 `json:"availableQuantity"`
		AlertThreshold    float64 `json:"alertThreshold"`
		UpdateTime        string  `json:"updateTime"`
	}

	items := make([]StockItem, len(products))
	for i, p := range products {
		items[i] = StockItem{
			ID:                p.ID,
			ProductID:         p.ID,
			ProductCode:       p.SkuCode,
			ProductName:       p.Name,
			Category:          categoryMap[p.CategoryID],
			Specification:     p.Specification,
			Unit:              p.Unit,
			WarehouseID:       "1",
			WarehouseName:     "默认仓库",
			Quantity:          p.StockQty,
			AvailableQuantity: p.StockQty,
			AlertThreshold:    p.AlertThreshold,
			UpdateTime:        p.UpdatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"items": items,
			"total": total,
		},
	})
}

// GetStock 获取库存详情
func (h *StockHandler) GetStock(c *gin.Context) {
	id := c.Param("id")

	var product Product
	if err := h.db.First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "库存记录不存在"})
		return
	}

	var category Category
	h.db.First(&category, product.CategoryID)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"id":                product.ID,
			"productId":         product.ID,
			"productCode":       product.SkuCode,
			"productName":       product.Name,
			"category":          category.Name,
			"specification":     product.Specification,
			"unit":              product.Unit,
			"warehouseId":       "1",
			"warehouseName":     "默认仓库",
			"quantity":          product.StockQty,
			"availableQuantity": product.StockQty,
			"alertThreshold":    product.AlertThreshold,
			"updateTime":        product.UpdatedAt,
		},
	})
}

// GetStockLogs 获取库存流水
func (h *StockHandler) GetStockLogs(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "20"))
	productID := c.Query("productId")
	logType := c.Query("type")

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize
	query := h.db.Model(&StockLog{})

	if productID != "" {
		query = query.Where("product_id = ?", productID)
	}

	if logType != "" {
		query = query.Where("type = ?", logType)
	}

	var total int64
	query.Count(&total)

	var logs []StockLog
	query.Order("id DESC").Offset(offset).Limit(pageSize).Find(&logs)

	// 获取产品信息
	productIDs := make([]int64, 0)
	operatorIDs := make([]int64, 0)
	for _, log := range logs {
		productIDs = append(productIDs, log.ProductID)
		if log.OperatorID != nil {
			operatorIDs = append(operatorIDs, *log.OperatorID)
		}
	}

	productMap := make(map[int64]Product)
	if len(productIDs) > 0 {
		var products []Product
		h.db.Where("id IN ?", productIDs).Find(&products)
		for _, p := range products {
			productMap[p.ID] = p
		}
	}

	userMap := make(map[int64]string)
	if len(operatorIDs) > 0 {
		var users []struct {
			ID       int64  `gorm:"column:id"`
			RealName string `gorm:"column:real_name"`
		}
		h.db.Table("sys_user").Where("id IN ?", operatorIDs).Find(&users)
		for _, u := range users {
			userMap[u.ID] = u.RealName
		}
	}

	type LogItem struct {
		ID           int64   `json:"id"`
		ProductID    int64   `json:"productId"`
		ProductCode  string  `json:"productCode"`
		ProductName  string  `json:"productName"`
		Type         string  `json:"type"`
		ChangeQty    float64 `json:"changeQty"`
		SnapshotQty  float64 `json:"snapshotQty"`
		RelatedNo    string  `json:"relatedNo"`
		OperatorName string  `json:"operatorName"`
		CreateTime   string  `json:"createTime"`
	}

	items := make([]LogItem, len(logs))
	for i, log := range logs {
		p := productMap[log.ProductID]
		operatorName := ""
		if log.OperatorID != nil {
			operatorName = userMap[*log.OperatorID]
		}

		items[i] = LogItem{
			ID:           log.ID,
			ProductID:    log.ProductID,
			ProductCode:  p.SkuCode,
			ProductName:  p.Name,
			Type:         log.Type,
			ChangeQty:    log.ChangeQty,
			SnapshotQty:  log.SnapshotQty,
			RelatedNo:    log.RelatedNo,
			OperatorName: operatorName,
			CreateTime:   log.CreatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"items": items,
			"total": total,
		},
	})
}
