-- =============================================
-- EasyWMS 权限管理表结构
-- 版本: V1.0
-- 说明: 定义角色和权限码的关联关系
-- =============================================

USE easywms;

-- =============================================
-- 1. 权限码表
-- =============================================
CREATE TABLE IF NOT EXISTS `sys_permission` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) NOT NULL COMMENT '权限码',
  `name` varchar(100) NOT NULL COMMENT '权限名称',
  `description` varchar(255) DEFAULT NULL COMMENT '权限描述',
  `module` varchar(50) DEFAULT NULL COMMENT '所属模块',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='权限码表';

-- =============================================
-- 2. 角色权限关联表
-- =============================================
CREATE TABLE IF NOT EXISTS `sys_role_permission` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `role_code` varchar(20) NOT NULL COMMENT '角色代码',
  `permission_code` varchar(50) NOT NULL COMMENT '权限码',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_perm` (`role_code`, `permission_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色权限关联表';

-- =============================================
-- 3. 初始化权限码数据
-- =============================================

-- 基础数据管理模块权限
INSERT INTO `sys_permission` (`code`, `name`, `description`, `module`) VALUES
('BASIC_VIEW', '基础数据查看', '查看物资档案、供应商、部门等基础数据', 'basic'),
('BASIC_MANAGE', '基础数据管理', '新增、修改、删除基础数据', 'basic'),
('PRODUCT_VIEW', '产品查看', '查看产品列表', 'product'),
('PRODUCT_CREATE', '产品新增', '新增产品', 'product'),
('PRODUCT_EDIT', '产品编辑', '编辑产品信息', 'product'),
('PRODUCT_DELETE', '产品删除', '删除产品', 'product'),
('SUPPLIER_MANAGE', '供应商管理', '管理供应商档案', 'supplier'),
('DEPARTMENT_MANAGE', '部门管理', '管理部门架构', 'department'),
('USER_MANAGE', '用户管理', '管理系统用户', 'user'),
('INIT_STOCK', '期初库存录入', '录入期初库存数据', 'stock');

-- 采购管理模块权限
INSERT INTO `sys_permission` (`code`, `name`, `description`, `module`) VALUES
('PROCUREMENT_VIEW', '采购单查看', '查看采购申请列表', 'procurement'),
('PROCUREMENT_CREATE', '采购申请', '发起采购申请', 'procurement'),
('PROCUREMENT_APPROVE', '采购审批', '审批采购申请', 'procurement'),
('PROCUREMENT_ORDER', '生成订单', '将批准的申请转为订单', 'procurement');

-- 入库管理模块权限
INSERT INTO `sys_permission` (`code`, `name`, `description`, `module`) VALUES
('INBOUND_VIEW', '入库单查看', '查看入库单列表', 'inbound'),
('INBOUND_CREATE', '入库操作', '执行入库操作', 'inbound'),
('INBOUND_APPROVE', '入库审核', '审核入库单', 'inbound');

-- 出库管理模块权限
INSERT INTO `sys_permission` (`code`, `name`, `description`, `module`) VALUES
('OUTBOUND_VIEW', '出库单查看', '查看出库单列表', 'outbound'),
('OUTBOUND_CREATE', '领用申请', '发起物资领用申请', 'outbound'),
('OUTBOUND_APPROVE', '出库审核', '审核出库申请', 'outbound'),
('OUTBOUND_EXECUTE', '出库执行', '执行出库操作', 'outbound');

-- 库存管理模块权限
INSERT INTO `sys_permission` (`code`, `name`, `description`, `module`) VALUES
('INVENTORY_VIEW', '库存查看', '查看库存信息', 'inventory'),
('INVENTORY_CHECK', '库存盘点', '执行库存盘点', 'inventory'),
('INVENTORY_ADJUST', '库存调整', '调整库存数量', 'inventory');

-- 统计报表权限
INSERT INTO `sys_permission` (`code`, `name`, `description`, `module`) VALUES
('REPORT_VIEW', '报表查看', '查看统计报表', 'report'),
('DASHBOARD_VIEW', '仪表盘查看', '查看仪表盘数据', 'dashboard');

