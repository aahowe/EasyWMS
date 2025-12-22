package model

import (
	"time"
)

// Product 物资档案模型
type Product struct {
	ID             int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	CategoryID     int64     `gorm:"not null;index" json:"category_id"`
	SKUCode        string    `gorm:"type:varchar(64);uniqueIndex;not null" json:"sku_code"`
	Name           string    `gorm:"type:varchar(128);not null;index" json:"name"`
	Specification  string    `gorm:"type:varchar(128)" json:"specification"`
	Unit           string    `gorm:"type:varchar(20);not null" json:"unit"`
	StockQty       float64   `gorm:"type:decimal(14,4);not null;default:0" json:"stock_qty"`
	AlertThreshold float64   `gorm:"type:decimal(14,4);not null;default:0" json:"alert_threshold"`
	Status         int8      `gorm:"type:tinyint;not null;default:1" json:"status"`
	CreatedAt      time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt      time.Time `gorm:"autoUpdateTime" json:"updated_at"`

	// 关联
	Category *Category `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
}

// TableName 指定表名
func (Product) TableName() string {
	return "base_product"
}

// Category 物资分类模型
type Category struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	Name      string    `gorm:"type:varchar(64);not null" json:"name"`
	ParentID  int64     `gorm:"not null;default:0;index" json:"parent_id"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

// TableName 指定表名
func (Category) TableName() string {
	return "base_category"
}
