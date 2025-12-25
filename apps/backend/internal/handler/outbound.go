package handler

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Outbound 出库单模型
type Outbound struct {
	ID           int64      `json:"id" gorm:"column:id;primaryKey"`
	OutboundNo   string     `json:"orderNo" gorm:"column:outbound_no"`
	ApplicantID  int64      `json:"applicantId" gorm:"column:applicant_id"`
	DeptID       int64      `json:"deptId" gorm:"column:dept_id"`
	Status       string     `json:"status" gorm:"column:status"`
	Purpose      string     `json:"purpose" gorm:"column:purpose"`
	ReviewerID   *int64     `json:"reviewerId" gorm:"column:reviewer_id"`
	ReviewTime   *time.Time `json:"reviewTime" gorm:"column:review_time"`
	OutboundDate *time.Time `json:"outboundDate" gorm:"column:outbound_date"`
	CreatedAt    time.Time  `json:"createTime" gorm:"column:created_at;autoCreateTime"`
	UpdatedAt    time.Time  `json:"updateTime" gorm:"column:updated_at;autoUpdateTime"`
	// 关联字段
	ApplicantName string  `json:"applicantName" gorm:"-"`
	DeptName      string  `json:"deptName" gorm:"-"`
	ReviewerName  string  `json:"reviewerName" gorm:"-"`
	TotalQuantity float64 `json:"totalQuantity" gorm:"-"`
	Type          string  `json:"type" gorm:"-"`
	WarehouseName string  `json:"warehouseName" gorm:"-"`
	OperatorName  string  `json:"operatorName" gorm:"-"`
}

func (Outbound) TableName() string {
	return "biz_outbound"
}

// OutboundItem 出库明细模型
type OutboundItem struct {
	ID         int64     `json:"id" gorm:"column:id;primaryKey"`
	OutboundID int64     `json:"outboundId" gorm:"column:outbound_id"`
	ProductID  int64     `json:"productId" gorm:"column:product_id"`
	ApplyQty   float64   `json:"quantity" gorm:"column:apply_qty"`
	ActualQty  *float64  `json:"pickedQuantity" gorm:"column:actual_qty"`
	CreatedAt  time.Time `json:"createTime" gorm:"column:created_at;autoCreateTime"`
	// 关联字段
	ProductName string `json:"productName" gorm:"-"`
	ProductCode string `json:"productCode" gorm:"-"`
}

func (OutboundItem) TableName() string {
	return "biz_outbound_item"
}

// OutboundHandler 出库处理器
type OutboundHandler struct {
	db *gorm.DB
}

// NewOutboundHandler 创建出库处理器
func NewOutboundHandler(db *gorm.DB) *OutboundHandler {
	return &OutboundHandler{db: db}
}

// GetOutboundList 获取出库单列表
func (h *OutboundHandler) GetOutboundList(c *gin.Context) {
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
	query := h.db.Model(&Outbound{})

	if orderNo != "" {
		query = query.Where("outbound_no LIKE ?", "%"+orderNo+"%")
	}
	if status != "" {
		// 状态映射
		statusMap := map[string]string{
			"pending":   "PENDING",
			"approved":  "APPROVED",
			"completed": "DONE",
			"cancelled": "REJECT",
		}
		if dbStatus, ok := statusMap[status]; ok {
			query = query.Where("status = ?", dbStatus)
		}
	}
	if startDate != "" {
		query = query.Where("created_at >= ?", startDate)
	}
	if endDate != "" {
		query = query.Where("created_at <= ?", endDate+" 23:59:59")
	}

	var total int64
	query.Count(&total)

	var outbounds []Outbound
	query.Order("id DESC").Offset(offset).Limit(pageSize).Find(&outbounds)

	// 加载关联信息
	userIDs := make([]int64, 0)
	deptIDs := make([]int64, 0)
	outboundIDs := make([]int64, 0)

	for _, o := range outbounds {
		userIDs = append(userIDs, o.ApplicantID)
		if o.ReviewerID != nil {
			userIDs = append(userIDs, *o.ReviewerID)
		}
		deptIDs = append(deptIDs, o.DeptID)
		outboundIDs = append(outboundIDs, o.ID)
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

	// 部门名映射
	deptMap := make(map[int64]string)
	if len(deptIDs) > 0 {
		var depts []struct {
			ID   int64  `gorm:"column:id"`
			Name string `gorm:"column:name"`
		}
		h.db.Table("base_department").Where("id IN ?", deptIDs).Find(&depts)
		for _, d := range depts {
			deptMap[d.ID] = d.Name
		}
	}

	// 计算总数量
	qtyMap := make(map[int64]float64)
	if len(outboundIDs) > 0 {
		var qtys []struct {
			OutboundID int64   `gorm:"column:outbound_id"`
			Total      float64 `gorm:"column:total"`
		}
		h.db.Table("biz_outbound_item").
			Select("outbound_id, SUM(apply_qty) as total").
			Where("outbound_id IN ?", outboundIDs).
			Group("outbound_id").
			Find(&qtys)
		for _, q := range qtys {
			qtyMap[q.OutboundID] = q.Total
		}
	}

	// 填充关联信息和状态转换
	for i := range outbounds {
		outbounds[i].ApplicantName = userMap[outbounds[i].ApplicantID]
		if outbounds[i].ReviewerID != nil {
			outbounds[i].ReviewerName = userMap[*outbounds[i].ReviewerID]
		}
		outbounds[i].DeptName = deptMap[outbounds[i].DeptID]
		outbounds[i].TotalQuantity = qtyMap[outbounds[i].ID]
		outbounds[i].Type = "other"
		outbounds[i].WarehouseName = "默认仓库"
		outbounds[i].OperatorName = outbounds[i].ApplicantName

		// 状态转换
		switch outbounds[i].Status {
		case "PENDING":
			outbounds[i].Status = "pending"
		case "APPROVED":
			outbounds[i].Status = "picking"
		case "DONE":
			outbounds[i].Status = "completed"
		case "REJECT":
			outbounds[i].Status = "cancelled"
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"items": outbounds,
			"total": total,
		},
	})
}

