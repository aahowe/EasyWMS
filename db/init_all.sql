-- =============================================
-- EasyWMS 数据库完整初始化脚本 (整合版)
-- 版本: V2.0
-- 说明: 包含清理、建表、权限、大量测试数据
-- 执行: mysql -u root -p < init_all.sql
-- =============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS easywms DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE easywms;

-- =============================================
-- 第一部分: 清理旧数据 (按外键依赖顺序)
-- =============================================
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `biz_inventory_check_item`;
DROP TABLE IF EXISTS `biz_inventory_check`;
DROP TABLE IF EXISTS `biz_stock_log`;
DROP TABLE IF EXISTS `biz_outbound_item`;
DROP TABLE IF EXISTS `biz_outbound`;
DROP TABLE IF EXISTS `biz_inbound_item`;
DROP TABLE IF EXISTS `biz_inbound`;
DROP TABLE IF EXISTS `biz_procurement_item`;
DROP TABLE IF EXISTS `biz_procurement`;
DROP TABLE IF EXISTS `base_product`;
DROP TABLE IF EXISTS `base_category`;
DROP TABLE IF EXISTS `base_supplier`;
DROP TABLE IF EXISTS `sys_role_permission`;
DROP TABLE IF EXISTS `sys_permission`;
DROP TABLE IF EXISTS `sys_user`;
DROP TABLE IF EXISTS `base_department`;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================
-- 第二部分: 创建表结构
-- =============================================

-- 1. 部门表
CREATE TABLE `base_department` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '部门ID',
  `name` VARCHAR(64) NOT NULL COMMENT '部门名称',
  `parent_id` BIGINT NOT NULL DEFAULT 0 COMMENT '父部门ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门表';

-- 2. 系统用户表
CREATE TABLE `sys_user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` VARCHAR(64) NOT NULL COMMENT '登录账号',
  `password` VARCHAR(128) NOT NULL COMMENT '登录密码(BCrypt)',
  `real_name` VARCHAR(64) NOT NULL COMMENT '真实姓名',
  `dept_id` BIGINT NOT NULL COMMENT '部门ID',
  `role_code` VARCHAR(20) NOT NULL COMMENT '角色: ADMIN/W_MGR/BUYER/STAFF',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1-启用 0-禁用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_dept_id` (`dept_id`),
  KEY `idx_role_code` (`role_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统用户表';

-- 3. 权限码表
CREATE TABLE `sys_permission` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL COMMENT '权限码',
  `name` VARCHAR(100) NOT NULL COMMENT '权限名称',
  `description` VARCHAR(255) DEFAULT NULL COMMENT '描述',
  `module` VARCHAR(50) DEFAULT NULL COMMENT '所属模块',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='权限码表';

