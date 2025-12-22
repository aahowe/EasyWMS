package model

import (
	"time"
)

// Department 部门模型
type Department struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	Name      string    `gorm:"type:varchar(64);not null" json:"name"`
	ParentID  int64     `gorm:"not null;default:0;index" json:"parent_id"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

// TableName 指定表名
func (Department) TableName() string {
	return "base_department"
}
