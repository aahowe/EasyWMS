-- =============================================
-- EasyWMS 数据库初始化脚本
-- 版本: V1.0
-- 数据库: MySQL 8.0
-- 引擎: InnoDB
-- 字符集: UTF8MB4
-- =============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS easywms DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE easywms;

-- =============================================
-- 基础数据表
-- =============================================

-- 1. 部门表
DROP TABLE IF EXISTS `base_department`;
CREATE TABLE `base_department` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '部门ID',
  `name` VARCHAR(64) NOT NULL COMMENT '部门名称',
  `parent_id` BIGINT NOT NULL DEFAULT 0 COMMENT '父部门ID，0表示顶级部门',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门表';

-- 2. 系统用户表
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` VARCHAR(64) NOT NULL COMMENT '登录账号',
  `password` VARCHAR(128) NOT NULL COMMENT '登录密码(BCrypt加密)',
  `real_name` VARCHAR(64) NOT NULL COMMENT '真实姓名',
  `dept_id` BIGINT NOT NULL COMMENT '部门ID',
  `role_code` VARCHAR(20) NOT NULL COMMENT '角色编码: ADMIN-管理员, W_MGR-仓管, BUYER-采购, STAFF-员工',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '账号状态: 1-启用, 0-禁用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_dept_id` (`dept_id`),
  KEY `idx_role_code` (`role_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统用户表';

-- 3. 供应商表
DROP TABLE IF EXISTS `base_supplier`;
CREATE TABLE `base_supplier` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '供应商ID',
  `name` VARCHAR(128) NOT NULL COMMENT '供应商名称',
  `contact` VARCHAR(32) DEFAULT NULL COMMENT '联系人',
  `phone` VARCHAR(20) DEFAULT NULL COMMENT '联系电话',
  `address` VARCHAR(255) DEFAULT NULL COMMENT '地址',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 1-启用, 0-停用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='供应商表';

-- 4. 物资分类表
DROP TABLE IF EXISTS `base_category`;
CREATE TABLE `base_category` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '分类ID',
  `name` VARCHAR(64) NOT NULL COMMENT '分类名称',
  `parent_id` BIGINT NOT NULL DEFAULT 0 COMMENT '父分类ID，0表示顶级分类',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物资分类表';

-- 5. 物资档案表
DROP TABLE IF EXISTS `base_product`;
CREATE TABLE `base_product` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '物资ID',
  `category_id` BIGINT NOT NULL COMMENT '所属分类ID',
  `sku_code` VARCHAR(64) NOT NULL COMMENT 'SKU编码',
  `name` VARCHAR(128) NOT NULL COMMENT '物资名称',
  `specification` VARCHAR(128) DEFAULT NULL COMMENT '规格型号',
  `unit` VARCHAR(20) NOT NULL COMMENT '计量单位',
  `stock_qty` DECIMAL(14,4) NOT NULL DEFAULT 0.0000 COMMENT '实时库存数量',
  `alert_threshold` DECIMAL(14,4) NOT NULL DEFAULT 0.0000 COMMENT '预警阈值',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 1-启用, 0-停用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sku_code` (`sku_code`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物资档案表';

-- =============================================
-- 业务单据表
-- =============================================

-- 6. 采购订单主表
DROP TABLE IF EXISTS `biz_procurement`;
CREATE TABLE `biz_procurement` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `order_no` VARCHAR(32) NOT NULL COMMENT '采购单号',
  `applicant_id` BIGINT NOT NULL COMMENT '申请人ID',
  `supplier_id` BIGINT DEFAULT NULL COMMENT '供应商ID',
  `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '状态: PENDING-待审, APPROVED-已批, ORDERED-已下单, DONE-完成',
  `reason` TEXT COMMENT '申请原因',
  `expected_date` DATE DEFAULT NULL COMMENT '预计到货日期',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_applicant_id` (`applicant_id`),
  KEY `idx_supplier_id` (`supplier_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='采购订单主表';

-- 7. 采购明细表
DROP TABLE IF EXISTS `biz_procurement_item`;
CREATE TABLE `biz_procurement_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
  `procurement_id` BIGINT NOT NULL COMMENT '采购单ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `plan_qty` DECIMAL(14,4) NOT NULL COMMENT '计划数量',
  `unit_price` DECIMAL(14,2) DEFAULT NULL COMMENT '单价',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_procurement_id` (`procurement_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='采购明细表';

-- 8. 入库单主表
DROP TABLE IF EXISTS `biz_inbound`;
CREATE TABLE `biz_inbound` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '入库ID',
  `inbound_no` VARCHAR(32) NOT NULL COMMENT '入库单号',
  `source_id` BIGINT DEFAULT NULL COMMENT '来源单ID(采购单ID)',
  `is_temporary` TINYINT NOT NULL DEFAULT 0 COMMENT '是否暂估: 1-暂估, 0-正常',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '状态: 1-已完成, 0-草稿',
  `inbound_date` DATETIME DEFAULT NULL COMMENT '入库时间',
  `warehouse_user_id` BIGINT DEFAULT NULL COMMENT '仓管员ID',
  `remark` TEXT COMMENT '备注',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_inbound_no` (`inbound_no`),
  KEY `idx_source_id` (`source_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='入库单主表';

-- 9. 入库明细表
DROP TABLE IF EXISTS `biz_inbound_item`;
CREATE TABLE `biz_inbound_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
  `inbound_id` BIGINT NOT NULL COMMENT '入库单ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `actual_qty` DECIMAL(14,4) NOT NULL COMMENT '实收数量',
  `location` VARCHAR(64) DEFAULT NULL COMMENT '库位',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_inbound_id` (`inbound_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='入库明细表';

-- 10. 出库主表
DROP TABLE IF EXISTS `biz_outbound`;
CREATE TABLE `biz_outbound` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '出库ID',
  `outbound_no` VARCHAR(32) NOT NULL COMMENT '出库单号',
  `applicant_id` BIGINT NOT NULL COMMENT '申请人ID',
  `dept_id` BIGINT NOT NULL COMMENT '领用部门ID',
  `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '状态: PENDING-待审, APPROVED-已批, DONE-已领用, REJECT-驳回',
  `purpose` TEXT COMMENT '用途',
  `reviewer_id` BIGINT DEFAULT NULL COMMENT '审核人ID',
  `review_time` DATETIME DEFAULT NULL COMMENT '审核时间',
  `outbound_date` DATETIME DEFAULT NULL COMMENT '出库时间',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_outbound_no` (`outbound_no`),
  KEY `idx_applicant_id` (`applicant_id`),
  KEY `idx_dept_id` (`dept_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='出库主表';

-- 11. 领用明细表
DROP TABLE IF EXISTS `biz_outbound_item`;
CREATE TABLE `biz_outbound_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
  `outbound_id` BIGINT NOT NULL COMMENT '出库单ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `apply_qty` DECIMAL(14,4) NOT NULL COMMENT '申请数量',
  `actual_qty` DECIMAL(14,4) DEFAULT NULL COMMENT '实发数量',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_outbound_id` (`outbound_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='领用明细表';

-- 12. 库存流水表
DROP TABLE IF EXISTS `biz_stock_log`;
CREATE TABLE `biz_stock_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `type` VARCHAR(10) NOT NULL COMMENT '变动类型: IN-入库, OUT-出库, ADJUST-盘点调整',
  `change_qty` DECIMAL(14,4) NOT NULL COMMENT '变动数量(正数为增,负数为减)',
  `snapshot_qty` DECIMAL(14,4) NOT NULL COMMENT '变动后的库存快照',
  `related_no` VARCHAR(32) DEFAULT NULL COMMENT '关联单号',
  `operator_id` BIGINT DEFAULT NULL COMMENT '操作人ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发生时间',
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_type` (`type`),
  KEY `idx_related_no` (`related_no`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='库存流水表';

-- 13. 盘点主表
DROP TABLE IF EXISTS `biz_inventory_check`;
CREATE TABLE `biz_inventory_check` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '盘点ID',
  `check_no` VARCHAR(32) NOT NULL COMMENT '盘点单号',
  `status` VARCHAR(20) NOT NULL DEFAULT 'CHECKING' COMMENT '状态: CHECKING-盘点中, FINISHED-已调账结束',
  `check_date` DATE NOT NULL COMMENT '盘点日期',
  `checker_id` BIGINT DEFAULT NULL COMMENT '盘点人ID',
  `remark` TEXT COMMENT '备注',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_check_no` (`check_no`),
  KEY `idx_status` (`status`),
  KEY `idx_check_date` (`check_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='盘点主表';

-- 14. 盘点差异表
DROP TABLE IF EXISTS `biz_inventory_check_item`;
CREATE TABLE `biz_inventory_check_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
  `check_id` BIGINT NOT NULL COMMENT '盘点单ID',
  `product_id` BIGINT NOT NULL COMMENT '物资ID',
  `book_qty` DECIMAL(14,4) NOT NULL COMMENT '账面数量',
  `actual_qty` DECIMAL(14,4) NOT NULL COMMENT '实盘数量',
  `diff_qty` DECIMAL(14,4) NOT NULL COMMENT '盈亏数量(实盘-账面)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_check_id` (`check_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='盘点差异表';

-- =============================================
-- 外键约束
-- =============================================

-- 用户表外键
ALTER TABLE `sys_user` ADD CONSTRAINT `fk_user_dept` FOREIGN KEY (`dept_id`) REFERENCES `base_department` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 物资档案表外键
ALTER TABLE `base_product` ADD CONSTRAINT `fk_product_category` FOREIGN KEY (`category_id`) REFERENCES `base_category` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 采购订单主表外键
ALTER TABLE `biz_procurement` ADD CONSTRAINT `fk_procurement_applicant` FOREIGN KEY (`applicant_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `biz_procurement` ADD CONSTRAINT `fk_procurement_supplier` FOREIGN KEY (`supplier_id`) REFERENCES `base_supplier` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 采购明细表外键
ALTER TABLE `biz_procurement_item` ADD CONSTRAINT `fk_procurement_item_procurement` FOREIGN KEY (`procurement_id`) REFERENCES `biz_procurement` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `biz_procurement_item` ADD CONSTRAINT `fk_procurement_item_product` FOREIGN KEY (`product_id`) REFERENCES `base_product` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 入库单主表外键
ALTER TABLE `biz_inbound` ADD CONSTRAINT `fk_inbound_source` FOREIGN KEY (`source_id`) REFERENCES `biz_procurement` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `biz_inbound` ADD CONSTRAINT `fk_inbound_warehouse_user` FOREIGN KEY (`warehouse_user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 入库明细表外键
ALTER TABLE `biz_inbound_item` ADD CONSTRAINT `fk_inbound_item_inbound` FOREIGN KEY (`inbound_id`) REFERENCES `biz_inbound` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `biz_inbound_item` ADD CONSTRAINT `fk_inbound_item_product` FOREIGN KEY (`product_id`) REFERENCES `base_product` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 出库主表外键
ALTER TABLE `biz_outbound` ADD CONSTRAINT `fk_outbound_applicant` FOREIGN KEY (`applicant_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `biz_outbound` ADD CONSTRAINT `fk_outbound_dept` FOREIGN KEY (`dept_id`) REFERENCES `base_department` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `biz_outbound` ADD CONSTRAINT `fk_outbound_reviewer` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 领用明细表外键
ALTER TABLE `biz_outbound_item` ADD CONSTRAINT `fk_outbound_item_outbound` FOREIGN KEY (`outbound_id`) REFERENCES `biz_outbound` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `biz_outbound_item` ADD CONSTRAINT `fk_outbound_item_product` FOREIGN KEY (`product_id`) REFERENCES `base_product` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 库存流水表外键
ALTER TABLE `biz_stock_log` ADD CONSTRAINT `fk_stock_log_product` FOREIGN KEY (`product_id`) REFERENCES `base_product` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `biz_stock_log` ADD CONSTRAINT `fk_stock_log_operator` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 盘点主表外键
ALTER TABLE `biz_inventory_check` ADD CONSTRAINT `fk_inventory_check_checker` FOREIGN KEY (`checker_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- 盘点差异表外键
ALTER TABLE `biz_inventory_check_item` ADD CONSTRAINT `fk_inventory_check_item_check` FOREIGN KEY (`check_id`) REFERENCES `biz_inventory_check` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `biz_inventory_check_item` ADD CONSTRAINT `fk_inventory_check_item_product` FOREIGN KEY (`product_id`) REFERENCES `base_product` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- =============================================
-- 初始化完成
-- =============================================
