package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// CategoryHandler 分类处理器
type CategoryHandler struct {
	db *gorm.DB
}

// NewCategoryHandler 创建分类处理器
func NewCategoryHandler(db *gorm.DB) *CategoryHandler {
	return &CategoryHandler{db: db}
}

// GetCategoryList 获取分类列表
func (h *CategoryHandler) GetCategoryList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "100"))
	keyword := c.Query("keyword")

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 200 {
		pageSize = 100
	}

	offset := (page - 1) * pageSize
	query := h.db.Model(&Category{})

	if keyword != "" {
		query = query.Where("name LIKE ?", "%"+keyword+"%")
	}

	var total int64
	query.Count(&total)

	var categories []Category
	query.Order("parent_id ASC, id ASC").Offset(offset).Limit(pageSize).Find(&categories)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"items": categories,
			"total": total,
		},
	})
}

// GetCategoryTree 获取分类树
func (h *CategoryHandler) GetCategoryTree(c *gin.Context) {
	var categories []Category
	h.db.Order("parent_id ASC, id ASC").Find(&categories)

	// 构建树形结构
	type TreeNode struct {
		ID       int64       `json:"id"`
		Name     string      `json:"name"`
		ParentID int64       `json:"parentId"`
		Children []*TreeNode `json:"children,omitempty"`
	}

	nodeMap := make(map[int64]*TreeNode)
	var roots []*TreeNode

	for _, cat := range categories {
		node := &TreeNode{
			ID:       cat.ID,
			Name:     cat.Name,
			ParentID: cat.ParentID,
			Children: []*TreeNode{},
		}
		nodeMap[cat.ID] = node
	}

	for _, cat := range categories {
		node := nodeMap[cat.ID]
		if cat.ParentID == 0 {
			roots = append(roots, node)
		} else if parent, ok := nodeMap[cat.ParentID]; ok {
			parent.Children = append(parent.Children, node)
		}
	}

	c.JSON(http.StatusOK, gin.H{"code": 0, "data": roots})
}

// GetCategory 获取分类详情
func (h *CategoryHandler) GetCategory(c *gin.Context) {
	id := c.Param("id")
	var category Category
	if err := h.db.First(&category, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "分类不存在"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"code": 0, "data": category})
}

// CreateCategory 创建分类
func (h *CategoryHandler) CreateCategory(c *gin.Context) {
	var req struct {
		Name     string `json:"name"`
		ParentID int64  `json:"parentId"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	category := Category{
		Name:     req.Name,
		ParentID: req.ParentID,
	}

	if err := h.db.Create(&category).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "创建成功", "data": category})
}

// UpdateCategory 更新分类
func (h *CategoryHandler) UpdateCategory(c *gin.Context) {
	id := c.Param("id")
	var category Category
	if err := h.db.First(&category, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "分类不存在"})
		return
	}

	var req struct {
		Name     string `json:"name"`
		ParentID int64  `json:"parentId"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	h.db.Model(&category).Updates(map[string]interface{}{
		"name":      req.Name,
		"parent_id": req.ParentID,
	})

	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "更新成功"})
}

// DeleteCategory 删除分类
func (h *CategoryHandler) DeleteCategory(c *gin.Context) {
	id := c.Param("id")

	// 检查是否有子分类
	var count int64
	h.db.Model(&Category{}).Where("parent_id = ?", id).Count(&count)
	if count > 0 {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "存在子分类，无法删除"})
		return
	}

	// 检查是否有关联产品
	h.db.Model(&Product{}).Where("category_id = ?", id).Count(&count)
	if count > 0 {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "存在关联产品，无法删除"})
		return
	}

	if err := h.db.Delete(&Category{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "删除失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "删除成功"})
}
