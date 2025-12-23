package handler

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Inbound 入库单模型
type Inbound struct {
	ID              int64  `json:"id" gorm:"column:id;primaryKey"`
	InboundNo       string `json:"orderNo" gorm:"column:inbound_no"`
	SourceID        *int64 `json:"sourceId" gorm:"column:source_id"`
	IsTemporary     int    `json:"isTemporary" gorm:"column:is_temporary"`
	Status          int    `json:"statusCode" gorm:"column:status"`
	InboundDate     string `json:"inboundDate" gorm:"column:inbound_date"`
	WarehouseUserID *int64 `json:"operatorId" gorm:"column:warehouse_user_id"`
	Remark          string `json:"remark" gorm:"column:remark"`
	CreatedAt       string `json:"createTime" gorm:"column:created_at"`
	UpdatedAt       string `json:"updateTime" gorm:"column:updated_at"`
	// 关联字段
	Status_       string  `json:"status" gorm:"-"`
	Type          string  `json:"type" gorm:"-"`
	SourceOrderNo string  `json:"sourceOrderNo" gorm:"-"`
	OperatorName  string  `json:"operatorName" gorm:"-"`
	TotalQuantity float64 `json:"totalQuantity" gorm:"-"`
	WarehouseName string  `json:"warehouseName" gorm:"-"`
}

func (Inbound) TableName() string {
	return "biz_inbound"
}

// InboundItem 入库明细模型
type InboundItem struct {
	ID        int64   `json:"id" gorm:"column:id;primaryKey"`
	InboundID int64   `json:"inboundId" gorm:"column:inbound_id"`
	ProductID int64   `json:"productId" gorm:"column:product_id"`
	ActualQty float64 `json:"quantity" gorm:"column:actual_qty"`
	Location  string  `json:"locationName" gorm:"column:location"`
	CreatedAt string  `json:"createTime" gorm:"column:created_at"`
	// 关联字段
	ProductName string `json:"productName" gorm:"-"`
	ProductCode string `json:"productCode" gorm:"-"`
}

func (InboundItem) TableName() string {
	return "biz_inbound_item"
}

// InboundHandler 入库处理器
type InboundHandler struct {
	db *gorm.DB
}

// NewInboundHandler 创建入库处理器
func NewInboundHandler(db *gorm.DB) *InboundHandler {
	return &InboundHandler{db: db}
}

// GetInboundList 获取入库单列表
func (h *InboundHandler) GetInboundList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "20"))
	orderNo := c.Query("orderNo")
	status := c.Query("status")
	startDate := c.Query("startDate")
	endDate := c.Query("endDate")

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize
	query := h.db.Model(&Inbound{})

	if orderNo != "" {
		query = query.Where("inbound_no LIKE ?", "%"+orderNo+"%")
	}
	if status != "" {
		statusCode := 0
		if status == "completed" {
			statusCode = 1
		}
		query = query.Where("status = ?", statusCode)
	}
	if startDate != "" {
		query = query.Where("created_at >= ?", startDate)
	}
	if endDate != "" {
		query = query.Where("created_at <= ?", endDate+" 23:59:59")
	}

	var total int64
	query.Count(&total)

	var inbounds []Inbound
	query.Order("id DESC").Offset(offset).Limit(pageSize).Find(&inbounds)

	// 加载关联信息
	userIDs := make([]int64, 0)
	sourceIDs := make([]int64, 0)
	inboundIDs := make([]int64, 0)

	for _, i := range inbounds {
		if i.WarehouseUserID != nil {
			userIDs = append(userIDs, *i.WarehouseUserID)
		}
		if i.SourceID != nil {
			sourceIDs = append(sourceIDs, *i.SourceID)
		}
		inboundIDs = append(inboundIDs, i.ID)
	}

	// 用户名映射
	userMap := make(map[int64]string)
	if len(userIDs) > 0 {
		var users []struct {
			ID       int64  `gorm:"column:id"`
			RealName string `gorm:"column:real_name"`
		}
		h.db.Table("sys_user").Where("id IN ?", userIDs).Find(&users)
		for _, u := range users {
			userMap[u.ID] = u.RealName
		}
	}

	// 采购单号映射
	sourceMap := make(map[int64]string)
	if len(sourceIDs) > 0 {
		var procurements []struct {
			ID      int64  `gorm:"column:id"`
			OrderNo string `gorm:"column:order_no"`
		}
		h.db.Table("biz_procurement").Where("id IN ?", sourceIDs).Find(&procurements)
		for _, p := range procurements {
			sourceMap[p.ID] = p.OrderNo
		}
	}

	// 计算总数量
	qtyMap := make(map[int64]float64)
	if len(inboundIDs) > 0 {
		var qtys []struct {
			InboundID int64   `gorm:"column:inbound_id"`
			Total     float64 `gorm:"column:total"`
		}
		h.db.Table("biz_inbound_item").
			Select("inbound_id, SUM(actual_qty) as total").
			Where("inbound_id IN ?", inboundIDs).
			Group("inbound_id").
			Find(&qtys)
		for _, q := range qtys {
			qtyMap[q.InboundID] = q.Total
		}
	}

	// 填充关联信息
	for i := range inbounds {
		if inbounds[i].WarehouseUserID != nil {
			inbounds[i].OperatorName = userMap[*inbounds[i].WarehouseUserID]
		}
		if inbounds[i].SourceID != nil {
			inbounds[i].SourceOrderNo = sourceMap[*inbounds[i].SourceID]
			inbounds[i].Type = "purchase"
		} else if inbounds[i].IsTemporary == 1 {
			inbounds[i].Type = "other"
		} else {
			inbounds[i].Type = "other"
		}
		inbounds[i].TotalQuantity = qtyMap[inbounds[i].ID]
		if inbounds[i].Status == 1 {
			inbounds[i].Status_ = "completed"
		} else {
			inbounds[i].Status_ = "draft"
		}
		inbounds[i].WarehouseName = "默认仓库"
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"items": inbounds,
			"total": total,
		},
	})
}

