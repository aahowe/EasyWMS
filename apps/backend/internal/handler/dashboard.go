package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// DashboardHandler 仪表盘处理器
type DashboardHandler struct {
	db *gorm.DB
}

// NewDashboardHandler 创建仪表盘处理器
func NewDashboardHandler(db *gorm.DB) *DashboardHandler {
	return &DashboardHandler{db: db}
}

// OverviewStats 概览统计数据
type OverviewStats struct {
	ProductCount     int64   `json:"productCount"`     // 产品数量
	TotalStock       float64 `json:"totalStock"`       // 总库存量
	PendingInbound   int64   `json:"pendingInbound"`   // 待入库单数
	PendingOutbound  int64   `json:"pendingOutbound"`  // 待出库单数
	LowStockCount    int64   `json:"lowStockCount"`    // 低库存预警数
	TodayInbound     int64   `json:"todayInbound"`     // 今日入库数
	TodayOutbound    int64   `json:"todayOutbound"`    // 今日出库数
	ProcurementCount int64   `json:"procurementCount"` // 采购单数量
}

// GetOverviewStats 获取概览统计
func (h *DashboardHandler) GetOverviewStats(c *gin.Context) {
	var stats OverviewStats

	// 产品数量
	h.db.Table("base_product").Where("status = ?", 1).Count(&stats.ProductCount)

	// 总库存量
	h.db.Table("base_product").Select("COALESCE(SUM(stock_qty), 0)").Scan(&stats.TotalStock)

	// 待入库单数 (状态为待入库)
	h.db.Table("biz_inbound").Where("status = ?", "PENDING").Count(&stats.PendingInbound)

	// 待出库单数 (状态为待出库)
	h.db.Table("biz_outbound").Where("status = ?", "PENDING").Count(&stats.PendingOutbound)

	// 低库存预警数 (库存低于预警阈值)
	h.db.Table("base_product").Where("stock_qty < alert_threshold AND status = ?", 1).Count(&stats.LowStockCount)

	// 今日入库数
	today := time.Now().Format("2006-01-02")
	h.db.Table("biz_inbound").Where("DATE(created_at) = ? AND status = ?", today, "COMPLETED").Count(&stats.TodayInbound)

	// 今日出库数
	h.db.Table("biz_outbound").Where("DATE(created_at) = ? AND status = ?", today, "COMPLETED").Count(&stats.TodayOutbound)

	// 采购单数量
	h.db.Table("biz_procurement").Count(&stats.ProcurementCount)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": stats,
	})
}

// StockTrendItem 库存趋势项
type StockTrendItem struct {
	Date    string  `json:"date"`
	Inbound float64 `json:"inbound"`
	Outbound float64 `json:"outbound"`
}

// GetStockTrend 获取最近7天库存变化趋势
func (h *DashboardHandler) GetStockTrend(c *gin.Context) {
	var trends []StockTrendItem

	// 获取最近7天的日期
	for i := 6; i >= 0; i-- {
		date := time.Now().AddDate(0, 0, -i).Format("2006-01-02")
		var inbound, outbound float64

		// 查询当天入库数量
		h.db.Table("biz_stock_log").
			Select("COALESCE(SUM(change_qty), 0)").
			Where("type = ? AND DATE(created_at) = ?", "IN", date).
			Scan(&inbound)

		// 查询当天出库数量
		h.db.Table("biz_stock_log").
			Select("COALESCE(SUM(ABS(change_qty)), 0)").
			Where("type = ? AND DATE(created_at) = ?", "OUT", date).
			Scan(&outbound)

		trends = append(trends, StockTrendItem{
			Date:    date,
			Inbound: inbound,
			Outbound: outbound,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": trends,
	})
}

// CategoryStock 分类库存
type CategoryStock struct {
	Name     string  `json:"name"`
	Quantity float64 `json:"quantity"`
}

// GetCategoryStock 获取分类库存分布
func (h *DashboardHandler) GetCategoryStock(c *gin.Context) {
	var items []CategoryStock

	h.db.Table("base_product p").
		Select("c.name, COALESCE(SUM(p.stock_qty), 0) as quantity").
		Joins("LEFT JOIN base_category c ON p.category_id = c.id").
		Where("p.status = ?", 1).
		Group("c.id, c.name").
		Scan(&items)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": items,
	})
}

// LowStockProduct 低库存产品
type LowStockProduct struct {
	ID             uint    `json:"id"`
	Name           string  `json:"name"`
	SkuCode        string  `json:"skuCode"`
	StockQty       float64 `json:"stockQty"`
	AlertThreshold float64 `json:"alertThreshold"`
}

// GetLowStockProducts 获取低库存产品列表
func (h *DashboardHandler) GetLowStockProducts(c *gin.Context) {
	var products []LowStockProduct

	h.db.Table("base_product").
		Select("id, name, sku_code, stock_qty, alert_threshold").
		Where("stock_qty < alert_threshold AND status = ?", 1).
		Order("stock_qty ASC").
		Limit(10).
		Scan(&products)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": products,
	})
}

// RecentActivity 最近动态
type RecentActivity struct {
	ID        uint   `json:"id"`
	Type      string `json:"type"`      // INBOUND, OUTBOUND, PROCUREMENT
	OrderNo   string `json:"orderNo"`
	Operator  string `json:"operator"`
	CreatedAt string `json:"createdAt"`
}

// GetRecentActivities 获取最近操作动态
func (h *DashboardHandler) GetRecentActivities(c *gin.Context) {
	var activities []RecentActivity

	// 从库存流水中获取最近的操作记录
	h.db.Table("biz_stock_log sl").
		Select("sl.id, sl.type, sl.related_no as order_no, u.real_name as operator, DATE_FORMAT(sl.created_at, '%Y-%m-%d %H:%i') as created_at").
		Joins("LEFT JOIN sys_user u ON sl.operator_id = u.id").
		Order("sl.created_at DESC").
		Limit(10).
		Scan(&activities)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": activities,
	})
}

