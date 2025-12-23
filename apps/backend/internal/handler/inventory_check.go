package handler

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// InventoryCheck 盘点单模型
type InventoryCheck struct {
	ID         int64  `json:"id" gorm:"column:id;primaryKey"`
	CheckNo    string `json:"checkNo" gorm:"column:check_no"`
	OperatorID int64  `json:"operatorId" gorm:"column:operator_id"`
	Status     string `json:"status" gorm:"column:status"`
	CheckDate  string `json:"checkDate" gorm:"column:check_date"`
	Remark     string `json:"remark" gorm:"column:remark"`
	CreatedAt  string `json:"createTime" gorm:"column:created_at"`
	UpdatedAt  string `json:"updateTime" gorm:"column:updated_at"`
	// 关联字段
	OperatorName  string `json:"operatorName" gorm:"-"`
	WarehouseID   string `json:"warehouseId" gorm:"-"`
	WarehouseName string `json:"warehouseName" gorm:"-"`
}

func (InventoryCheck) TableName() string {
	return "biz_inventory_check"
}

// InventoryCheckItem 盘点明细模型
type InventoryCheckItem struct {
	ID              int64   `json:"id" gorm:"column:id;primaryKey"`
	CheckID         int64   `json:"checkId" gorm:"column:check_id"`
	ProductID       int64   `json:"productId" gorm:"column:product_id"`
	SystemQty       float64 `json:"systemQuantity" gorm:"column:system_qty"`
	ActualQty       float64 `json:"actualQuantity" gorm:"column:actual_qty"`
	DifferenceQty   float64 `json:"differenceQuantity" gorm:"column:difference_qty"`
	Remark          string  `json:"remark" gorm:"column:remark"`
	CreatedAt       string  `json:"createTime" gorm:"column:created_at"`
	// 关联字段
	ProductName string `json:"productName" gorm:"-"`
	ProductCode string `json:"productCode" gorm:"-"`
}

func (InventoryCheckItem) TableName() string {
	return "biz_inventory_check_item"
}

// InventoryCheckHandler 盘点处理器
type InventoryCheckHandler struct {
	db *gorm.DB
}

// NewInventoryCheckHandler 创建盘点处理器
func NewInventoryCheckHandler(db *gorm.DB) *InventoryCheckHandler {
	return &InventoryCheckHandler{db: db}
}

// GetInventoryCheckList 获取盘点单列表
func (h *InventoryCheckHandler) GetInventoryCheckList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "20"))
	checkNo := c.Query("checkNo")
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
	query := h.db.Model(&InventoryCheck{})

	if checkNo != "" {
		query = query.Where("check_no LIKE ?", "%"+checkNo+"%")
	}
	if status != "" {
		// 状态映射
		statusMap := map[string]string{
			"draft":     "CHECKING",
			"checking":  "CHECKING",
			"completed": "FINISHED",
			"cancelled": "CANCELLED",
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

	var checks []InventoryCheck
	query.Order("id DESC").Offset(offset).Limit(pageSize).Find(&checks)

	// 加载用户信息
	userIDs := make([]int64, 0)
	for _, check := range checks {
		userIDs = append(userIDs, check.OperatorID)
	}

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

	// 填充关联信息和状态转换
	for i := range checks {
		checks[i].OperatorName = userMap[checks[i].OperatorID]
		checks[i].WarehouseID = "1"
		checks[i].WarehouseName = "默认仓库"

		// 状态转换
		switch checks[i].Status {
		case "CHECKING":
			checks[i].Status = "checking"
		case "FINISHED":
			checks[i].Status = "completed"
		case "CANCELLED":
			checks[i].Status = "cancelled"
		default:
			checks[i].Status = "draft"
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"items": checks,
			"total": total,
		},
	})
}

// GetInventoryCheck 获取盘点单详情
func (h *InventoryCheckHandler) GetInventoryCheck(c *gin.Context) {
	id := c.Param("id")
	var check InventoryCheck
	if err := h.db.First(&check, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "盘点单不存在"})
		return
	}

	// 获取明细
	var items []InventoryCheckItem
	h.db.Where("check_id = ?", id).Find(&items)

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

	// 获取操作员信息
	var user struct {
		RealName string `gorm:"column:real_name"`
	}
	h.db.Table("sys_user").Where("id = ?", check.OperatorID).First(&user)
	check.OperatorName = user.RealName

	// 状态转换
	dbStatus := check.Status
	switch dbStatus {
	case "CHECKING":
		check.Status = "checking"
	case "FINISHED":
		check.Status = "completed"
	case "CANCELLED":
		check.Status = "cancelled"
	default:
		check.Status = "draft"
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"id":            check.ID,
			"checkNo":       check.CheckNo,
			"warehouseId":   "1",
			"warehouseName": "默认仓库",
			"operatorId":    check.OperatorID,
			"operatorName":  check.OperatorName,
			"status":        check.Status,
			"checkDate":     check.CheckDate,
			"remark":        check.Remark,
			"createTime":    check.CreatedAt,
			"items":         items,
		},
	})
}

