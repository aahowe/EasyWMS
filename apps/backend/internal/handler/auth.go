package handler

import (
	"net/http"

	"easywms/internal/config"
	"easywms/internal/model"
	"easywms/internal/utils"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// AuthHandler 认证处理器
type AuthHandler struct {
	db  *gorm.DB
	cfg *config.Config
}

// NewAuthHandler 创建认证处理器
func NewAuthHandler(db *gorm.DB, cfg *config.Config) *AuthHandler {
	return &AuthHandler{db: db, cfg: cfg}
}

// LoginRequest 登录请求
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse 登录响应
type LoginResponse struct {
	AccessToken string `json:"accessToken"`
}

// Login 用户登录
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "请求参数错误",
			"error":   err.Error(),
		})
		return
	}

	// 查询用户
	var user model.User
	if err := h.db.Where("username = ?", req.Username).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    401,
				"message": "用户名或密码错误",
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "服务器内部错误",
		})
		return
	}

	// 检查用户状态
	if user.Status != 1 {
		c.JSON(http.StatusForbidden, gin.H{
			"code":    403,
			"message": "账号已被禁用",
		})
		return
	}

	// 验证密码
	if !utils.CheckPassword(req.Password, user.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    401,
			"message": "用户名或密码错误",
		})
		return
	}

	// 生成JWT
	token, err := utils.GenerateToken(user.ID, user.Username, user.RoleCode, h.cfg.JWT.Secret, h.cfg.JWT.ExpireHours)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "生成令牌失败",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": LoginResponse{
			AccessToken: token,
		},
	})
}

// Logout 用户登出
func (h *AuthHandler) Logout(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "登出成功",
	})
}

// GetUserInfo 获取用户信息
func (h *AuthHandler) GetUserInfo(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    401,
			"message": "未授权",
		})
		return
	}

	var user model.User
	if err := h.db.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    404,
			"message": "用户不存在",
		})
		return
	}

	// 获取角色列表
	roles := []string{user.RoleCode}

	// 根据角色设置不同的首页
	homePath := "/analytics"
	switch user.RoleCode {
	case "ADMIN":
		homePath = "/analytics"
	case "BUYER":
		homePath = "/wms/procurement/list"
	case "W_MGR":
		homePath = "/wms/inbound/list"
	case "STAFF":
		homePath = "/wms/outbound/list"
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"userId":   user.ID,
			"username": user.Username,
			"realName": user.RealName,
			"roles":    roles,
			"homePath": homePath,
		},
	})
}

// GetAccessCodes 获取用户权限码
func (h *AuthHandler) GetAccessCodes(c *gin.Context) {
	roleCode, exists := c.Get("roleCode")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    401,
			"message": "未授权",
		})
		return
	}

	// 从数据库查询角色的权限码
	var permissions []string
	h.db.Table("sys_role_permission").
		Where("role_code = ?", roleCode).
		Pluck("permission_code", &permissions)

	// 如果数据库没有数据，使用默认权限
	if len(permissions) == 0 {
		permissions = h.getDefaultPermissions(roleCode.(string))
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": permissions,
	})
}

// getDefaultPermissions 获取默认权限（数据库未初始化时使用）
func (h *AuthHandler) getDefaultPermissions(roleCode string) []string {
	switch roleCode {
	case "ADMIN":
		return []string{
			"BASIC_VIEW", "BASIC_MANAGE",
			"PRODUCT_VIEW", "PRODUCT_CREATE", "PRODUCT_EDIT", "PRODUCT_DELETE",
			"SUPPLIER_MANAGE", "DEPARTMENT_MANAGE", "USER_MANAGE", "INIT_STOCK",
			"PROCUREMENT_VIEW", "PROCUREMENT_CREATE", "PROCUREMENT_APPROVE", "PROCUREMENT_ORDER",
			"INBOUND_VIEW", "INBOUND_CREATE", "INBOUND_APPROVE",
			"OUTBOUND_VIEW", "OUTBOUND_CREATE", "OUTBOUND_APPROVE", "OUTBOUND_EXECUTE",
			"INVENTORY_VIEW", "INVENTORY_CHECK", "INVENTORY_ADJUST",
			"REPORT_VIEW", "DASHBOARD_VIEW",
		}
	case "BUYER":
		return []string{
			"BASIC_VIEW", "PRODUCT_VIEW", "SUPPLIER_MANAGE",
			"PROCUREMENT_VIEW", "PROCUREMENT_CREATE", "PROCUREMENT_ORDER",
			"INVENTORY_VIEW", "DASHBOARD_VIEW",
		}
	case "W_MGR":
		return []string{
			"BASIC_VIEW", "PRODUCT_VIEW", "PRODUCT_CREATE", "PRODUCT_EDIT", "INIT_STOCK",
			"INBOUND_VIEW", "INBOUND_CREATE", "INBOUND_APPROVE",
			"OUTBOUND_VIEW", "OUTBOUND_APPROVE", "OUTBOUND_EXECUTE",
			"INVENTORY_VIEW", "INVENTORY_CHECK", "INVENTORY_ADJUST",
			"DASHBOARD_VIEW",
		}
	case "STAFF":
		return []string{
			"BASIC_VIEW", "PRODUCT_VIEW",
			"OUTBOUND_VIEW", "OUTBOUND_CREATE",
			"INVENTORY_VIEW", "DASHBOARD_VIEW",
		}
	default:
		return []string{}
	}
}

