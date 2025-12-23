package handler

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Procurement 采购单模型
type Procurement struct {
	ID           int64   `json:"id" gorm:"column:id;primaryKey"`
	OrderNo      string  `json:"orderNo" gorm:"column:order_no"`
	ApplicantID  int64   `json:"applicantId" gorm:"column:applicant_id"`
	SupplierID   int64   `json:"supplierId" gorm:"column:supplier_id"`
	Status       string  `json:"status" gorm:"column:status"`
	Reason       string  `json:"reason" gorm:"column:reason"`
	ExpectedDate string  `json:"expectedDate" gorm:"column:expected_date"`
	CreatedAt    string  `json:"createTime" gorm:"column:created_at"`
	UpdatedAt    string  `json:"updateTime" gorm:"column:updated_at"`
	TotalAmount  float64 `json:"totalAmount" gorm:"-"`
	// 关联字段
	ApplicantName string `json:"applicantName" gorm:"-"`
	SupplierName  string `json:"supplierName" gorm:"-"`
}

func (Procurement) TableName() string {
	return "biz_procurement"
}

// ProcurementItem 采购明细模型
type ProcurementItem struct {
	ID            int64   `json:"id" gorm:"column:id;primaryKey"`
	ProcurementID int64   `json:"procurementId" gorm:"column:procurement_id"`
	ProductID     int64   `json:"productId" gorm:"column:product_id"`
	PlanQty       float64 `json:"quantity" gorm:"column:plan_qty"`
	UnitPrice     float64 `json:"price" gorm:"column:unit_price"`
	Amount        float64 `json:"amount" gorm:"-"`
	CreatedAt     string  `json:"createTime" gorm:"column:created_at"`
	// 关联字段
	ProductName string `json:"productName" gorm:"-"`
	ProductCode string `json:"productCode" gorm:"-"`
}

func (ProcurementItem) TableName() string {
	return "biz_procurement_item"
}

// ProcurementHandler 采购处理器
type ProcurementHandler struct {
	db *gorm.DB
}

// NewProcurementHandler 创建采购处理器
func NewProcurementHandler(db *gorm.DB) *ProcurementHandler {
	return &ProcurementHandler{db: db}
}

// GetProcurementList 获取采购单列表
func (h *ProcurementHandler) GetProcurementList(c *gin.Context) {
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
	query := h.db.Model(&Procurement{})

	if orderNo != "" {
		query = query.Where("order_no LIKE ?", "%"+orderNo+"%")
	}
	if status != "" {
		query = query.Where("status = ?", status)
	}
	if startDate != "" {
		query = query.Where("created_at >= ?", startDate)
	}
	if endDate != "" {
		query = query.Where("created_at <= ?", endDate+" 23:59:59")
	}

	var total int64
	query.Count(&total)

	var procurements []Procurement
	query.Order("id DESC").Offset(offset).Limit(pageSize).Find(&procurements)

	// 加载关联信息
	userIDs := make([]int64, 0)
	supplierIDs := make([]int64, 0)
	procurementIDs := make([]int64, 0)

	for _, p := range procurements {
		userIDs = append(userIDs, p.ApplicantID)
		if p.SupplierID > 0 {
			supplierIDs = append(supplierIDs, p.SupplierID)
		}
		procurementIDs = append(procurementIDs, p.ID)
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

	// 供应商名映射
	supplierMap := make(map[int64]string)
	if len(supplierIDs) > 0 {
		var suppliers []Supplier
		h.db.Where("id IN ?", supplierIDs).Find(&suppliers)
		for _, s := range suppliers {
			supplierMap[s.ID] = s.Name
		}
	}

	// 计算总金额
	amountMap := make(map[int64]float64)
	if len(procurementIDs) > 0 {
		var amounts []struct {
			ProcurementID int64   `gorm:"column:procurement_id"`
			Total         float64 `gorm:"column:total"`
		}
		h.db.Table("biz_procurement_item").
			Select("procurement_id, SUM(plan_qty * COALESCE(unit_price, 0)) as total").
			Where("procurement_id IN ?", procurementIDs).
			Group("procurement_id").
			Find(&amounts)
		for _, a := range amounts {
			amountMap[a.ProcurementID] = a.Total
		}
	}

	// 填充关联信息
	for i := range procurements {
		procurements[i].ApplicantName = userMap[procurements[i].ApplicantID]
		procurements[i].SupplierName = supplierMap[procurements[i].SupplierID]
		procurements[i].TotalAmount = amountMap[procurements[i].ID]
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"items": procurements,
			"total": total,
		},
	})
}