// CreateInventoryCheck 创建盘点单
func (h *InventoryCheckHandler) CreateInventoryCheck(c *gin.Context) {
	var req struct {
		Remark string `json:"remark"`
		Items  []struct {
			ProductID      int64   `json:"productId"`
			SystemQuantity float64 `json:"systemQuantity"`
			ActualQuantity float64 `json:"actualQuantity"`
			Remark         string  `json:"remark"`
		} `json:"items"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	userID, _ := c.Get("userID")
	userIDInt := userID.(int64)

	checkNo := fmt.Sprintf("CHK%s%03d", time.Now().Format("20060102150405"), time.Now().Nanosecond()%1000)

	check := InventoryCheck{
		CheckNo:    checkNo,
		OperatorID: userIDInt,
		Status:     "CHECKING",
		Remark:     req.Remark,
	}

	tx := h.db.Begin()

	if err := tx.Create(&check).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建失败"})
		return
	}

	for _, item := range req.Items {
		differenceQty := item.ActualQuantity - item.SystemQuantity

		checkItem := InventoryCheckItem{
			CheckID:       check.ID,
			ProductID:     item.ProductID,
			SystemQty:     item.SystemQuantity,
			ActualQty:     item.ActualQuantity,
			DifferenceQty: differenceQty,
			Remark:        item.Remark,
		}
		if err := tx.Create(&checkItem).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建明细失败"})
			return
		}
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "创建成功", "data": check})
}

// UpdateInventoryCheck 更新盘点单
func (h *InventoryCheckHandler) UpdateInventoryCheck(c *gin.Context) {
	id := c.Param("id")
	var check InventoryCheck
	if err := h.db.First(&check, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "盘点单不存在"})
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

	// 状态转换
	dbStatus := check.Status
	switch req.Status {
	case "draft", "checking":
		dbStatus = "CHECKING"
	case "completed":
		dbStatus = "FINISHED"
	case "cancelled":
		dbStatus = "CANCELLED"
	}

	tx := h.db.Begin()

	// 如果状态变为已完成，需要更新库存
	if dbStatus == "FINISHED" && check.Status == "CHECKING" {
		var items []InventoryCheckItem
		h.db.Where("check_id = ?", id).Find(&items)

		userID, _ := c.Get("userID")
		userIDInt := userID.(int64)

		for _, item := range items {
			if item.DifferenceQty != 0 {
				// 更新产品库存
				tx.Model(&Product{}).Where("id = ?", item.ProductID).
					Update("stock_qty", item.ActualQty)

				// 记录库存流水
				stockLog := StockLog{
					ProductID:   item.ProductID,
					Type:        "CHECK",
					ChangeQty:   item.DifferenceQty,
					SnapshotQty: item.ActualQty,
					RelatedNo:   check.CheckNo,
					OperatorID:  &userIDInt,
				}
				tx.Create(&stockLog)
			}
		}

		now := time.Now().Format("2006-01-02 15:04:05")
		tx.Model(&check).Updates(map[string]interface{}{
			"status":     dbStatus,
			"check_date": now,
			"remark":     req.Remark,
		})
	} else {
		tx.Model(&check).Updates(map[string]interface{}{
			"status": dbStatus,
			"remark": req.Remark,
		})
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "更新成功"})
}

// DeleteInventoryCheck 删除盘点单
func (h *InventoryCheckHandler) DeleteInventoryCheck(c *gin.Context) {
	id := c.Param("id")

	var check InventoryCheck
	if err := h.db.First(&check, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "盘点单不存在"})
		return
	}

	if check.Status == "FINISHED" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "已完成的盘点单不能删除"})
		return
	}

	tx := h.db.Begin()
	tx.Where("check_id = ?", id).Delete(&InventoryCheckItem{})
	tx.Delete(&InventoryCheck{}, id)
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "删除成功"})
}