// MenuItem 菜单项
type MenuItem struct {
	Name      string     `json:"name"`
	Path      string     `json:"path"`
	Component string     `json:"component,omitempty"`
	Meta      MenuMeta   `json:"meta"`
	Children  []MenuItem `json:"children,omitempty"`
}

// MenuMeta 菜单元数据
type MenuMeta struct {
	Title     string   `json:"title"`
	Icon      string   `json:"icon,omitempty"`
	Order     int      `json:"order,omitempty"`
	Authority []string `json:"authority,omitempty"`
	AffixTab  bool     `json:"affixTab,omitempty"`
}

// GetMenus 获取用户菜单
func (h *AuthHandler) GetMenus(c *gin.Context) {
	roleCode, exists := c.Get("roleCode")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    401,
			"message": "未授权",
		})
		return
	}

	menus := h.buildMenus(roleCode.(string))

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": menus,
	})
}

// buildMenus 根据角色构建菜单
func (h *AuthHandler) buildMenus(roleCode string) []MenuItem {
	var menus []MenuItem

	// 概览菜单 - 所有角色都可见
	dashboardMenu := MenuItem{
		Name: "Dashboard",
		Path: "/dashboard",
		Meta: MenuMeta{
			Title: "概览",
			Icon:  "lucide:layout-dashboard",
			Order: -1,
		},
		Children: []MenuItem{
			{
				Name:      "Analytics",
				Path:      "/analytics",
				Component: "#/views/dashboard/analytics/index.vue",
				Meta: MenuMeta{
					Title:    "分析页",
					Icon:     "lucide:area-chart",
					AffixTab: true,
				},
			},
			{
				Name:      "Workspace",
				Path:      "/workspace",
				Component: "#/views/dashboard/workspace/index.vue",
				Meta: MenuMeta{
					Title: "工作台",
					Icon:  "carbon:workspace",
				},
			},
		},
	}
	menus = append(menus, dashboardMenu)

	// 根据角色添加不同的菜单
	switch roleCode {
	case "ADMIN":
		menus = append(menus, h.getAdminMenus()...)
	case "BUYER":
		menus = append(menus, h.getBuyerMenus()...)
	case "W_MGR":
		menus = append(menus, h.getWarehouseManagerMenus()...)
	case "STAFF":
		menus = append(menus, h.getStaffMenus()...)
	}

	return menus
}

