package model

import (
	"time"
)

// User 用户模型
type User struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	Username  string    `gorm:"type:varchar(64);uniqueIndex;not null" json:"username"`
	Password  string    `gorm:"type:varchar(128);not null" json:"-"`
	RealName  string    `gorm:"type:varchar(64);not null" json:"real_name"`
	DeptID    int64     `gorm:"not null;index" json:"dept_id"`
	RoleCode  string    `gorm:"type:varchar(20);not null;index" json:"role_code"`
	Status    int8      `gorm:"type:tinyint;not null;default:1" json:"status"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`

	// 关联
	Department *Department `gorm:"foreignKey:DeptID" json:"department,omitempty"`
}

// TableName 指定表名
func (User) TableName() string {
	return "sys_user"
}