-- =============================================
-- 4. 初始化角色权限关联
-- =============================================

-- ADMIN (系统管理员) - 拥有所有权限
INSERT INTO `sys_role_permission` (`role_code`, `permission_code`) VALUES
('ADMIN', 'BASIC_VIEW'),
('ADMIN', 'BASIC_MANAGE'),
('ADMIN', 'PRODUCT_VIEW'),
('ADMIN', 'PRODUCT_CREATE'),
('ADMIN', 'PRODUCT_EDIT'),
('ADMIN', 'PRODUCT_DELETE'),
('ADMIN', 'SUPPLIER_MANAGE'),
('ADMIN', 'DEPARTMENT_MANAGE'),
('ADMIN', 'USER_MANAGE'),
('ADMIN', 'INIT_STOCK'),
('ADMIN', 'PROCUREMENT_VIEW'),
('ADMIN', 'PROCUREMENT_CREATE'),
('ADMIN', 'PROCUREMENT_APPROVE'),
('ADMIN', 'PROCUREMENT_ORDER'),
('ADMIN', 'INBOUND_VIEW'),
('ADMIN', 'INBOUND_CREATE'),
('ADMIN', 'INBOUND_APPROVE'),
('ADMIN', 'OUTBOUND_VIEW'),
('ADMIN', 'OUTBOUND_CREATE'),
('ADMIN', 'OUTBOUND_APPROVE'),
('ADMIN', 'OUTBOUND_EXECUTE'),
('ADMIN', 'INVENTORY_VIEW'),
('ADMIN', 'INVENTORY_CHECK'),
('ADMIN', 'INVENTORY_ADJUST'),
('ADMIN', 'REPORT_VIEW'),
('ADMIN', 'DASHBOARD_VIEW');

-- BUYER (采购专员) - 采购相关权限
INSERT INTO `sys_role_permission` (`role_code`, `permission_code`) VALUES
('BUYER', 'BASIC_VIEW'),
('BUYER', 'PRODUCT_VIEW'),
('BUYER', 'SUPPLIER_MANAGE'),
('BUYER', 'PROCUREMENT_VIEW'),
('BUYER', 'PROCUREMENT_CREATE'),
('BUYER', 'PROCUREMENT_ORDER'),
('BUYER', 'INVENTORY_VIEW'),
('BUYER', 'DASHBOARD_VIEW');

-- W_MGR (仓库管理员) - 仓储作业权限
INSERT INTO `sys_role_permission` (`role_code`, `permission_code`) VALUES
('W_MGR', 'BASIC_VIEW'),
('W_MGR', 'PRODUCT_VIEW'),
('W_MGR', 'PRODUCT_CREATE'),
('W_MGR', 'PRODUCT_EDIT'),
('W_MGR', 'INIT_STOCK'),
('W_MGR', 'INBOUND_VIEW'),
('W_MGR', 'INBOUND_CREATE'),
('W_MGR', 'INBOUND_APPROVE'),
('W_MGR', 'OUTBOUND_VIEW'),
('W_MGR', 'OUTBOUND_APPROVE'),
('W_MGR', 'OUTBOUND_EXECUTE'),
('W_MGR', 'INVENTORY_VIEW'),
('W_MGR', 'INVENTORY_CHECK'),
('W_MGR', 'INVENTORY_ADJUST'),
('W_MGR', 'DASHBOARD_VIEW');

-- STAFF (部门员工) - 基本权限
INSERT INTO `sys_role_permission` (`role_code`, `permission_code`) VALUES
('STAFF', 'BASIC_VIEW'),
('STAFF', 'PRODUCT_VIEW'),
('STAFF', 'OUTBOUND_VIEW'),
('STAFF', 'OUTBOUND_CREATE'),
('STAFF', 'INVENTORY_VIEW'),
('STAFF', 'DASHBOARD_VIEW');

-- =============================================
-- 权限管理表创建完成
-- =============================================