-- 4. 角色权限关联表
CREATE TABLE `sys_role_permission` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_code` VARCHAR(20) NOT NULL COMMENT '角色代码',
  `permission_code` VARCHAR(50) NOT NULL COMMENT '权限码',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_perm` (`role_code`, `permission_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色权限关联表';

-- 5. 供应商表
CREATE TABLE `base_supplier` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '供应商ID',
  `name` VARCHAR(128) NOT NULL COMMENT '供应商名称',
  `contact` VARCHAR(32) DEFAULT NULL COMMENT '联系人',
  `phone` VARCHAR(20) DEFAULT NULL COMMENT '联系电话',
  `address` VARCHAR(255) DEFAULT NULL COMMENT '地址',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1-启用 0-停用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='供应商表';

-- 6. 物资分类表
CREATE TABLE `base_category` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '分类ID',
  `name` VARCHAR(64) NOT NULL COMMENT '分类名称',
  `parent_id` BIGINT NOT NULL DEFAULT 0 COMMENT '父分类ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物资分类表';

-- 7. 物资档案表
CREATE TABLE `base_product` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '物资ID',
  `category_id` BIGINT NOT NULL COMMENT '所属分类ID',
  `sku_code` VARCHAR(64) NOT NULL COMMENT 'SKU编码',
  `name` VARCHAR(128) NOT NULL COMMENT '物资名称',
  `specification` VARCHAR(128) DEFAULT NULL COMMENT '规格型号',
  `unit` VARCHAR(20) NOT NULL COMMENT '计量单位',
  `stock_qty` DECIMAL(14,4) NOT NULL DEFAULT 0.0000 COMMENT '实时库存',
  `alert_threshold` DECIMAL(14,4) NOT NULL DEFAULT 0.0000 COMMENT '预警阈值',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1-启用 0-停用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sku_code` (`sku_code`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物资档案表';

-- 8. 采购订单主表
CREATE TABLE `biz_procurement` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `order_no` VARCHAR(32) NOT NULL COMMENT '采购单号',
  `applicant_id` BIGINT NOT NULL COMMENT '申请人ID',
  `supplier_id` BIGINT DEFAULT NULL COMMENT '供应商ID',
  `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/APPROVED/ORDERED/DONE',
  `reason` TEXT COMMENT '申请原因',
  `expected_date` DATE DEFAULT NULL COMMENT '预计到货日期',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_applicant_id` (`applicant_id`),
  KEY `idx_supplier_id` (`supplier_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='采购订单主表';

-- 9. 采购明细表
CREATE TABLE `biz_procurement_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
  `procurement_id` BIGINT NOT NULL COMMENT '采购单ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `plan_qty` DECIMAL(14,4) NOT NULL COMMENT '计划数量',
  `unit_price` DECIMAL(14,2) DEFAULT NULL COMMENT '单价',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_procurement_id` (`procurement_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='采购明细表';

-- 10. 入库单主表
CREATE TABLE `biz_inbound` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '入库ID',
  `inbound_no` VARCHAR(32) NOT NULL COMMENT '入库单号',
  `source_id` BIGINT DEFAULT NULL COMMENT '来源采购单ID',
  `is_temporary` TINYINT NOT NULL DEFAULT 0 COMMENT '1-暂估 0-正常',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '1-已完成 0-草稿',
  `inbound_date` DATETIME DEFAULT NULL COMMENT '入库时间',
  `warehouse_user_id` BIGINT DEFAULT NULL COMMENT '仓管员ID',
  `remark` TEXT COMMENT '备注',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_inbound_no` (`inbound_no`),
  KEY `idx_source_id` (`source_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='入库单主表';

-- 11. 入库明细表
CREATE TABLE `biz_inbound_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
  `inbound_id` BIGINT NOT NULL COMMENT '入库单ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `actual_qty` DECIMAL(14,4) NOT NULL COMMENT '实收数量',
  `location` VARCHAR(64) DEFAULT NULL COMMENT '库位',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_inbound_id` (`inbound_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='入库明细表';

-- 12. 出库主表
CREATE TABLE `biz_outbound` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '出库ID',
  `outbound_no` VARCHAR(32) NOT NULL COMMENT '出库单号',
  `applicant_id` BIGINT NOT NULL COMMENT '申请人ID',
  `dept_id` BIGINT NOT NULL COMMENT '领用部门ID',
  `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/APPROVED/DONE/REJECT',
  `purpose` TEXT COMMENT '用途',
  `reviewer_id` BIGINT DEFAULT NULL COMMENT '审核人ID',
  `review_time` DATETIME DEFAULT NULL COMMENT '审核时间',
  `outbound_date` DATETIME DEFAULT NULL COMMENT '出库时间',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_outbound_no` (`outbound_no`),
  KEY `idx_applicant_id` (`applicant_id`),
  KEY `idx_dept_id` (`dept_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='出库主表';

-- 13. 领用明细表
CREATE TABLE `biz_outbound_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
  `outbound_id` BIGINT NOT NULL COMMENT '出库单ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `apply_qty` DECIMAL(14,4) NOT NULL COMMENT '申请数量',
  `actual_qty` DECIMAL(14,4) DEFAULT NULL COMMENT '实发数量',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_outbound_id` (`outbound_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='领用明细表';

-- 14. 库存流水表
CREATE TABLE `biz_stock_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `type` VARCHAR(10) NOT NULL COMMENT 'IN/OUT/ADJUST',
  `change_qty` DECIMAL(14,4) NOT NULL COMMENT '变动数量',
  `snapshot_qty` DECIMAL(14,4) NOT NULL COMMENT '变动后库存',
  `related_no` VARCHAR(32) DEFAULT NULL COMMENT '关联单号',
  `operator_id` BIGINT DEFAULT NULL COMMENT '操作人ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_type` (`type`),
  KEY `idx_related_no` (`related_no`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='库存流水表';

-- 15. 盘点主表
CREATE TABLE `biz_inventory_check` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '盘点ID',
  `check_no` VARCHAR(32) NOT NULL COMMENT '盘点单号',
  `status` VARCHAR(20) NOT NULL DEFAULT 'CHECKING' COMMENT 'CHECKING/FINISHED',
  `check_date` DATE NOT NULL COMMENT '盘点日期',
  `checker_id` BIGINT DEFAULT NULL COMMENT '盘点人ID',
  `remark` TEXT COMMENT '备注',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_check_no` (`check_no`),
  KEY `idx_status` (`status`),
  KEY `idx_check_date` (`check_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='盘点主表';

-- 16. 盘点差异表
CREATE TABLE `biz_inventory_check_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
  `check_id` BIGINT NOT NULL COMMENT '盘点单ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `book_qty` DECIMAL(14,4) NOT NULL COMMENT '账面数量',
  `actual_qty` DECIMAL(14,4) NOT NULL COMMENT '实盘数量',
  `diff_qty` DECIMAL(14,4) NOT NULL COMMENT '盈亏数量',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_check_id` (`check_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='盘点差异表';

-- =============================================
-- 第三部分: 插入权限数据
-- =============================================
INSERT INTO `sys_permission` (`code`, `name`, `description`, `module`) VALUES
('BASIC_VIEW', '基础数据查看', '查看物资档案、供应商等', 'basic'),
('BASIC_MANAGE', '基础数据管理', '新增、修改、删除基础数据', 'basic'),
('PRODUCT_VIEW', '产品查看', '查看产品列表', 'product'),
('PRODUCT_CREATE', '产品新增', '新增产品', 'product'),
('PRODUCT_EDIT', '产品编辑', '编辑产品信息', 'product'),
('PRODUCT_DELETE', '产品删除', '删除产品', 'product'),
('SUPPLIER_MANAGE', '供应商管理', '管理供应商档案', 'supplier'),
('DEPARTMENT_MANAGE', '部门管理', '管理部门架构', 'department'),
('USER_MANAGE', '用户管理', '管理系统用户', 'user'),
('INIT_STOCK', '期初库存录入', '录入期初库存', 'stock'),
('PROCUREMENT_VIEW', '采购单查看', '查看采购申请列表', 'procurement'),
('PROCUREMENT_CREATE', '采购申请', '发起采购申请', 'procurement'),
('PROCUREMENT_APPROVE', '采购审批', '审批采购申请', 'procurement'),
('PROCUREMENT_ORDER', '生成订单', '将批准的申请转为订单', 'procurement'),
('INBOUND_VIEW', '入库单查看', '查看入库单列表', 'inbound'),
('INBOUND_CREATE', '入库操作', '执行入库操作', 'inbound'),
('INBOUND_APPROVE', '入库审核', '审核入库单', 'inbound'),
('OUTBOUND_VIEW', '出库单查看', '查看出库单列表', 'outbound'),
('OUTBOUND_CREATE', '领用申请', '发起物资领用申请', 'outbound'),
('OUTBOUND_APPROVE', '出库审核', '审核出库申请', 'outbound'),
('OUTBOUND_EXECUTE', '出库执行', '执行出库操作', 'outbound'),
('INVENTORY_VIEW', '库存查看', '查看库存信息', 'inventory'),
('INVENTORY_CHECK', '库存盘点', '执行库存盘点', 'inventory'),
('INVENTORY_ADJUST', '库存调整', '调整库存数量', 'inventory'),
('REPORT_VIEW', '报表查看', '查看统计报表', 'report'),
('DASHBOARD_VIEW', '仪表盘查看', '查看仪表盘数据', 'dashboard');

-- ADMIN (系统管理员) - 全部权限
INSERT INTO `sys_role_permission` (`role_code`, `permission_code`) VALUES
('ADMIN', 'BASIC_VIEW'), ('ADMIN', 'BASIC_MANAGE'), ('ADMIN', 'PRODUCT_VIEW'), ('ADMIN', 'PRODUCT_CREATE'),
('ADMIN', 'PRODUCT_EDIT'), ('ADMIN', 'PRODUCT_DELETE'), ('ADMIN', 'SUPPLIER_MANAGE'), ('ADMIN', 'DEPARTMENT_MANAGE'),
('ADMIN', 'USER_MANAGE'), ('ADMIN', 'INIT_STOCK'), ('ADMIN', 'PROCUREMENT_VIEW'), ('ADMIN', 'PROCUREMENT_CREATE'),
('ADMIN', 'PROCUREMENT_APPROVE'), ('ADMIN', 'PROCUREMENT_ORDER'), ('ADMIN', 'INBOUND_VIEW'), ('ADMIN', 'INBOUND_CREATE'),
('ADMIN', 'INBOUND_APPROVE'), ('ADMIN', 'OUTBOUND_VIEW'), ('ADMIN', 'OUTBOUND_CREATE'), ('ADMIN', 'OUTBOUND_APPROVE'),
('ADMIN', 'OUTBOUND_EXECUTE'), ('ADMIN', 'INVENTORY_VIEW'), ('ADMIN', 'INVENTORY_CHECK'), ('ADMIN', 'INVENTORY_ADJUST'),
('ADMIN', 'REPORT_VIEW'), ('ADMIN', 'DASHBOARD_VIEW');

-- BUYER (采购专员)
INSERT INTO `sys_role_permission` (`role_code`, `permission_code`) VALUES
('BUYER', 'BASIC_VIEW'), ('BUYER', 'PRODUCT_VIEW'), ('BUYER', 'SUPPLIER_MANAGE'),
('BUYER', 'PROCUREMENT_VIEW'), ('BUYER', 'PROCUREMENT_CREATE'), ('BUYER', 'PROCUREMENT_ORDER'),
('BUYER', 'INVENTORY_VIEW'), ('BUYER', 'DASHBOARD_VIEW');

-- W_MGR (仓库管理员)
INSERT INTO `sys_role_permission` (`role_code`, `permission_code`) VALUES
('W_MGR', 'BASIC_VIEW'), ('W_MGR', 'PRODUCT_VIEW'), ('W_MGR', 'PRODUCT_CREATE'), ('W_MGR', 'PRODUCT_EDIT'),
('W_MGR', 'INIT_STOCK'), ('W_MGR', 'INBOUND_VIEW'), ('W_MGR', 'INBOUND_CREATE'), ('W_MGR', 'INBOUND_APPROVE'),
('W_MGR', 'OUTBOUND_VIEW'), ('W_MGR', 'OUTBOUND_APPROVE'), ('W_MGR', 'OUTBOUND_EXECUTE'),
('W_MGR', 'INVENTORY_VIEW'), ('W_MGR', 'INVENTORY_CHECK'), ('W_MGR', 'INVENTORY_ADJUST'), ('W_MGR', 'DASHBOARD_VIEW');

-- STAFF (部门员工)
INSERT INTO `sys_role_permission` (`role_code`, `permission_code`) VALUES
('STAFF', 'BASIC_VIEW'), ('STAFF', 'PRODUCT_VIEW'), ('STAFF', 'OUTBOUND_VIEW'),
('STAFF', 'OUTBOUND_CREATE'), ('STAFF', 'INVENTORY_VIEW'), ('STAFF', 'DASHBOARD_VIEW');

-- =============================================
-- 第四部分: 插入基础数据
-- =============================================

-- 部门数据 (25个部门)
INSERT INTO `base_department` (`id`, `name`, `parent_id`) VALUES
(1, '总经办', 0), (2, '研发中心', 0), (3, '采购部', 0), (4, '仓储物流部', 0), (5, '行政人事部', 0),
(6, '财务部', 0), (7, '销售部', 0), (8, '市场部', 0), (9, '客服部', 0), (10, '质量部', 0),
(11, '前端开发组', 2), (12, '后端开发组', 2), (13, '测试组', 2), (14, '运维组', 2), (15, '产品组', 2),
(16, '仓库一组', 4), (17, '仓库二组', 4), (18, '配送组', 4),
(19, '华东销售部', 7), (20, '华南销售部', 7), (21, '华北销售部', 7),
(22, '采购一组', 3), (23, '采购二组', 3),
(24, '行政组', 5), (25, '人事组', 5);

-- 用户数据 (30个用户，密码统一: 123456)
INSERT INTO `sys_user` (`id`, `username`, `password`, `real_name`, `dept_id`, `role_code`, `status`) VALUES
(1, 'admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '系统管理员', 1, 'ADMIN', 1),
(2, 'ceo', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '张总', 1, 'ADMIN', 1),
-- 采购人员
(3, 'buyer01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '张采购', 22, 'BUYER', 1),
(4, 'buyer02', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '刘采购', 22, 'BUYER', 1),
(5, 'buyer03', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '王采购', 23, 'BUYER', 1),
(6, 'buyer04', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '陈采购', 23, 'BUYER', 1),
-- 仓库管理员
(7, 'warehouse01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '李仓管', 16, 'W_MGR', 1),
(8, 'warehouse02', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '周仓管', 16, 'W_MGR', 1),
(9, 'warehouse03', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '吴仓管', 17, 'W_MGR', 1),
(10, 'warehouse04', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '郑仓管', 17, 'W_MGR', 1),
-- 普通员工
(11, 'dev01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '孙前端', 11, 'STAFF', 1),
(12, 'dev02', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '钱前端', 11, 'STAFF', 1),
(13, 'dev03', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '赵后端', 12, 'STAFF', 1),
(14, 'dev04', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '马后端', 12, 'STAFF', 1),
(15, 'test01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '冯测试', 13, 'STAFF', 1),
(16, 'test02', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '褚测试', 13, 'STAFF', 1),
(17, 'ops01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '卫运维', 14, 'STAFF', 1),
(18, 'pm01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '蒋产品', 15, 'STAFF', 1),
(19, 'hr01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '沈人事', 25, 'STAFF', 1),
(20, 'admin01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '韩行政', 24, 'STAFF', 1),
(21, 'finance01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '杨财务', 6, 'STAFF', 1),
(22, 'sales01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '朱销售', 19, 'STAFF', 1),
(23, 'sales02', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '秦销售', 20, 'STAFF', 1),
(24, 'sales03', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '尤销售', 21, 'STAFF', 1),
(25, 'market01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '许市场', 8, 'STAFF', 1),
(26, 'cs01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '何客服', 9, 'STAFF', 1),
(27, 'qa01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '吕质量', 10, 'STAFF', 1),
(28, 'delivery01', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '施配送', 18, 'STAFF', 1),
(29, 'dev05', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '张开发', 11, 'STAFF', 1),
(30, 'dev06', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '李开发', 12, 'STAFF', 1);

-- 供应商数据 (20个供应商)
INSERT INTO `base_supplier` (`id`, `name`, `contact`, `phone`, `address`, `status`) VALUES
(1, '晨光文具有限公司', '张经理', '13800138001', '上海市浦东新区张江高科技园区', 1),
(2, '得力办公用品有限公司', '李经理', '13800138002', '浙江省宁波市鄞州区', 1),
(3, '联想电子科技有限公司', '王经理', '13800138003', '北京市海淀区中关村软件园', 1),
(4, '华为技术有限公司', '赵经理', '13800138004', '广东省深圳市龙岗区坂田街道', 1),
(5, '3M中国有限公司', '刘经理', '13800138005', '上海市闵行区漕河泾开发区', 1),
(6, '金士顿科技有限公司', '陈经理', '13800138006', '上海市闵行区七宝镇', 1),
(7, 'TP-LINK普联技术有限公司', '吴经理', '13800138007', '广东省深圳市南山区高新园', 1),
(8, '霍尼韦尔中国有限公司', '周经理', '13800138008', '上海市浦东新区陆家嘴', 1),
(9, '戴尔科技有限公司', '郑经理', '13800138009', '福建省厦门市湖里区', 1),
(10, '惠普科技有限公司', '冯经理', '13800138010', '上海市浦东新区金桥', 1),
(11, '罗技电子科技有限公司', '褚经理', '13800138011', '江苏省苏州市工业园区', 1),
(12, '西部数据信息技术有限公司', '卫经理', '13800138012', '上海市闵行区漕河泾', 1),
(13, '希捷科技有限公司', '蒋经理', '13800138013', '江苏省无锡市新吴区', 1),
(14, '闪迪科技有限公司', '沈经理', '13800138014', '上海市浦东新区张江', 1),
(15, '维达纸业有限公司', '韩经理', '13800138015', '广东省江门市新会区', 1),
(16, '滴露消毒用品有限公司', '杨经理', '13800138016', '上海市浦东新区外高桥', 1),
(17, '妙洁清洁用品有限公司', '朱经理', '13800138017', '广东省佛山市顺德区', 1),
(18, '美的集团股份有限公司', '秦经理', '13800138018', '广东省佛山市顺德区北滘镇', 1),
(19, '格力电器股份有限公司', '尤经理', '13800138019', '广东省珠海市香洲区', 1),
(20, '欧普照明股份有限公司', '许经理', '13800138020', '上海市金山区枫泾镇', 1);

-- 物资分类数据 (20个分类)
INSERT INTO `base_category` (`id`, `name`, `parent_id`) VALUES
(1, '办公用品', 0), (2, '电子设备', 0), (3, '劳保用品', 0), (4, '清洁用品', 0), (5, '家电设备', 0),
(6, '文具类', 1), (7, '纸张类', 1), (8, '办公耗材', 1), (9, '办公家具', 1),
(10, '计算机类', 2), (11, '网络设备', 2), (12, '存储设备', 2), (13, '外设配件', 2),
(14, '防护用品', 3), (15, '安全设备', 3),
(16, '清洁工具', 4), (17, '清洁耗材', 4),
(18, '空调设备', 5), (19, '照明设备', 5), (20, '饮水设备', 5);

-- =============================================
-- 第五部分: 物资档案数据 (80个产品)
-- =============================================
INSERT INTO `base_product` (`id`, `category_id`, `sku_code`, `name`, `specification`, `unit`, `stock_qty`, `alert_threshold`, `status`) VALUES
-- 文具类 (1-15)
(1, 6, 'SKU-WJ-001', '中性笔', '0.5mm 黑色 晨光', '支', 2500.0000, 500.0000, 1),
(2, 6, 'SKU-WJ-002', '中性笔', '0.5mm 蓝色 晨光', '支', 1800.0000, 400.0000, 1),
(3, 6, 'SKU-WJ-003', '中性笔', '0.5mm 红色 晨光', '支', 800.0000, 200.0000, 1),
(4, 6, 'SKU-WJ-004', '铅笔', 'HB 2B 得力', '支', 1200.0000, 300.0000, 1),
(5, 6, 'SKU-WJ-005', '自动铅笔', '0.5mm 晨光', '支', 350.0000, 100.0000, 1),
(6, 6, 'SKU-WJ-006', '橡皮擦', '4B绘图橡皮', '块', 600.0000, 150.0000, 1),
(7, 6, 'SKU-WJ-007', '订书机', '标准型 得力', '个', 180.0000, 50.0000, 1),
(8, 6, 'SKU-WJ-008', '订书钉', '24/6通用 10盒装', '盒', 500.0000, 100.0000, 1),
(9, 6, 'SKU-WJ-009', '剪刀', '办公剪 不锈钢', '把', 280.0000, 50.0000, 1),
(10, 6, 'SKU-WJ-010', '胶带', '透明胶带 宽4.5cm', '卷', 800.0000, 200.0000, 1),
(11, 6, 'SKU-WJ-011', '双面胶', '1.5cm宽 10米', '卷', 450.0000, 100.0000, 1),
(12, 6, 'SKU-WJ-012', '固体胶', '21g 得力', '支', 380.0000, 80.0000, 1),
(13, 6, 'SKU-WJ-013', '文件夹', 'A4 塑料 蓝色', '个', 650.0000, 150.0000, 1),
(14, 6, 'SKU-WJ-014', '档案盒', 'A4 5.5cm 牛皮纸', '个', 420.0000, 100.0000, 1),
(15, 6, 'SKU-WJ-015', '计算器', '12位显示 得力', '个', 120.0000, 30.0000, 1),
-- 纸张类 (16-25)
(16, 7, 'SKU-ZZ-001', 'A4打印纸', '70g 500张/包', '包', 1500.0000, 300.0000, 1),
(17, 7, 'SKU-ZZ-002', 'A4打印纸', '80g 500张/包', '包', 1200.0000, 250.0000, 1),
(18, 7, 'SKU-ZZ-003', 'A3打印纸', '80g 500张/包', '包', 350.0000, 80.0000, 1),
(19, 7, 'SKU-ZZ-004', '复写纸', '双面蓝色 100张/盒', '盒', 180.0000, 40.0000, 1),
(20, 7, 'SKU-ZZ-005', '便签纸', '76x76mm 黄色', '本', 1200.0000, 300.0000, 1),
(21, 7, 'SKU-ZZ-006', '便签纸', '76x76mm 彩色', '本', 800.0000, 200.0000, 1),
(22, 7, 'SKU-ZZ-007', '信封', '5号 白色 100个/包', '包', 280.0000, 60.0000, 1),
(23, 7, 'SKU-ZZ-008', '牛皮纸信封', 'A4 档案袋', '个', 450.0000, 100.0000, 1),
(24, 7, 'SKU-ZZ-009', '标签纸', 'A4 不干胶', '包', 320.0000, 80.0000, 1),
(25, 7, 'SKU-ZZ-010', '热敏打印纸', '80mm 收银纸', '卷', 600.0000, 150.0000, 1),
-- 办公耗材 (26-32)
(26, 8, 'SKU-HC-001', '硒鼓', 'HP LaserJet通用', '个', 85.0000, 20.0000, 1),
(27, 8, 'SKU-HC-002', '墨盒', 'HP彩色喷墨 三色', '个', 65.0000, 15.0000, 1),
(28, 8, 'SKU-HC-003', '碳粉', '通用型 200g装', '瓶', 120.0000, 30.0000, 1),
(29, 8, 'SKU-HC-004', '色带', '针式打印机通用', '个', 95.0000, 25.0000, 1),
(30, 8, 'SKU-HC-005', '打印头', '爱普生 LQ系列', '个', 25.0000, 5.0000, 1),
(31, 8, 'SKU-HC-006', '装订夹条', '10mm 塑料', '根', 2000.0000, 500.0000, 1),
(32, 8, 'SKU-HC-007', '塑封膜', 'A4 100张/包', '包', 180.0000, 40.0000, 1),
-- 办公家具 (33-36)
(33, 9, 'SKU-JJ-001', '办公椅', '人体工学 网布', '把', 45.0000, 10.0000, 1),
(34, 9, 'SKU-JJ-002', '办公桌', '1.4m 钢木结合', '张', 28.0000, 5.0000, 1),
(35, 9, 'SKU-JJ-003', '文件柜', '四层 钢制', '个', 22.0000, 5.0000, 1),
(36, 9, 'SKU-JJ-004', '会议桌', '3.2m 板式', '张', 8.0000, 2.0000, 1),
-- 计算机类 (37-48)
(37, 10, 'SKU-DN-001', '联想笔记本电脑', 'ThinkPad E14 i5/16G/512G', '台', 35.0000, 8.0000, 1),
(38, 10, 'SKU-DN-002', '联想笔记本电脑', 'ThinkPad T14 i7/32G/1T', '台', 18.0000, 5.0000, 1),
(39, 10, 'SKU-DN-003', '戴尔笔记本电脑', 'Latitude 5520 i5/16G/512G', '台', 25.0000, 5.0000, 1),
(40, 10, 'SKU-DN-004', '苹果笔记本电脑', 'MacBook Pro 14 M3/16G/512G', '台', 12.0000, 3.0000, 1),
(41, 10, 'SKU-DN-005', '戴尔台式机', 'OptiPlex 7090 i5/16G/512G', '台', 42.0000, 10.0000, 1),
(42, 10, 'SKU-DN-006', '联想台式机', 'ThinkCentre M90t i7/16G/512G', '台', 28.0000, 8.0000, 1),
(43, 10, 'SKU-DN-007', '显示器', '戴尔 27英寸 4K IPS', '台', 68.0000, 15.0000, 1),
(44, 10, 'SKU-DN-008', '显示器', '戴尔 24英寸 FHD', '台', 85.0000, 20.0000, 1),
(45, 10, 'SKU-DN-009', '显示器', 'LG 32英寸 曲面', '台', 32.0000, 8.0000, 1),
(46, 10, 'SKU-DN-010', '一体机电脑', '联想 23.8英寸 i5/8G/256G', '台', 15.0000, 5.0000, 1),
(47, 10, 'SKU-DN-011', '工作站', '戴尔 Precision 3660', '台', 8.0000, 2.0000, 1),
(48, 10, 'SKU-DN-012', '服务器', '戴尔 PowerEdge R750', '台', 5.0000, 1.0000, 1),
-- 外设配件 (49-58)
(49, 13, 'SKU-WS-001', '机械键盘', '罗技 G610 青轴', '个', 120.0000, 30.0000, 1),
(50, 13, 'SKU-WS-002', '薄膜键盘', '罗技 K120', '个', 180.0000, 40.0000, 1),
(51, 13, 'SKU-WS-003', '无线鼠标', '罗技 M590', '个', 200.0000, 50.0000, 1),
(52, 13, 'SKU-WS-004', '有线鼠标', '罗技 M100', '个', 250.0000, 60.0000, 1),
(53, 13, 'SKU-WS-005', '鼠标垫', '超大号 游戏鼠标垫', '个', 350.0000, 80.0000, 1),
(54, 13, 'SKU-WS-006', '耳机', '罗技 H340 USB', '个', 85.0000, 20.0000, 1),
(55, 13, 'SKU-WS-007', '摄像头', '罗技 C920 高清', '个', 65.0000, 15.0000, 1),
(56, 13, 'SKU-WS-008', '手写板', 'Wacom CTL-472', '个', 25.0000, 5.0000, 1),
(57, 13, 'SKU-WS-009', 'USB集线器', '7口 USB3.0 带电源', '个', 120.0000, 30.0000, 1),
(58, 13, 'SKU-WS-010', '笔记本支架', '铝合金 可调节', '个', 150.0000, 40.0000, 1),
-- 网络设备 (59-64)
(59, 11, 'SKU-WL-001', '路由器', 'TP-LINK AX3000 WiFi6', '台', 85.0000, 20.0000, 1),
(60, 11, 'SKU-WL-002', '交换机', '华为24口千兆', '台', 35.0000, 8.0000, 1),
(61, 11, 'SKU-WL-003', '交换机', 'TP-LINK 8口百兆', '台', 65.0000, 15.0000, 1),
(62, 11, 'SKU-WL-004', '网线', 'CAT6 超六类 1米', '根', 800.0000, 200.0000, 1),
(63, 11, 'SKU-WL-005', '网线', 'CAT6 超六类 3米', '根', 600.0000, 150.0000, 1),
(64, 11, 'SKU-WL-006', '网线', 'CAT6 超六类 5米', '根', 400.0000, 100.0000, 1),
-- 存储设备 (65-70)
(65, 12, 'SKU-CC-001', 'U盘', '金士顿 32GB USB3.0', '个', 280.0000, 60.0000, 1),
(66, 12, 'SKU-CC-002', 'U盘', '金士顿 64GB USB3.0', '个', 220.0000, 50.0000, 1),
(67, 12, 'SKU-CC-003', 'U盘', '金士顿 128GB USB3.0', '个', 150.0000, 35.0000, 1),
(68, 12, 'SKU-CC-004', '移动硬盘', '希捷 1TB USB3.0', '个', 75.0000, 18.0000, 1),
(69, 12, 'SKU-CC-005', '移动硬盘', '希捷 2TB USB3.0', '个', 45.0000, 10.0000, 1),
(70, 12, 'SKU-CC-006', 'SD卡', '闪迪 64GB Class10', '张', 160.0000, 40.0000, 1),
-- 防护用品 (71-76)
(71, 14, 'SKU-FH-001', '防护口罩', 'N95标准 霍尼韦尔', '个', 3500.0000, 800.0000, 1),
(72, 14, 'SKU-FH-002', '医用口罩', '一次性三层 50只/盒', '盒', 650.0000, 150.0000, 1),
(73, 14, 'SKU-FH-003', '防护手套', '乳胶材质 100只/盒', '盒', 380.0000, 80.0000, 1),
(74, 14, 'SKU-FH-004', '防护眼镜', '透明护目镜 3M', '副', 180.0000, 40.0000, 1),
(75, 14, 'SKU-FH-005', '安全帽', '工地用 ABS材质', '顶', 120.0000, 30.0000, 1),
(76, 14, 'SKU-FH-006', '防护服', '一次性 SMS材质', '套', 250.0000, 60.0000, 1),
-- 安全设备 (77-80)
(77, 15, 'SKU-AQ-001', '灭火器', '干粉4kg', '个', 85.0000, 20.0000, 1),
(78, 15, 'SKU-AQ-002', '应急灯', 'LED双头 消防', '个', 65.0000, 15.0000, 1),
(79, 15, 'SKU-AQ-003', '急救箱', '办公室急救包', '个', 42.0000, 10.0000, 1),
(80, 15, 'SKU-AQ-004', '灭火毯', '1.5m x 1.5m', '张', 55.0000, 12.0000, 1);

-- 继续添加更多产品
INSERT INTO `base_product` (`id`, `category_id`, `sku_code`, `name`, `specification`, `unit`, `stock_qty`, `alert_threshold`, `status`) VALUES
-- 清洁工具 (81-85)
(81, 16, 'SKU-QJ-001', '拖把', '平板拖 可替换布', '把', 75.0000, 20.0000, 1),
(82, 16, 'SKU-QJ-002', '扫把', '塑料软毛', '把', 90.0000, 25.0000, 1),
(83, 16, 'SKU-QJ-003', '垃圾桶', '塑料 15L', '个', 180.0000, 40.0000, 1),
(84, 16, 'SKU-QJ-004', '垃圾桶', '不锈钢 30L', '个', 65.0000, 15.0000, 1),
(85, 16, 'SKU-QJ-005', '簸箕', '塑料 带扫把套装', '套', 55.0000, 15.0000, 1),
-- 清洁耗材 (86-92)
(86, 17, 'SKU-QH-001', '垃圾袋', '黑色 大号 100只/卷', '卷', 380.0000, 80.0000, 1),
(87, 17, 'SKU-QH-002', '洗手液', '滴露 500ml', '瓶', 320.0000, 70.0000, 1),
(88, 17, 'SKU-QH-003', '抽纸', '维达 3层 120抽', '包', 850.0000, 200.0000, 1),
(89, 17, 'SKU-QH-004', '卷纸', '维达 4层 10卷/提', '提', 420.0000, 100.0000, 1),
(90, 17, 'SKU-QH-005', '消毒液', '84消毒液 1L', '瓶', 280.0000, 60.0000, 1),
(91, 17, 'SKU-QH-006', '洁厕剂', '威猛先生 500ml', '瓶', 180.0000, 40.0000, 1),
(92, 17, 'SKU-QH-007', '玻璃清洁剂', '蓝月亮 500ml', '瓶', 150.0000, 35.0000, 1),
-- 空调设备 (93-95)
(93, 18, 'SKU-KT-001', '空调', '格力 1.5匹 变频', '台', 28.0000, 5.0000, 1),
(94, 18, 'SKU-KT-002', '空调', '美的 3匹 柜机', '台', 15.0000, 3.0000, 1),
(95, 18, 'SKU-KT-003', '空调扇', '美的 冷风扇', '台', 35.0000, 8.0000, 1),
-- 照明设备 (96-98)
(96, 19, 'SKU-ZM-001', 'LED灯管', 'T8 1.2m 18W', '根', 250.0000, 60.0000, 1),
(97, 19, 'SKU-ZM-002', '台灯', 'LED护眼台灯', '台', 120.0000, 30.0000, 1),
(98, 19, 'SKU-ZM-003', '应急照明灯', 'LED 双头 充电式', '个', 85.0000, 20.0000, 1),
-- 饮水设备 (99-100)
(99, 20, 'SKU-YS-001', '饮水机', '美的 立式 冷热', '台', 22.0000, 5.0000, 1),
(100, 20, 'SKU-YS-002', '电热水壶', '美的 1.7L 不锈钢', '个', 65.0000, 15.0000, 1);

-- =============================================
-- 第六部分: 采购订单数据 (30条采购单)
-- =============================================
INSERT INTO `biz_procurement` (`id`, `order_no`, `applicant_id`, `supplier_id`, `status`, `reason`, `expected_date`, `created_at`) VALUES
-- 2024年10月份采购单 (已完成)
(1, 'PO20241001001', 3, 1, 'DONE', '10月份文具月度补货采购', '2024-10-10', '2024-10-01 09:30:00'),
(2, 'PO20241003001', 4, 3, 'DONE', '研发部笔记本电脑批量采购', '2024-10-15', '2024-10-03 10:00:00'),
(3, 'PO20241005001', 5, 8, 'DONE', '防疫物资季度补货', '2024-10-18', '2024-10-05 14:00:00'),
(4, 'PO20241008001', 3, 11, 'DONE', '外设配件采购-键盘鼠标', '2024-10-20', '2024-10-08 11:00:00'),
(5, 'PO20241010001', 6, 15, 'DONE', '清洁用品月度采购', '2024-10-22', '2024-10-10 09:00:00'),
-- 2024年11月份采购单 (已完成)
(6, 'PO20241101001', 4, 2, 'DONE', '11月份办公用品补货', '2024-11-10', '2024-11-01 08:45:00'),
(7, 'PO20241105001', 3, 9, 'DONE', '戴尔电脑设备采购', '2024-11-15', '2024-11-05 10:30:00'),
(8, 'PO20241108001', 5, 6, 'DONE', '存储设备批量采购', '2024-11-18', '2024-11-08 15:00:00'),
(9, 'PO20241112001', 6, 7, 'DONE', '网络设备更新采购', '2024-11-22', '2024-11-12 14:00:00'),
(10, 'PO20241115001', 4, 18, 'DONE', '家电设备采购-空调', '2024-11-25', '2024-11-15 09:30:00'),
-- 2024年12月份采购单 (部分完成,部分进行中)
(11, 'PO20241201001', 3, 1, 'DONE', '12月份文具补货', '2024-12-10', '2024-12-01 09:00:00'),
(12, 'PO20241203001', 5, 10, 'DONE', '惠普打印耗材采购', '2024-12-12', '2024-12-03 11:00:00'),
(13, 'PO20241205001', 4, 3, 'DONE', '年终设备采购-笔记本', '2024-12-15', '2024-12-05 10:00:00'),
(14, 'PO20241208001', 6, 17, 'DONE', '清洁工具采购', '2024-12-18', '2024-12-08 14:30:00'),
(15, 'PO20241210001', 3, 8, 'DONE', '防护用品采购', '2024-12-20', '2024-12-10 16:00:00'),
(16, 'PO20241212001', 5, 20, 'ORDERED', '照明设备采购', '2024-12-22', '2024-12-12 09:00:00'),
(17, 'PO20241215001', 4, 13, 'ORDERED', '移动硬盘批量采购', '2024-12-25', '2024-12-15 10:30:00'),
(18, 'PO20241216001', 3, 2, 'ORDERED', '办公家具采购-椅子', '2024-12-26', '2024-12-16 11:00:00'),
(19, 'PO20241218001', 6, 19, 'APPROVED', '格力空调采购', '2024-12-28', '2024-12-18 14:00:00'),
(20, 'PO20241219001', 5, 4, 'APPROVED', '华为网络设备采购', '2024-12-30', '2024-12-19 09:30:00'),
(21, 'PO20241220001', 4, 1, 'APPROVED', '元旦前文具补货', '2025-01-05', '2024-12-20 10:00:00'),
(22, 'PO20241221001', 3, 14, 'PENDING', 'SD卡U盘采购', '2025-01-08', '2024-12-21 15:30:00'),
(23, 'PO20241222001', 6, 16, 'PENDING', '消毒用品采购', '2025-01-10', '2024-12-22 08:00:00'),
(24, 'PO20241223001', 5, 11, 'PENDING', '外设配件采购-耳机摄像头', '2025-01-12', '2024-12-23 09:00:00'),
-- 更多采购单
(25, 'PO20241101002', 3, 5, 'DONE', '3M防护用品采购', '2024-11-12', '2024-11-02 10:00:00'),
(26, 'PO20241103001', 4, 12, 'DONE', '西部数据硬盘采购', '2024-11-15', '2024-11-03 14:00:00'),
(27, 'PO20241115002', 5, 15, 'DONE', '维达纸品采购', '2024-11-25', '2024-11-15 11:00:00'),
(28, 'PO20241120001', 6, 1, 'DONE', '晨光文具大宗采购', '2024-11-28', '2024-11-20 09:00:00'),
(29, 'PO20241125001', 3, 9, 'DONE', '戴尔显示器采购', '2024-12-05', '2024-11-25 15:00:00'),
(30, 'PO20241128001', 4, 7, 'DONE', 'TP-LINK网络设备采购', '2024-12-08', '2024-11-28 10:30:00');

-- =============================================
-- 第七部分: 采购明细数据 (约100条)
-- =============================================
INSERT INTO `biz_procurement_item` (`id`, `procurement_id`, `product_id`, `plan_qty`, `unit_price`) VALUES
-- PO20241001001 文具采购
(1, 1, 1, 500.0000, 1.50), (2, 1, 2, 400.0000, 1.50), (3, 1, 4, 300.0000, 0.80),
(4, 1, 7, 50.0000, 25.00), (5, 1, 16, 100.0000, 25.00),
-- PO20241003001 笔记本采购
(6, 2, 37, 10.0000, 4500.00), (7, 2, 38, 5.0000, 7800.00), (8, 2, 43, 15.0000, 2800.00),
-- PO20241005001 防疫物资
(9, 3, 71, 1000.0000, 3.50), (10, 3, 72, 200.0000, 35.00), (11, 3, 73, 100.0000, 45.00),
-- PO20241008001 外设采购
(12, 4, 49, 30.0000, 350.00), (13, 4, 50, 50.0000, 89.00), (14, 4, 51, 60.0000, 150.00), (15, 4, 52, 80.0000, 39.00),
-- PO20241010001 清洁用品
(16, 5, 86, 100.0000, 8.00), (17, 5, 87, 80.0000, 15.00), (18, 5, 88, 200.0000, 5.00), (19, 5, 89, 100.0000, 25.00),
-- PO20241101001 办公用品
(20, 6, 1, 600.0000, 1.50), (21, 6, 10, 200.0000, 3.00), (22, 6, 13, 150.0000, 5.00), (23, 6, 20, 300.0000, 2.50),
-- PO20241105001 戴尔设备
(24, 7, 39, 8.0000, 5200.00), (25, 7, 41, 12.0000, 4800.00), (26, 7, 44, 20.0000, 1200.00),
-- PO20241108001 存储设备
(27, 8, 65, 100.0000, 35.00), (28, 8, 66, 80.0000, 55.00), (29, 8, 68, 30.0000, 350.00),
-- PO20241112001 网络设备
(30, 9, 59, 20.0000, 280.00), (31, 9, 60, 10.0000, 850.00), (32, 9, 62, 200.0000, 5.00), (33, 9, 63, 150.0000, 8.00),
-- PO20241115001 空调
(34, 10, 93, 8.0000, 3200.00), (35, 10, 94, 4.0000, 5800.00),
-- PO20241201001 文具
(36, 11, 1, 400.0000, 1.50), (37, 11, 2, 300.0000, 1.50), (38, 11, 6, 150.0000, 2.00), (39, 11, 8, 100.0000, 18.00),
-- PO20241203001 打印耗材
(40, 12, 26, 30.0000, 180.00), (41, 12, 27, 25.0000, 120.00), (42, 12, 28, 40.0000, 45.00),
-- PO20241205001 笔记本
(43, 13, 37, 8.0000, 4500.00), (44, 13, 40, 5.0000, 15800.00), (45, 13, 43, 10.0000, 2800.00),
-- PO20241208001 清洁工具
(46, 14, 81, 20.0000, 35.00), (47, 14, 82, 25.0000, 18.00), (48, 14, 83, 50.0000, 25.00), (49, 14, 84, 20.0000, 120.00),
-- PO20241210001 防护
(50, 15, 71, 800.0000, 3.50), (51, 15, 74, 50.0000, 28.00), (52, 15, 76, 100.0000, 35.00),
-- PO20241212001 照明
(53, 16, 96, 80.0000, 18.00), (54, 16, 97, 40.0000, 85.00), (55, 16, 98, 30.0000, 65.00),
-- PO20241215001 硬盘
(56, 17, 68, 25.0000, 350.00), (57, 17, 69, 15.0000, 520.00),
-- PO20241216001 办公家具
(58, 18, 33, 15.0000, 580.00), (59, 18, 34, 8.0000, 850.00),
-- PO20241218001 空调
(60, 19, 93, 5.0000, 3200.00),
-- PO20241219001 华为设备
(61, 20, 60, 8.0000, 850.00),
-- PO20241220001 文具
(62, 21, 1, 500.0000, 1.50), (63, 21, 3, 200.0000, 1.50), (64, 21, 5, 100.0000, 8.00),
-- PO20241221001 存储
(65, 22, 70, 60.0000, 45.00), (66, 22, 65, 80.0000, 35.00),
-- PO20241222001 消毒
(67, 23, 90, 80.0000, 12.00), (68, 23, 91, 50.0000, 15.00),
-- PO20241223001 外设
(69, 24, 54, 30.0000, 120.00), (70, 24, 55, 20.0000, 280.00),
-- 更多明细
(71, 25, 74, 60.0000, 28.00), (72, 25, 75, 40.0000, 35.00),
(73, 26, 68, 20.0000, 350.00), (74, 26, 69, 12.0000, 520.00),
(75, 27, 88, 300.0000, 5.00), (76, 27, 89, 150.0000, 25.00),
(77, 28, 1, 800.0000, 1.50), (78, 28, 2, 600.0000, 1.50), (79, 28, 4, 400.0000, 0.80),
(80, 29, 43, 25.0000, 2800.00), (81, 29, 44, 30.0000, 1200.00),
(82, 30, 59, 15.0000, 280.00), (83, 30, 61, 20.0000, 120.00);

-- =============================================
-- 第八部分: 入库单数据 (25条)
-- =============================================
INSERT INTO `biz_inbound` (`id`, `inbound_no`, `source_id`, `is_temporary`, `status`, `inbound_date`, `warehouse_user_id`, `remark`, `created_at`) VALUES
-- 10月入库
(1, 'IN20241005001', 1, 0, 1, '2024-10-05 14:30:00', 7, '采购入库-文具', '2024-10-05 14:00:00'),
(2, 'IN20241010001', 2, 0, 1, '2024-10-10 16:00:00', 7, '采购入库-笔记本电脑', '2024-10-10 15:00:00'),
(3, 'IN20241012001', 3, 0, 1, '2024-10-12 11:30:00', 8, '采购入库-防疫物资', '2024-10-12 10:00:00'),
(4, 'IN20241015001', 4, 0, 1, '2024-10-15 15:00:00', 9, '采购入库-外设配件', '2024-10-15 14:00:00'),
(5, 'IN20241018001', 5, 0, 1, '2024-10-18 10:30:00', 10, '采购入库-清洁用品', '2024-10-18 09:30:00'),
-- 11月入库
(6, 'IN20241105001', 6, 0, 1, '2024-11-05 14:00:00', 7, '采购入库-办公用品', '2024-11-05 13:00:00'),
(7, 'IN20241110001', 7, 0, 1, '2024-11-10 16:30:00', 8, '采购入库-戴尔设备', '2024-11-10 15:30:00'),
(8, 'IN20241115001', 8, 0, 1, '2024-11-15 11:00:00', 9, '采购入库-存储设备', '2024-11-15 10:00:00'),
(9, 'IN20241118001', 9, 0, 1, '2024-11-18 14:30:00', 10, '采购入库-网络设备', '2024-11-18 13:30:00'),
(10, 'IN20241122001', 10, 0, 1, '2024-11-22 09:30:00', 7, '采购入库-空调设备', '2024-11-22 08:30:00'),
-- 12月入库
(11, 'IN20241205001', 11, 0, 1, '2024-12-05 14:00:00', 8, '采购入库-文具', '2024-12-05 13:00:00'),
(12, 'IN20241208001', 12, 0, 1, '2024-12-08 15:30:00', 9, '采购入库-打印耗材', '2024-12-08 14:30:00'),
(13, 'IN20241212001', 13, 0, 1, '2024-12-12 10:00:00', 10, '采购入库-笔记本', '2024-12-12 09:00:00'),
(14, 'IN20241215001', 14, 0, 1, '2024-12-15 16:00:00', 7, '采购入库-清洁工具', '2024-12-15 15:00:00'),
(15, 'IN20241218001', 15, 0, 1, '2024-12-18 11:30:00', 8, '采购入库-防护用品', '2024-12-18 10:30:00'),
-- 暂估入库
(16, 'IN20241220001', NULL, 1, 1, '2024-12-20 09:30:00', 9, '暂估入库-文具样品', '2024-12-20 09:00:00'),
(17, 'IN20241221001', NULL, 1, 1, '2024-12-21 10:00:00', 10, '暂估入库-办公耗材', '2024-12-21 09:30:00'),
-- 待处理
(18, 'IN20241222001', 16, 0, 0, NULL, NULL, '待验收入库-照明设备', '2024-12-22 08:00:00'),
(19, 'IN20241223001', 17, 0, 0, NULL, NULL, '待验收入库-移动硬盘', '2024-12-23 09:00:00'),
-- 更多已完成入库
(20, 'IN20241108001', 25, 0, 1, '2024-11-08 14:00:00', 7, '采购入库-3M防护用品', '2024-11-08 13:00:00'),
(21, 'IN20241110002', 26, 0, 1, '2024-11-10 11:00:00', 8, '采购入库-西部数据硬盘', '2024-11-10 10:00:00'),
(22, 'IN20241120001', 27, 0, 1, '2024-11-20 15:30:00', 9, '采购入库-维达纸品', '2024-11-20 14:30:00'),
(23, 'IN20241125001', 28, 0, 1, '2024-11-25 10:00:00', 10, '采购入库-晨光文具', '2024-11-25 09:00:00'),
(24, 'IN20241130001', 29, 0, 1, '2024-11-30 16:00:00', 7, '采购入库-戴尔显示器', '2024-11-30 15:00:00'),
(25, 'IN20241203001', 30, 0, 1, '2024-12-03 11:30:00', 8, '采购入库-TP-LINK设备', '2024-12-03 10:30:00');

-- =============================================
-- 第九部分: 入库明细数据 (约80条)
-- =============================================
INSERT INTO `biz_inbound_item` (`id`, `inbound_id`, `product_id`, `actual_qty`, `location`) VALUES
-- IN20241005001
(1, 1, 1, 500.0000, 'A-01-01'), (2, 1, 2, 400.0000, 'A-01-02'), (3, 1, 4, 300.0000, 'A-01-03'),
(4, 1, 7, 50.0000, 'A-02-01'), (5, 1, 16, 100.0000, 'A-02-02'),
-- IN20241010001
(6, 2, 37, 10.0000, 'B-01-01'), (7, 2, 38, 5.0000, 'B-01-02'), (8, 2, 43, 15.0000, 'B-01-03'),
-- IN20241012001
(9, 3, 71, 1000.0000, 'C-01-01'), (10, 3, 72, 200.0000, 'C-01-02'), (11, 3, 73, 100.0000, 'C-01-03'),
-- IN20241015001
(12, 4, 49, 30.0000, 'B-02-01'), (13, 4, 50, 50.0000, 'B-02-02'), (14, 4, 51, 60.0000, 'B-02-03'), (15, 4, 52, 80.0000, 'B-02-04'),
-- IN20241018001
(16, 5, 86, 100.0000, 'D-01-01'), (17, 5, 87, 80.0000, 'D-01-02'), (18, 5, 88, 200.0000, 'D-01-03'), (19, 5, 89, 100.0000, 'D-01-04'),
-- IN20241105001
(20, 6, 1, 600.0000, 'A-01-01'), (21, 6, 10, 200.0000, 'A-03-01'), (22, 6, 13, 150.0000, 'A-03-02'), (23, 6, 20, 300.0000, 'A-03-03'),
-- IN20241110001
(24, 7, 39, 8.0000, 'B-03-01'), (25, 7, 41, 12.0000, 'B-03-02'), (26, 7, 44, 20.0000, 'B-03-03'),
-- IN20241115001
(27, 8, 65, 100.0000, 'B-04-01'), (28, 8, 66, 80.0000, 'B-04-02'), (29, 8, 68, 30.0000, 'B-04-03'),
-- IN20241118001
(30, 9, 59, 20.0000, 'B-05-01'), (31, 9, 60, 10.0000, 'B-05-02'), (32, 9, 62, 200.0000, 'B-05-03'), (33, 9, 63, 150.0000, 'B-05-04'),
-- IN20241122001
(34, 10, 93, 8.0000, 'E-01-01'), (35, 10, 94, 4.0000, 'E-01-02'),
-- IN20241205001
(36, 11, 1, 400.0000, 'A-01-01'), (37, 11, 2, 300.0000, 'A-01-02'), (38, 11, 6, 150.0000, 'A-04-01'), (39, 11, 8, 100.0000, 'A-04-02'),
-- IN20241208001
(40, 12, 26, 30.0000, 'A-05-01'), (41, 12, 27, 25.0000, 'A-05-02'), (42, 12, 28, 40.0000, 'A-05-03'),
-- IN20241212001
(43, 13, 37, 8.0000, 'B-01-01'), (44, 13, 40, 5.0000, 'B-06-01'), (45, 13, 43, 10.0000, 'B-01-03'),
-- IN20241215001
(46, 14, 81, 20.0000, 'D-02-01'), (47, 14, 82, 25.0000, 'D-02-02'), (48, 14, 83, 50.0000, 'D-02-03'), (49, 14, 84, 20.0000, 'D-02-04'),
-- IN20241218001
(50, 15, 71, 800.0000, 'C-01-01'), (51, 15, 74, 50.0000, 'C-02-01'), (52, 15, 76, 100.0000, 'C-02-02'),
-- IN20241220001 暂估
(53, 16, 1, 100.0000, 'A-01-04'), (54, 16, 2, 80.0000, 'A-01-05'),
-- IN20241221001 暂估
(55, 17, 26, 10.0000, 'A-05-04'), (56, 17, 28, 15.0000, 'A-05-05'),
-- IN20241222001 待验收
(57, 18, 96, 80.0000, NULL), (58, 18, 97, 40.0000, NULL),
-- IN20241223001 待验收
(59, 19, 68, 25.0000, NULL), (60, 19, 69, 15.0000, NULL),
-- 更多入库明细
(61, 20, 74, 60.0000, 'C-03-01'), (62, 20, 75, 40.0000, 'C-03-02'),
(63, 21, 68, 20.0000, 'B-04-04'), (64, 21, 69, 12.0000, 'B-04-05'),
(65, 22, 88, 300.0000, 'D-01-03'), (66, 22, 89, 150.0000, 'D-01-04'),
(67, 23, 1, 800.0000, 'A-01-01'), (68, 23, 2, 600.0000, 'A-01-02'), (69, 23, 4, 400.0000, 'A-01-03'),
(70, 24, 43, 25.0000, 'B-01-03'), (71, 24, 44, 30.0000, 'B-01-04'),
(72, 25, 59, 15.0000, 'B-05-01'), (73, 25, 61, 20.0000, 'B-05-05');

-- =============================================
-- 第十部分: 出库单数据 (35条)
-- =============================================
INSERT INTO `biz_outbound` (`id`, `outbound_no`, `applicant_id`, `dept_id`, `status`, `purpose`, `reviewer_id`, `review_time`, `outbound_date`, `created_at`) VALUES
-- 10月份出库 (已完成)
(1, 'OUT20241008001', 11, 11, 'DONE', '前端组日常办公用品领用', 7, '2024-10-08 10:00:00', '2024-10-08 14:30:00', '2024-10-08 09:00:00'),
(2, 'OUT20241010001', 13, 12, 'DONE', '后端组新人入职设备领用', 7, '2024-10-10 11:00:00', '2024-10-10 15:00:00', '2024-10-10 10:00:00'),
(3, 'OUT20241012001', 20, 24, 'DONE', '行政部防疫物资领用', 8, '2024-10-12 09:30:00', '2024-10-12 10:30:00', '2024-10-12 09:00:00'),
(4, 'OUT20241015001', 15, 13, 'DONE', '测试组办公设备领用', 9, '2024-10-15 14:00:00', '2024-10-15 16:00:00', '2024-10-15 13:00:00'),
(5, 'OUT20241018001', 22, 19, 'DONE', '销售部外出展会物资领用', 10, '2024-10-18 10:00:00', '2024-10-18 11:30:00', '2024-10-18 09:30:00'),
-- 11月份出库 (已完成)
(6, 'OUT20241105001', 11, 11, 'DONE', '前端组项目加班物资', 7, '2024-11-05 14:00:00', '2024-11-05 15:30:00', '2024-11-05 13:00:00'),
(7, 'OUT20241108001', 14, 12, 'DONE', '后端组开发设备升级', 8, '2024-11-08 10:00:00', '2024-11-08 11:30:00', '2024-11-08 09:30:00'),
(8, 'OUT20241112001', 17, 14, 'DONE', '运维组机房设备领用', 9, '2024-11-12 15:00:00', '2024-11-12 16:30:00', '2024-11-12 14:00:00'),
(9, 'OUT20241115001', 18, 15, 'DONE', '产品组办公用品领用', 10, '2024-11-15 09:30:00', '2024-11-15 10:30:00', '2024-11-15 09:00:00'),
(10, 'OUT20241118001', 19, 25, 'DONE', '人事部培训物资领用', 7, '2024-11-18 11:00:00', '2024-11-18 14:00:00', '2024-11-18 10:30:00'),
(11, 'OUT20241120001', 21, 6, 'DONE', '财务部年终审计物资', 8, '2024-11-20 14:30:00', '2024-11-20 16:00:00', '2024-11-20 14:00:00'),
(12, 'OUT20241122001', 23, 20, 'DONE', '华南销售部客户拜访礼品', 9, '2024-11-22 10:00:00', '2024-11-22 11:30:00', '2024-11-22 09:30:00'),
(13, 'OUT20241125001', 25, 8, 'DONE', '市场部展会物资领用', 10, '2024-11-25 15:00:00', '2024-11-25 16:30:00', '2024-11-25 14:30:00'),
-- 12月份出库 (部分进行中)
(14, 'OUT20241201001', 11, 11, 'DONE', '前端组12月份日常办公用品', 7, '2024-12-01 10:00:00', '2024-12-01 11:30:00', '2024-12-01 09:30:00'),
(15, 'OUT20241205001', 12, 11, 'DONE', '前端组新人入职设备', 8, '2024-12-05 11:00:00', '2024-12-05 14:00:00', '2024-12-05 10:30:00'),
(16, 'OUT20241208001', 13, 12, 'DONE', '后端组开发环境升级', 9, '2024-12-08 14:00:00', '2024-12-08 15:30:00', '2024-12-08 13:30:00'),
(17, 'OUT20241210001', 15, 13, 'DONE', '测试组自动化测试设备', 10, '2024-12-10 10:00:00', '2024-12-10 11:30:00', '2024-12-10 09:30:00'),
(18, 'OUT20241212001', 20, 24, 'DONE', '行政部年终大扫除物资', 7, '2024-12-12 15:00:00', '2024-12-12 16:30:00', '2024-12-12 14:30:00'),
(19, 'OUT20241215001', 26, 9, 'DONE', '客服部工位设备更新', 8, '2024-12-15 09:30:00', '2024-12-15 10:30:00', '2024-12-15 09:00:00'),
(20, 'OUT20241216001', 27, 10, 'DONE', '质量部检测设备领用', 9, '2024-12-16 11:00:00', '2024-12-16 14:00:00', '2024-12-16 10:30:00'),
-- 已批准待领取
(21, 'OUT20241218001', 14, 12, 'APPROVED', '后端组年终项目冲刺物资', 7, '2024-12-18 14:00:00', NULL, '2024-12-18 10:00:00'),
(22, 'OUT20241219001', 24, 21, 'APPROVED', '华北销售部年终客户拜访', 8, '2024-12-19 11:00:00', NULL, '2024-12-19 09:30:00'),
(23, 'OUT20241220001', 16, 13, 'APPROVED', '测试组设备更新', 9, '2024-12-20 10:00:00', NULL, '2024-12-20 09:00:00'),
-- 待审核
(24, 'OUT20241221001', 11, 11, 'PENDING', '前端组元旦节前物资准备', NULL, NULL, NULL, '2024-12-21 13:00:00'),
(25, 'OUT20241222001', 12, 11, 'PENDING', '前端组新项目启动物资', NULL, NULL, NULL, '2024-12-22 09:30:00'),
(26, 'OUT20241222002', 17, 14, 'PENDING', '运维组机房维护物资', NULL, NULL, NULL, '2024-12-22 10:00:00'),
(27, 'OUT20241223001', 20, 24, 'PENDING', '行政部元旦活动物资', NULL, NULL, NULL, '2024-12-23 08:30:00'),
(28, 'OUT20241223002', 29, 11, 'PENDING', '前端组加班福利物资', NULL, NULL, NULL, '2024-12-23 09:00:00'),
(29, 'OUT20241223003', 30, 12, 'PENDING', '后端组服务器维护配件', NULL, NULL, NULL, '2024-12-23 10:30:00'),
-- 已驳回
(30, 'OUT20241210002', 11, 11, 'REJECT', '笔记本电脑申请(数量过多)', 1, '2024-12-10 16:00:00', NULL, '2024-12-10 14:00:00'),
(31, 'OUT20241215002', 22, 19, 'REJECT', '高端显示器申请(超出预算)', 1, '2024-12-15 17:00:00', NULL, '2024-12-15 15:00:00'),
-- 更多已完成
(32, 'OUT20241106001', 28, 18, 'DONE', '配送组车辆维护用品', 7, '2024-11-06 10:00:00', '2024-11-06 11:00:00', '2024-11-06 09:30:00'),
(33, 'OUT20241110001', 19, 25, 'DONE', '人事部招聘活动物资', 8, '2024-11-10 14:00:00', '2024-11-10 15:30:00', '2024-11-10 13:30:00'),
(34, 'OUT20241128001', 21, 6, 'DONE', '财务部办公用品领用', 9, '2024-11-28 10:00:00', '2024-11-28 11:00:00', '2024-11-28 09:30:00'),
(35, 'OUT20241130001', 25, 8, 'DONE', '市场部年终活动物资', 10, '2024-11-30 15:00:00', '2024-11-30 16:30:00', '2024-11-30 14:30:00');

-- =============================================
-- 第十一部分: 出库明细数据 (约100条)
-- =============================================
INSERT INTO `biz_outbound_item` (`id`, `outbound_id`, `product_id`, `apply_qty`, `actual_qty`) VALUES
-- OUT20241008001
(1, 1, 1, 30.0000, 30.0000), (2, 1, 2, 20.0000, 20.0000), (3, 1, 20, 15.0000, 15.0000),
-- OUT20241010001
(4, 2, 37, 2.0000, 2.0000), (5, 2, 43, 2.0000, 2.0000), (6, 2, 49, 2.0000, 2.0000), (7, 2, 51, 2.0000, 2.0000),
-- OUT20241012001
(8, 3, 71, 100.0000, 100.0000), (9, 3, 72, 20.0000, 20.0000), (10, 3, 87, 10.0000, 10.0000),
-- OUT20241015001
(11, 4, 37, 1.0000, 1.0000), (12, 4, 44, 2.0000, 2.0000), (13, 4, 51, 2.0000, 2.0000),
-- OUT20241018001
(14, 5, 65, 10.0000, 10.0000), (15, 5, 66, 5.0000, 5.0000), (16, 5, 88, 20.0000, 20.0000),
-- OUT20241105001
(17, 6, 1, 50.0000, 50.0000), (18, 6, 88, 30.0000, 30.0000), (19, 6, 89, 10.0000, 10.0000),
-- OUT20241108001
(20, 7, 38, 1.0000, 1.0000), (21, 7, 43, 2.0000, 2.0000), (22, 7, 68, 2.0000, 2.0000),
-- OUT20241112001
(23, 8, 60, 2.0000, 2.0000), (24, 8, 62, 30.0000, 30.0000), (25, 8, 63, 20.0000, 20.0000),
-- OUT20241115001
(26, 9, 1, 20.0000, 20.0000), (27, 9, 13, 15.0000, 15.0000), (28, 9, 20, 30.0000, 30.0000),
-- OUT20241118001
(29, 10, 16, 20.0000, 20.0000), (30, 10, 88, 50.0000, 50.0000),
-- OUT20241120001
(31, 11, 1, 30.0000, 30.0000), (32, 11, 16, 15.0000, 15.0000), (33, 11, 26, 3.0000, 3.0000),
-- OUT20241122001
(34, 12, 65, 15.0000, 15.0000), (35, 12, 66, 10.0000, 10.0000),
-- OUT20241125001
(36, 13, 1, 40.0000, 40.0000), (37, 13, 13, 20.0000, 20.0000), (38, 13, 88, 40.0000, 40.0000),
-- OUT20241201001
(39, 14, 1, 25.0000, 25.0000), (40, 14, 2, 15.0000, 15.0000), (41, 14, 20, 20.0000, 20.0000),
-- OUT20241205001
(42, 15, 37, 1.0000, 1.0000), (43, 15, 43, 1.0000, 1.0000), (44, 15, 49, 1.0000, 1.0000), (45, 15, 51, 1.0000, 1.0000),
-- OUT20241208001
(46, 16, 38, 2.0000, 2.0000), (47, 16, 68, 3.0000, 3.0000),
-- OUT20241210001
(48, 17, 41, 2.0000, 2.0000), (49, 17, 44, 3.0000, 3.0000),
-- OUT20241212001
(50, 18, 81, 5.0000, 5.0000), (51, 18, 82, 8.0000, 8.0000), (52, 18, 86, 20.0000, 20.0000), (53, 18, 90, 15.0000, 15.0000),
-- OUT20241215001
(54, 19, 50, 5.0000, 5.0000), (55, 19, 51, 5.0000, 5.0000), (56, 19, 54, 5.0000, 5.0000),
-- OUT20241216001
(57, 20, 44, 2.0000, 2.0000), (58, 20, 55, 2.0000, 2.0000),
-- OUT20241218001 待领取
(59, 21, 88, 30.0000, NULL), (60, 21, 89, 15.0000, NULL), (61, 21, 1, 40.0000, NULL),
-- OUT20241219001 待领取
(62, 22, 65, 20.0000, NULL), (63, 22, 66, 10.0000, NULL),
-- OUT20241220001 待领取
(64, 23, 41, 1.0000, NULL), (65, 23, 44, 2.0000, NULL),
-- OUT20241221001 待审核
(66, 24, 1, 50.0000, NULL), (67, 24, 2, 30.0000, NULL), (68, 24, 88, 40.0000, NULL),
-- OUT20241222001 待审核
(69, 25, 37, 2.0000, NULL), (70, 25, 49, 3.0000, NULL),
-- OUT20241222002 待审核
(71, 26, 60, 1.0000, NULL), (72, 26, 62, 20.0000, NULL),
-- OUT20241223001 待审核
(73, 27, 71, 50.0000, NULL), (74, 27, 87, 10.0000, NULL), (75, 27, 88, 50.0000, NULL),
-- OUT20241223002 待审核
(76, 28, 88, 30.0000, NULL), (77, 28, 100, 5.0000, NULL),
-- OUT20241223003 待审核
(78, 29, 62, 30.0000, NULL), (79, 29, 63, 20.0000, NULL), (80, 29, 57, 5.0000, NULL),
-- OUT20241210002 已驳回
(81, 30, 37, 15.0000, NULL), (82, 30, 38, 10.0000, NULL),
-- OUT20241215002 已驳回
(83, 31, 45, 8.0000, NULL),
-- 更多已完成
(84, 32, 86, 10.0000, 10.0000), (85, 32, 90, 5.0000, 5.0000),
(86, 33, 1, 30.0000, 30.0000), (87, 33, 16, 20.0000, 20.0000),
(88, 34, 1, 20.0000, 20.0000), (89, 34, 20, 25.0000, 25.0000),
(90, 35, 13, 30.0000, 30.0000), (91, 35, 88, 60.0000, 60.0000);

-- =============================================
-- 第十二部分: 库存流水数据 (约150条)
-- =============================================
INSERT INTO `biz_stock_log` (`product_id`, `type`, `change_qty`, `snapshot_qty`, `related_no`, `operator_id`, `created_at`) VALUES
-- 期初库存录入 (2024年10月1日)
(1, 'ADJUST', 1000.0000, 1000.0000, 'INIT-001', 1, '2024-10-01 00:00:00'),
(2, 'ADJUST', 800.0000, 800.0000, 'INIT-002', 1, '2024-10-01 00:00:00'),
(4, 'ADJUST', 600.0000, 600.0000, 'INIT-003', 1, '2024-10-01 00:00:00'),
(16, 'ADJUST', 800.0000, 800.0000, 'INIT-004', 1, '2024-10-01 00:00:00'),
(17, 'ADJUST', 500.0000, 500.0000, 'INIT-005', 1, '2024-10-01 00:00:00'),
(20, 'ADJUST', 600.0000, 600.0000, 'INIT-006', 1, '2024-10-01 00:00:00'),
(37, 'ADJUST', 15.0000, 15.0000, 'INIT-007', 1, '2024-10-01 00:00:00'),
(43, 'ADJUST', 40.0000, 40.0000, 'INIT-008', 1, '2024-10-01 00:00:00'),
(65, 'ADJUST', 150.0000, 150.0000, 'INIT-009', 1, '2024-10-01 00:00:00'),
(66, 'ADJUST', 120.0000, 120.0000, 'INIT-010', 1, '2024-10-01 00:00:00'),
(71, 'ADJUST', 1500.0000, 1500.0000, 'INIT-011', 1, '2024-10-01 00:00:00'),
(88, 'ADJUST', 400.0000, 400.0000, 'INIT-012', 1, '2024-10-01 00:00:00'),

-- 10月入库流水
(1, 'IN', 500.0000, 1500.0000, 'IN20241005001', 7, '2024-10-05 14:30:00'),
(2, 'IN', 400.0000, 1200.0000, 'IN20241005001', 7, '2024-10-05 14:30:00'),
(4, 'IN', 300.0000, 900.0000, 'IN20241005001', 7, '2024-10-05 14:30:00'),
(7, 'IN', 50.0000, 130.0000, 'IN20241005001', 7, '2024-10-05 14:30:00'),
(16, 'IN', 100.0000, 900.0000, 'IN20241005001', 7, '2024-10-05 14:30:00'),
(37, 'IN', 10.0000, 25.0000, 'IN20241010001', 7, '2024-10-10 16:00:00'),
(38, 'IN', 5.0000, 13.0000, 'IN20241010001', 7, '2024-10-10 16:00:00'),
(43, 'IN', 15.0000, 55.0000, 'IN20241010001', 7, '2024-10-10 16:00:00'),
(71, 'IN', 1000.0000, 2500.0000, 'IN20241012001', 8, '2024-10-12 11:30:00'),
(72, 'IN', 200.0000, 450.0000, 'IN20241012001', 8, '2024-10-12 11:30:00'),
(73, 'IN', 100.0000, 280.0000, 'IN20241012001', 8, '2024-10-12 11:30:00'),
(49, 'IN', 30.0000, 90.0000, 'IN20241015001', 9, '2024-10-15 15:00:00'),
(50, 'IN', 50.0000, 130.0000, 'IN20241015001', 9, '2024-10-15 15:00:00'),
(51, 'IN', 60.0000, 140.0000, 'IN20241015001', 9, '2024-10-15 15:00:00'),
(52, 'IN', 80.0000, 170.0000, 'IN20241015001', 9, '2024-10-15 15:00:00'),
(86, 'IN', 100.0000, 280.0000, 'IN20241018001', 10, '2024-10-18 10:30:00'),
(87, 'IN', 80.0000, 250.0000, 'IN20241018001', 10, '2024-10-18 10:30:00'),
(88, 'IN', 200.0000, 600.0000, 'IN20241018001', 10, '2024-10-18 10:30:00'),
(89, 'IN', 100.0000, 320.0000, 'IN20241018001', 10, '2024-10-18 10:30:00'),

-- 10月出库流水
(1, 'OUT', -30.0000, 1470.0000, 'OUT20241008001', 7, '2024-10-08 14:30:00'),
(2, 'OUT', -20.0000, 1180.0000, 'OUT20241008001', 7, '2024-10-08 14:30:00'),
(20, 'OUT', -15.0000, 585.0000, 'OUT20241008001', 7, '2024-10-08 14:30:00'),
(37, 'OUT', -2.0000, 23.0000, 'OUT20241010001', 7, '2024-10-10 15:00:00'),
(43, 'OUT', -2.0000, 53.0000, 'OUT20241010001', 7, '2024-10-10 15:00:00'),
(49, 'OUT', -2.0000, 88.0000, 'OUT20241010001', 7, '2024-10-10 15:00:00'),
(51, 'OUT', -2.0000, 138.0000, 'OUT20241010001', 7, '2024-10-10 15:00:00'),
(71, 'OUT', -100.0000, 2400.0000, 'OUT20241012001', 8, '2024-10-12 10:30:00'),
(72, 'OUT', -20.0000, 430.0000, 'OUT20241012001', 8, '2024-10-12 10:30:00'),
(87, 'OUT', -10.0000, 240.0000, 'OUT20241012001', 8, '2024-10-12 10:30:00'),
(37, 'OUT', -1.0000, 22.0000, 'OUT20241015001', 9, '2024-10-15 16:00:00'),
(44, 'OUT', -2.0000, 83.0000, 'OUT20241015001', 9, '2024-10-15 16:00:00'),
(51, 'OUT', -2.0000, 136.0000, 'OUT20241015001', 9, '2024-10-15 16:00:00'),
(65, 'OUT', -10.0000, 140.0000, 'OUT20241018001', 10, '2024-10-18 11:30:00'),
(66, 'OUT', -5.0000, 115.0000, 'OUT20241018001', 10, '2024-10-18 11:30:00'),
(88, 'OUT', -20.0000, 580.0000, 'OUT20241018001', 10, '2024-10-18 11:30:00'),

-- 11月入库流水
(1, 'IN', 600.0000, 2070.0000, 'IN20241105001', 7, '2024-11-05 14:00:00'),
(10, 'IN', 200.0000, 600.0000, 'IN20241105001', 7, '2024-11-05 14:00:00'),
(13, 'IN', 150.0000, 500.0000, 'IN20241105001', 7, '2024-11-05 14:00:00'),
(20, 'IN', 300.0000, 885.0000, 'IN20241105001', 7, '2024-11-05 14:00:00'),
(39, 'IN', 8.0000, 17.0000, 'IN20241110001', 8, '2024-11-10 16:30:00'),
(41, 'IN', 12.0000, 30.0000, 'IN20241110001', 8, '2024-11-10 16:30:00'),
(44, 'IN', 20.0000, 103.0000, 'IN20241110001', 8, '2024-11-10 16:30:00'),
(65, 'IN', 100.0000, 240.0000, 'IN20241115001', 9, '2024-11-15 11:00:00'),
(66, 'IN', 80.0000, 195.0000, 'IN20241115001', 9, '2024-11-15 11:00:00'),
(68, 'IN', 30.0000, 55.0000, 'IN20241115001', 9, '2024-11-15 11:00:00'),
(59, 'IN', 20.0000, 65.0000, 'IN20241118001', 10, '2024-11-18 14:30:00'),
(60, 'IN', 10.0000, 25.0000, 'IN20241118001', 10, '2024-11-18 14:30:00'),
(62, 'IN', 200.0000, 570.0000, 'IN20241118001', 10, '2024-11-18 14:30:00'),
(63, 'IN', 150.0000, 430.0000, 'IN20241118001', 10, '2024-11-18 14:30:00'),
(93, 'IN', 8.0000, 20.0000, 'IN20241122001', 7, '2024-11-22 09:30:00'),
(94, 'IN', 4.0000, 11.0000, 'IN20241122001', 7, '2024-11-22 09:30:00'),

-- 11月出库流水
(1, 'OUT', -50.0000, 2020.0000, 'OUT20241105001', 7, '2024-11-05 15:30:00'),
(88, 'OUT', -30.0000, 550.0000, 'OUT20241105001', 7, '2024-11-05 15:30:00'),
(89, 'OUT', -10.0000, 310.0000, 'OUT20241105001', 7, '2024-11-05 15:30:00'),
(38, 'OUT', -1.0000, 12.0000, 'OUT20241108001', 8, '2024-11-08 11:30:00'),
(43, 'OUT', -2.0000, 51.0000, 'OUT20241108001', 8, '2024-11-08 11:30:00'),
(68, 'OUT', -2.0000, 53.0000, 'OUT20241108001', 8, '2024-11-08 11:30:00'),
(60, 'OUT', -2.0000, 23.0000, 'OUT20241112001', 9, '2024-11-12 16:30:00'),
(62, 'OUT', -30.0000, 540.0000, 'OUT20241112001', 9, '2024-11-12 16:30:00'),
(63, 'OUT', -20.0000, 410.0000, 'OUT20241112001', 9, '2024-11-12 16:30:00'),
(1, 'OUT', -20.0000, 2000.0000, 'OUT20241115001', 10, '2024-11-15 10:30:00'),
(13, 'OUT', -15.0000, 485.0000, 'OUT20241115001', 10, '2024-11-15 10:30:00'),
(20, 'OUT', -30.0000, 855.0000, 'OUT20241115001', 10, '2024-11-15 10:30:00'),
(16, 'OUT', -20.0000, 880.0000, 'OUT20241118001', 7, '2024-11-18 14:00:00'),
(88, 'OUT', -50.0000, 500.0000, 'OUT20241118001', 7, '2024-11-18 14:00:00'),
(1, 'OUT', -30.0000, 1970.0000, 'OUT20241120001', 8, '2024-11-20 16:00:00'),
(16, 'OUT', -15.0000, 865.0000, 'OUT20241120001', 8, '2024-11-20 16:00:00'),
(26, 'OUT', -3.0000, 82.0000, 'OUT20241120001', 8, '2024-11-20 16:00:00'),
(65, 'OUT', -15.0000, 225.0000, 'OUT20241122001', 9, '2024-11-22 11:30:00'),
(66, 'OUT', -10.0000, 185.0000, 'OUT20241122001', 9, '2024-11-22 11:30:00'),
(1, 'OUT', -40.0000, 1930.0000, 'OUT20241125001', 10, '2024-11-25 16:30:00'),
(13, 'OUT', -20.0000, 465.0000, 'OUT20241125001', 10, '2024-11-25 16:30:00'),
(88, 'OUT', -40.0000, 460.0000, 'OUT20241125001', 10, '2024-11-25 16:30:00'),

-- 12月入库流水
(1, 'IN', 400.0000, 2330.0000, 'IN20241205001', 8, '2024-12-05 14:00:00'),
(2, 'IN', 300.0000, 1480.0000, 'IN20241205001', 8, '2024-12-05 14:00:00'),
(6, 'IN', 150.0000, 450.0000, 'IN20241205001', 8, '2024-12-05 14:00:00'),
(8, 'IN', 100.0000, 400.0000, 'IN20241205001', 8, '2024-12-05 14:00:00'),
(26, 'IN', 30.0000, 112.0000, 'IN20241208001', 9, '2024-12-08 15:30:00'),
(27, 'IN', 25.0000, 65.0000, 'IN20241208001', 9, '2024-12-08 15:30:00'),
(28, 'IN', 40.0000, 120.0000, 'IN20241208001', 9, '2024-12-08 15:30:00'),
(37, 'IN', 8.0000, 30.0000, 'IN20241212001', 10, '2024-12-12 10:00:00'),
(40, 'IN', 5.0000, 12.0000, 'IN20241212001', 10, '2024-12-12 10:00:00'),
(43, 'IN', 10.0000, 61.0000, 'IN20241212001', 10, '2024-12-12 10:00:00'),
(81, 'IN', 20.0000, 55.0000, 'IN20241215001', 7, '2024-12-15 16:00:00'),
(82, 'IN', 25.0000, 65.0000, 'IN20241215001', 7, '2024-12-15 16:00:00'),
(83, 'IN', 50.0000, 130.0000, 'IN20241215001', 7, '2024-12-15 16:00:00'),
(84, 'IN', 20.0000, 45.0000, 'IN20241215001', 7, '2024-12-15 16:00:00'),
(71, 'IN', 800.0000, 3200.0000, 'IN20241218001', 8, '2024-12-18 11:30:00'),
(74, 'IN', 50.0000, 130.0000, 'IN20241218001', 8, '2024-12-18 11:30:00'),
(76, 'IN', 100.0000, 200.0000, 'IN20241218001', 8, '2024-12-18 11:30:00'),

-- 12月出库流水
(1, 'OUT', -25.0000, 2305.0000, 'OUT20241201001', 7, '2024-12-01 11:30:00'),
(2, 'OUT', -15.0000, 1465.0000, 'OUT20241201001', 7, '2024-12-01 11:30:00'),
(20, 'OUT', -20.0000, 835.0000, 'OUT20241201001', 7, '2024-12-01 11:30:00'),
(37, 'OUT', -1.0000, 29.0000, 'OUT20241205001', 8, '2024-12-05 14:00:00'),
(43, 'OUT', -1.0000, 60.0000, 'OUT20241205001', 8, '2024-12-05 14:00:00'),
(49, 'OUT', -1.0000, 87.0000, 'OUT20241205001', 8, '2024-12-05 14:00:00'),
(51, 'OUT', -1.0000, 135.0000, 'OUT20241205001', 8, '2024-12-05 14:00:00'),
(38, 'OUT', -2.0000, 10.0000, 'OUT20241208001', 9, '2024-12-08 15:30:00'),
(68, 'OUT', -3.0000, 50.0000, 'OUT20241208001', 9, '2024-12-08 15:30:00'),
(41, 'OUT', -2.0000, 28.0000, 'OUT20241210001', 10, '2024-12-10 11:30:00'),
(44, 'OUT', -3.0000, 100.0000, 'OUT20241210001', 10, '2024-12-10 11:30:00'),
(81, 'OUT', -5.0000, 50.0000, 'OUT20241212001', 7, '2024-12-12 16:30:00'),
(82, 'OUT', -8.0000, 57.0000, 'OUT20241212001', 7, '2024-12-12 16:30:00'),
(86, 'OUT', -20.0000, 260.0000, 'OUT20241212001', 7, '2024-12-12 16:30:00'),
(90, 'OUT', -15.0000, 250.0000, 'OUT20241212001', 7, '2024-12-12 16:30:00'),
(50, 'OUT', -5.0000, 125.0000, 'OUT20241215001', 8, '2024-12-15 10:30:00'),
(51, 'OUT', -5.0000, 130.0000, 'OUT20241215001', 8, '2024-12-15 10:30:00'),
(54, 'OUT', -5.0000, 80.0000, 'OUT20241215001', 8, '2024-12-15 10:30:00'),
(44, 'OUT', -2.0000, 98.0000, 'OUT20241216001', 9, '2024-12-16 14:00:00'),
(55, 'OUT', -2.0000, 63.0000, 'OUT20241216001', 9, '2024-12-16 14:00:00'),

-- 盘点调整
(1, 'ADJUST', -5.0000, 2300.0000, 'CHK20241115001', 7, '2024-11-15 18:00:00'),
(88, 'ADJUST', 3.0000, 503.0000, 'CHK20241115001', 7, '2024-11-15 18:00:00'),
(43, 'ADJUST', -1.0000, 50.0000, 'CHK20241215001', 8, '2024-12-15 18:00:00'),
(65, 'ADJUST', 2.0000, 227.0000, 'CHK20241215001', 8, '2024-12-15 18:00:00');

-- =============================================
-- 第十三部分: 盘点单数据 (8条)
-- =============================================
INSERT INTO `biz_inventory_check` (`id`, `check_no`, `status`, `check_date`, `checker_id`, `remark`, `created_at`) VALUES
(1, 'CHK20241015001', 'FINISHED', '2024-10-15', 7, '10月中旬定期盘点-办公用品区', '2024-10-15 08:00:00'),
(2, 'CHK20241031001', 'FINISHED', '2024-10-31', 8, '10月末盘点-电子设备区', '2024-10-31 08:00:00'),
(3, 'CHK20241115001', 'FINISHED', '2024-11-15', 7, '11月中旬定期盘点-办公用品区', '2024-11-15 08:00:00'),
(4, 'CHK20241130001', 'FINISHED', '2024-11-30', 9, '11月末盘点-清洁用品区', '2024-11-30 08:00:00'),
(5, 'CHK20241215001', 'FINISHED', '2024-12-15', 8, '12月中旬定期盘点-电子设备区', '2024-12-15 08:00:00'),
(6, 'CHK20241220001', 'CHECKING', '2024-12-20', 10, '年终全面盘点-A区', '2024-12-20 08:00:00'),
(7, 'CHK20241221001', 'CHECKING', '2024-12-21', 7, '年终全面盘点-B区', '2024-12-21 08:00:00'),
(8, 'CHK20241222001', 'CHECKING', '2024-12-22', 8, '年终全面盘点-C区', '2024-12-22 08:00:00');

-- =============================================
-- 第十四部分: 盘点明细数据 (约50条)
-- =============================================
INSERT INTO `biz_inventory_check_item` (`id`, `check_id`, `product_id`, `book_qty`, `actual_qty`, `diff_qty`) VALUES
-- CHK20241015001
(1, 1, 1, 1470.0000, 1468.0000, -2.0000),
(2, 1, 2, 1180.0000, 1180.0000, 0.0000),
(3, 1, 4, 900.0000, 898.0000, -2.0000),
(4, 1, 16, 900.0000, 900.0000, 0.0000),
(5, 1, 20, 585.0000, 585.0000, 0.0000),
-- CHK20241031001
(6, 2, 37, 22.0000, 22.0000, 0.0000),
(7, 2, 43, 53.0000, 53.0000, 0.0000),
(8, 2, 49, 88.0000, 88.0000, 0.0000),
(9, 2, 51, 136.0000, 135.0000, -1.0000),
(10, 2, 65, 140.0000, 140.0000, 0.0000),
-- CHK20241115001
(11, 3, 1, 2005.0000, 2000.0000, -5.0000),
(12, 3, 10, 600.0000, 600.0000, 0.0000),
(13, 3, 13, 485.0000, 485.0000, 0.0000),
(14, 3, 88, 500.0000, 503.0000, 3.0000),
(15, 3, 89, 310.0000, 310.0000, 0.0000),
-- CHK20241130001
(16, 4, 86, 280.0000, 278.0000, -2.0000),
(17, 4, 87, 240.0000, 240.0000, 0.0000),
(18, 4, 88, 460.0000, 460.0000, 0.0000),
(19, 4, 89, 310.0000, 310.0000, 0.0000),
(20, 4, 90, 250.0000, 250.0000, 0.0000),
-- CHK20241215001
(21, 5, 37, 29.0000, 29.0000, 0.0000),
(22, 5, 43, 61.0000, 60.0000, -1.0000),
(23, 5, 44, 100.0000, 100.0000, 0.0000),
(24, 5, 65, 225.0000, 227.0000, 2.0000),
(25, 5, 68, 50.0000, 50.0000, 0.0000),
-- CHK20241220001 进行中
(26, 6, 1, 2305.0000, 2302.0000, -3.0000),
(27, 6, 2, 1465.0000, 1465.0000, 0.0000),
(28, 6, 4, 896.0000, 896.0000, 0.0000),
(29, 6, 6, 450.0000, 449.0000, -1.0000),
(30, 6, 7, 130.0000, 130.0000, 0.0000),
(31, 6, 8, 400.0000, 400.0000, 0.0000),
(32, 6, 10, 600.0000, 600.0000, 0.0000),
(33, 6, 13, 465.0000, 465.0000, 0.0000),
(34, 6, 16, 865.0000, 864.0000, -1.0000),
(35, 6, 20, 835.0000, 835.0000, 0.0000),
-- CHK20241221001 进行中
(36, 7, 37, 29.0000, 29.0000, 0.0000),
(37, 7, 38, 10.0000, 10.0000, 0.0000),
(38, 7, 41, 28.0000, 28.0000, 0.0000),
(39, 7, 43, 60.0000, 60.0000, 0.0000),
(40, 7, 44, 98.0000, 98.0000, 0.0000),
(41, 7, 49, 87.0000, 87.0000, 0.0000),
(42, 7, 51, 130.0000, 129.0000, -1.0000),
(43, 7, 59, 65.0000, 65.0000, 0.0000),
(44, 7, 60, 23.0000, 23.0000, 0.0000),
-- CHK20241222001 进行中
(45, 8, 71, 3200.0000, 3198.0000, -2.0000),
(46, 8, 72, 430.0000, 430.0000, 0.0000),
(47, 8, 73, 280.0000, 280.0000, 0.0000),
(48, 8, 74, 130.0000, 130.0000, 0.0000),
(49, 8, 76, 200.0000, 200.0000, 0.0000),
(50, 8, 77, 85.0000, 85.0000, 0.0000);

-- =============================================
-- 完成初始化
-- =============================================
SELECT '数据库初始化完成!' AS message;
SELECT CONCAT('部门: ', COUNT(*), ' 条') AS summary FROM base_department
UNION ALL SELECT CONCAT('用户: ', COUNT(*), ' 条') FROM sys_user
UNION ALL SELECT CONCAT('供应商: ', COUNT(*), ' 条') FROM base_supplier
UNION ALL SELECT CONCAT('分类: ', COUNT(*), ' 条') FROM base_category
UNION ALL SELECT CONCAT('产品: ', COUNT(*), ' 条') FROM base_product
UNION ALL SELECT CONCAT('采购单: ', COUNT(*), ' 条') FROM biz_procurement
UNION ALL SELECT CONCAT('入库单: ', COUNT(*), ' 条') FROM biz_inbound
UNION ALL SELECT CONCAT('出库单: ', COUNT(*), ' 条') FROM biz_outbound
UNION ALL SELECT CONCAT('库存流水: ', COUNT(*), ' 条') FROM biz_stock_log
UNION ALL SELECT CONCAT('盘点单: ', COUNT(*), ' 条') FROM biz_inventory_check;