// getAdminMenus 系统管理员菜单
func (h *AuthHandler) getAdminMenus() []MenuItem {
	return []MenuItem{
		// 基础数据管理
		{
			Name: "WmsBasicData",
			Path: "/wms/basic",
			Meta: MenuMeta{
				Title: "基础数据",
				Icon:  "mdi:package-variant-closed",
				Order: 10,
			},
			Children: []MenuItem{
				{
					Name:      "WmsProduct",
					Path:      "/wms/basic/product",
					Component: "#/views/wms/product/list.vue",
					Meta: MenuMeta{
						Title: "产品管理",
						Icon:  "mdi:package-variant",
					},
				},
			},
		},
		// 采购管理
		{
			Name: "WmsProcurement",
			Path: "/wms/procurement",
			Meta: MenuMeta{
				Title: "采购管理",
				Icon:  "mdi:cart-outline",
				Order: 20,
			},
			Children: []MenuItem{
				{
					Name:      "WmsProcurementList",
					Path:      "/wms/procurement/list",
					Component: "#/views/wms/procurement/list.vue",
					Meta: MenuMeta{
						Title: "采购单列表",
						Icon:  "mdi:clipboard-list-outline",
					},
				},
			},
		},
		// 入库管理
		{
			Name: "WmsInbound",
			Path: "/wms/inbound",
			Meta: MenuMeta{
				Title: "入库管理",
				Icon:  "mdi:package-down",
				Order: 30,
			},
			Children: []MenuItem{
				{
					Name:      "WmsInboundList",
					Path:      "/wms/inbound/list",
					Component: "#/views/wms/inbound/list.vue",
					Meta: MenuMeta{
						Title: "入库单列表",
						Icon:  "mdi:clipboard-arrow-down-outline",
					},
				},
			},
		},
		// 出库管理
		{
			Name: "WmsOutbound",
			Path: "/wms/outbound",
			Meta: MenuMeta{
				Title: "出库管理",
				Icon:  "mdi:package-up",
				Order: 40,
			},
			Children: []MenuItem{
				{
					Name:      "WmsOutboundList",
					Path:      "/wms/outbound/list",
					Component: "#/views/wms/outbound/list.vue",
					Meta: MenuMeta{
						Title: "出库单列表",
						Icon:  "mdi:clipboard-arrow-up-outline",
					},
				},
			},
		},
		// 库存管理
		{
			Name: "WmsInventory",
			Path: "/wms/inventory",
			Meta: MenuMeta{
				Title: "库存管理",
				Icon:  "mdi:warehouse",
				Order: 50,
			},
			Children: []MenuItem{
				{
					Name:      "WmsInventoryStock",
					Path:      "/wms/inventory/stock",
					Component: "#/views/wms/inventory/stock/list.vue",
					Meta: MenuMeta{
						Title: "库存查询",
						Icon:  "mdi:cube-outline",
					},
				},
				{
					Name:      "WmsInventoryCheck",
					Path:      "/wms/inventory/check",
					Component: "#/views/wms/inventory/check/list.vue",
					Meta: MenuMeta{
						Title: "库存盘点",
						Icon:  "mdi:clipboard-check-outline",
					},
				},
			},
		},
	}
}

// getBuyerMenus 采购专员菜单
func (h *AuthHandler) getBuyerMenus() []MenuItem {
	return []MenuItem{
		// 基础数据（只读）
		{
			Name: "WmsBasicData",
			Path: "/wms/basic",
			Meta: MenuMeta{
				Title: "基础数据",
				Icon:  "mdi:package-variant-closed",
				Order: 10,
			},
			Children: []MenuItem{
				{
					Name:      "WmsProduct",
					Path:      "/wms/basic/product",
					Component: "#/views/wms/product/list.vue",
					Meta: MenuMeta{
						Title: "产品查看",
						Icon:  "mdi:package-variant",
					},
				},
			},
		},
		// 采购管理
		{
			Name: "WmsProcurement",
			Path: "/wms/procurement",
			Meta: MenuMeta{
				Title: "采购管理",
				Icon:  "mdi:cart-outline",
				Order: 20,
			},
			Children: []MenuItem{
				{
					Name:      "WmsProcurementList",
					Path:      "/wms/procurement/list",
					Component: "#/views/wms/procurement/list.vue",
					Meta: MenuMeta{
						Title: "采购单列表",
						Icon:  "mdi:clipboard-list-outline",
					},
				},
			},
		},
		// 库存查询
		{
			Name: "WmsInventory",
			Path: "/wms/inventory",
			Meta: MenuMeta{
				Title: "库存管理",
				Icon:  "mdi:warehouse",
				Order: 50,
			},
			Children: []MenuItem{
				{
					Name:      "WmsInventoryStock",
					Path:      "/wms/inventory/stock",
					Component: "#/views/wms/inventory/stock/list.vue",
					Meta: MenuMeta{
						Title: "库存查询",
						Icon:  "mdi:cube-outline",
					},
				},
			},
		},
	}
}