// GetProcurement 获取采购单详情
func (h *ProcurementHandler) GetProcurement(c *gin.Context) {
	id := c.Param("id")
	var procurement Procurement
	if err := h.db.First(&procurement, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "采购单不存在"})
		return
	}

	// 获取明细
	var items []ProcurementItem
	h.db.Where("procurement_id = ?", id).Find(&items)

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
		items[i].Amount = items[i].PlanQty * items[i].UnitPrice
	}

	// 获取供应商和申请人信息
	var user struct {
		RealName string `gorm:"column:real_name"`
	}
	h.db.Table("sys_user").Where("id = ?", procurement.ApplicantID).First(&user)
	procurement.ApplicantName = user.RealName

	var supplier Supplier
	h.db.First(&supplier, procurement.SupplierID)
	procurement.SupplierName = supplier.Name

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"id":            procurement.ID,
			"orderNo":       procurement.OrderNo,
			"supplierId":    procurement.SupplierID,
			"supplierName":  procurement.SupplierName,
			"applicantId":   procurement.ApplicantID,
			"applicantName": procurement.ApplicantName,
			"status":        procurement.Status,
			"reason":        procurement.Reason,
			"expectedDate":  procurement.ExpectedDate,
			"createTime":    procurement.CreatedAt,
			"items":         items,
		},
	})
}

// CreateProcurement 创建采购单
func (h *ProcurementHandler) CreateProcurement(c *gin.Context) {
	var req struct {
		SupplierID   int64  `json:"supplierId"`
		Reason       string `json:"reason"`
		ExpectedDate string `json:"expectedDate"`
		Items        []struct {
			ProductID int64   `json:"productId"`
			Quantity  float64 `json:"quantity"`
			Price     float64 `json:"price"`
		} `json:"items"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	// 获取当前用户ID
	userID, _ := c.Get("userID")

	// 生成单号
	orderNo := fmt.Sprintf("PO%s%03d", time.Now().Format("20060102150405"), time.Now().Nanosecond()%1000)

	procurement := Procurement{
		OrderNo:      orderNo,
		ApplicantID:  userID.(int64),
		SupplierID:   req.SupplierID,
		Status:       "PENDING",
		Reason:       req.Reason,
		ExpectedDate: req.ExpectedDate,
	}

	tx := h.db.Begin()

	if err := tx.Create(&procurement).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建失败"})
		return
	}

	// 创建明细
	for _, item := range req.Items {
		procurementItem := ProcurementItem{
			ProcurementID: procurement.ID,
			ProductID:     item.ProductID,
			PlanQty:       item.Quantity,
			UnitPrice:     item.Price,
		}
		if err := tx.Create(&procurementItem).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建明细失败"})
			return
		}
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "创建成功", "data": procurement})
}

// UpdateProcurement 更新采购单
func (h *ProcurementHandler) UpdateProcurement(c *gin.Context) {
	id := c.Param("id")
	var procurement Procurement
	if err := h.db.First(&procurement, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "采购单不存在"})
		return
	}

	var req struct {
		SupplierID   int64  `json:"supplierId"`
		Status       string `json:"status"`
		Reason       string `json:"reason"`
		ExpectedDate string `json:"expectedDate"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	updates := map[string]interface{}{
		"supplier_id":   req.SupplierID,
		"status":        req.Status,
		"reason":        req.Reason,
		"expected_date": req.ExpectedDate,
	}

	h.db.Model(&procurement).Updates(updates)
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "更新成功"})
}

// DeleteProcurement 删除采购单
func (h *ProcurementHandler) DeleteProcurement(c *gin.Context) {
	id := c.Param("id")

	tx := h.db.Begin()
	// 先删除明细
	tx.Where("procurement_id = ?", id).Delete(&ProcurementItem{})
	// 再删除主表
	tx.Delete(&Procurement{}, id)
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "删除成功"})
}