// GetInbound 获取入库单详情
func (h *InboundHandler) GetInbound(c *gin.Context) {
	id := c.Param("id")
	var inbound Inbound
	if err := h.db.First(&inbound, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "入库单不存在"})
		return
	}

	// 获取明细
	var items []InboundItem
	h.db.Where("inbound_id = ?", id).Find(&items)

	// 获取产品信息
	productIDs := make([]int64, 0)
	for _, item := range items {
		productIDs = append(productIDs, item.ProductID)
	}

	productMap := make(map[int64]Product)
	if len(productIDs) > 0 {
		var products []Product
		h.db.Where("id IN ?", productIDs).Find(&products)
		for _, p := range products {
			productMap[p.ID] = p
		}
	}

	for i := range items {
		if p, ok := productMap[items[i].ProductID]; ok {
			items[i].ProductName = p.Name
			items[i].ProductCode = p.SkuCode
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"id":          inbound.ID,
			"orderNo":     inbound.InboundNo,
			"sourceId":    inbound.SourceID,
			"status":      inbound.Status_,
			"inboundDate": inbound.InboundDate,
			"remark":      inbound.Remark,
			"createTime":  inbound.CreatedAt,
			"items":       items,
		},
	})
}

// CreateInbound 创建入库单
func (h *InboundHandler) CreateInbound(c *gin.Context) {
	var req struct {
		SourceID    *int64 `json:"sourceId"`
		IsTemporary int    `json:"isTemporary"`
		Remark      string `json:"remark"`
		Items       []struct {
			ProductID int64   `json:"productId"`
			Quantity  float64 `json:"quantity"`
			Location  string  `json:"location"`
		} `json:"items"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	userID, _ := c.Get("userID")
	userIDInt := userID.(int64)
	inboundNo := fmt.Sprintf("IN%s%03d", time.Now().Format("20060102150405"), time.Now().Nanosecond()%1000)

	inbound := Inbound{
		InboundNo:       inboundNo,
		SourceID:        req.SourceID,
		IsTemporary:     req.IsTemporary,
		Status:          0,
		WarehouseUserID: &userIDInt,
		Remark:          req.Remark,
	}

	tx := h.db.Begin()

	if err := tx.Create(&inbound).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建失败"})
		return
	}

	for _, item := range req.Items {
		inboundItem := InboundItem{
			InboundID: inbound.ID,
			ProductID: item.ProductID,
			ActualQty: item.Quantity,
			Location:  item.Location,
		}
		if err := tx.Create(&inboundItem).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建明细失败"})
			return
		}
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "创建成功", "data": inbound})
}

// UpdateInbound 更新入库单
func (h *InboundHandler) UpdateInbound(c *gin.Context) {
	id := c.Param("id")
	var inbound Inbound
	if err := h.db.First(&inbound, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "入库单不存在"})
		return
	}

	var req struct {
		Status string `json:"status"`
		Remark string `json:"remark"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	statusCode := 0
	if req.Status == "completed" {
		statusCode = 1
	}

	tx := h.db.Begin()

	// 如果状态变为已完成，需要更新库存
	if statusCode == 1 && inbound.Status == 0 {
		var items []InboundItem
		h.db.Where("inbound_id = ?", id).Find(&items)

		for _, item := range items {
			// 更新产品库存
			tx.Model(&Product{}).Where("id = ?", item.ProductID).
				Update("stock_qty", gorm.Expr("stock_qty + ?", item.ActualQty))

			// 记录库存流水
			stockLog := StockLog{
				ProductID:  item.ProductID,
				Type:       "IN",
				ChangeQty:  item.ActualQty,
				RelatedNo:  inbound.InboundNo,
				OperatorID: inbound.WarehouseUserID,
			}

			// 获取当前库存
			var product Product
			tx.First(&product, item.ProductID)
			stockLog.SnapshotQty = product.StockQty

			tx.Create(&stockLog)
		}

		// 更新入库时间
		now := time.Now().Format("2006-01-02 15:04:05")
		tx.Model(&inbound).Updates(map[string]interface{}{
			"status":       statusCode,
			"inbound_date": now,
			"remark":       req.Remark,
		})
	} else {
		tx.Model(&inbound).Updates(map[string]interface{}{
			"status": statusCode,
			"remark": req.Remark,
		})
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "更新成功"})
}

// DeleteInbound 删除入库单
func (h *InboundHandler) DeleteInbound(c *gin.Context) {
	id := c.Param("id")

	var inbound Inbound
	if err := h.db.First(&inbound, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "入库单不存在"})
		return
	}

	if inbound.Status == 1 {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "已完成的入库单不能删除"})
		return
	}

	tx := h.db.Begin()
	tx.Where("inbound_id = ?", id).Delete(&InboundItem{})
	tx.Delete(&Inbound{}, id)
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "删除成功"})
}