// getWarehouseManagerMenus 仓库管理员菜单
func (h *AuthHandler) getWarehouseManagerMenus() []MenuItem {
	return []MenuItem{
		// 基础数据管理
		{
			Name: "WmsBasicData",
			Path: "/wms/basic",
			Meta: MenuMeta{
				Title: "基础数据",
				Icon:  "mdi:package-variant-closed",
				Order: 10,
			},
			Children: []MenuItem{
				{
					Name:      "WmsProduct",
					Path:      "/wms/basic/product",
					Component: "#/views/wms/product/list.vue",
					Meta: MenuMeta{
						Title: "产品管理",
						Icon:  "mdi:package-variant",
					},
				},
			},
		},
		// 入库管理
		{
			Name: "WmsInbound",
			Path: "/wms/inbound",
			Meta: MenuMeta{
				Title: "入库管理",
				Icon:  "mdi:package-down",
				Order: 30,
			},
			Children: []MenuItem{
				{
					Name:      "WmsInboundList",
					Path:      "/wms/inbound/list",
					Component: "#/views/wms/inbound/list.vue",
					Meta: MenuMeta{
						Title: "入库单列表",
						Icon:  "mdi:clipboard-arrow-down-outline",
					},
				},
			},
		},
		// 出库管理
		{
			Name: "WmsOutbound",
			Path: "/wms/outbound",
			Meta: MenuMeta{
				Title: "出库管理",
				Icon:  "mdi:package-up",
				Order: 40,
			},
			Children: []MenuItem{
				{
					Name:      "WmsOutboundList",
					Path:      "/wms/outbound/list",
					Component: "#/views/wms/outbound/list.vue",
					Meta: MenuMeta{
						Title: "出库单列表",
						Icon:  "mdi:clipboard-arrow-up-outline",
					},
				},
			},
		},
		// 库存管理
		{
			Name: "WmsInventory",
			Path: "/wms/inventory",
			Meta: MenuMeta{
				Title: "库存管理",
				Icon:  "mdi:warehouse",
				Order: 50,
			},
			Children: []MenuItem{
				{
					Name:      "WmsInventoryStock",
					Path:      "/wms/inventory/stock",
					Component: "#/views/wms/inventory/stock/list.vue",
					Meta: MenuMeta{
						Title: "库存查询",
						Icon:  "mdi:cube-outline",
					},
				},
				{
					Name:      "WmsInventoryCheck",
					Path:      "/wms/inventory/check",
					Component: "#/views/wms/inventory/check/list.vue",
					Meta: MenuMeta{
						Title: "库存盘点",
						Icon:  "mdi:clipboard-check-outline",
					},
				},
			},
		},
	}
}

// getStaffMenus 部门员工菜单
func (h *AuthHandler) getStaffMenus() []MenuItem {
	return []MenuItem{
		// 产品查看
		{
			Name: "WmsBasicData",
			Path: "/wms/basic",
			Meta: MenuMeta{
				Title: "基础数据",
				Icon:  "mdi:package-variant-closed",
				Order: 10,
			},
			Children: []MenuItem{
				{
					Name:      "WmsProduct",
					Path:      "/wms/basic/product",
					Component: "#/views/wms/product/list.vue",
					Meta: MenuMeta{
						Title: "产品查看",
						Icon:  "mdi:package-variant",
					},
				},
			},
		},
		// 出库管理（领用申请）
		{
			Name: "WmsOutbound",
			Path: "/wms/outbound",
			Meta: MenuMeta{
				Title: "物资领用",
				Icon:  "mdi:package-up",
				Order: 40,
			},
			Children: []MenuItem{
				{
					Name:      "WmsOutboundList",
					Path:      "/wms/outbound/list",
					Component: "#/views/wms/outbound/list.vue",
					Meta: MenuMeta{
						Title: "领用申请",
						Icon:  "mdi:clipboard-arrow-up-outline",
					},
				},
			},
		},
		// 库存查询
		{
			Name: "WmsInventory",
			Path: "/wms/inventory",
			Meta: MenuMeta{
				Title: "库存查询",
				Icon:  "mdi:warehouse",
				Order: 50,
			},
			Children: []MenuItem{
				{
					Name:      "WmsInventoryStock",
					Path:      "/wms/inventory/stock",
					Component: "#/views/wms/inventory/stock/list.vue",
					Meta: MenuMeta{
						Title: "库存查询",
						Icon:  "mdi:cube-outline",
					},
				},
			},
		},
	}
}