// GetOutbound 获取出库单详情
func (h *OutboundHandler) GetOutbound(c *gin.Context) {
	id := c.Param("id")
	var outbound Outbound
	if err := h.db.First(&outbound, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "出库单不存在"})
		return
	}

	// 获取明细
	var items []OutboundItem
	h.db.Where("outbound_id = ?", id).Find(&items)

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

	// 状态转换
	status := outbound.Status
	switch outbound.Status {
	case "PENDING":
		status = "pending"
	case "APPROVED":
		status = "picking"
	case "DONE":
		status = "completed"
	case "REJECT":
		status = "cancelled"
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"id":           outbound.ID,
			"orderNo":      outbound.OutboundNo,
			"applicantId":  outbound.ApplicantID,
			"deptId":       outbound.DeptID,
			"status":       status,
			"purpose":      outbound.Purpose,
			"outboundDate": outbound.OutboundDate,
			"createTime":   outbound.CreatedAt,
			"items":        items,
		},
	})
}

// CreateOutbound 创建出库单
func (h *OutboundHandler) CreateOutbound(c *gin.Context) {
	var req struct {
		Purpose string `json:"purpose"`
		Items   []struct {
			ProductID int64   `json:"productId"`
			Quantity  float64 `json:"quantity"`
		} `json:"items"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	userID, _ := c.Get("userID")
	userIDInt := userID.(int64)

	// 获取用户部门
	var user struct {
		DeptID int64 `gorm:"column:dept_id"`
	}
	h.db.Table("sys_user").Where("id = ?", userIDInt).First(&user)

	outboundNo := fmt.Sprintf("OUT%s%03d", time.Now().Format("20060102150405"), time.Now().Nanosecond()%1000)

	outbound := Outbound{
		OutboundNo:  outboundNo,
		ApplicantID: userIDInt,
		DeptID:      user.DeptID,
		Status:      "PENDING",
		Purpose:     req.Purpose,
	}

	tx := h.db.Begin()

	if err := tx.Create(&outbound).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建失败"})
		return
	}

	for _, item := range req.Items {
		outboundItem := OutboundItem{
			OutboundID: outbound.ID,
			ProductID:  item.ProductID,
			ApplyQty:   item.Quantity,
		}
		if err := tx.Create(&outboundItem).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建明细失败"})
			return
		}
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "创建成功", "data": outbound})
}

// UpdateOutbound 更新出库单
func (h *OutboundHandler) UpdateOutbound(c *gin.Context) {
	id := c.Param("id")
	var outbound Outbound
	if err := h.db.First(&outbound, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "出库单不存在"})
		return
	}

	var req struct {
		Status  string `json:"status"`
		Purpose string `json:"purpose"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	userID, _ := c.Get("userID")
	userIDInt := userID.(int64)

	// 状态转换
	dbStatus := outbound.Status
	switch req.Status {
	case "pending":
		dbStatus = "PENDING"
	case "approved", "picking":
		dbStatus = "APPROVED"
	case "completed":
		dbStatus = "DONE"
	case "cancelled":
		dbStatus = "REJECT"
	}

	tx := h.db.Begin()

	// 如果状态变为已完成，需要更新库存
	if dbStatus == "DONE" && outbound.Status != "DONE" {
		var items []OutboundItem
		h.db.Where("outbound_id = ?", id).Find(&items)

		for _, item := range items {
			actualQty := item.ApplyQty
			if item.ActualQty != nil {
				actualQty = *item.ActualQty
			}

			// 更新产品库存
			tx.Model(&Product{}).Where("id = ?", item.ProductID).
				Update("stock_qty", gorm.Expr("stock_qty - ?", actualQty))

			// 更新实发数量
			tx.Model(&item).Update("actual_qty", actualQty)

			// 记录库存流水
			stockLog := StockLog{
				ProductID:  item.ProductID,
				Type:       "OUT",
				ChangeQty:  -actualQty,
				RelatedNo:  outbound.OutboundNo,
				OperatorID: &userIDInt,
			}

			var product Product
			tx.First(&product, item.ProductID)
			stockLog.SnapshotQty = product.StockQty

			tx.Create(&stockLog)
		}

		now := time.Now()
		tx.Model(&outbound).Updates(map[string]interface{}{
			"status":        dbStatus,
			"outbound_date": now,
			"purpose":       req.Purpose,
		})
	} else if dbStatus == "APPROVED" && outbound.Status == "PENDING" {
		// 审批通过
		now := time.Now()
		tx.Model(&outbound).Updates(map[string]interface{}{
			"status":      dbStatus,
			"reviewer_id": userIDInt,
			"review_time": now,
			"purpose":     req.Purpose,
		})
	} else {
		tx.Model(&outbound).Updates(map[string]interface{}{
			"status":  dbStatus,
			"purpose": req.Purpose,
		})
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "更新成功"})
}

// DeleteOutbound 删除出库单
func (h *OutboundHandler) DeleteOutbound(c *gin.Context) {
	id := c.Param("id")

	var outbound Outbound
	if err := h.db.First(&outbound, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "出库单不存在"})
		return
	}

	if outbound.Status == "DONE" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "已完成的出库单不能删除"})
		return
	}

	tx := h.db.Begin()
	tx.Where("outbound_id = ?", id).Delete(&OutboundItem{})
	tx.Delete(&Outbound{}, id)
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "删除成功"})
}
