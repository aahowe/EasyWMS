# EasyWMS - 简易仓库管理系统

一套轻量级、高并发的仓库管理系统，基于 Go + Vue 3 + MySQL 技术栈开发。

## 项目简介

EasyWMS 旨在为中小企业提供一套完整的物资管理解决方案，实现物资从采购申请到入库、再到消耗出库的全生命周期数字化管理。

### 核心功能

- 📦 **基础数据管理** - 物资档案、供应商、部门、用户管理
- 🛒 **采购管理** - 采购申请、审核、订单生成
- 📥 **入库管理** - 到货验收、正常入库、暂估入库
- 📤 **出库管理** - 领用申请、审核、出库执行
- 📊 **统计与盘点** - 库存查询、统计报表、库存盘点

### 技术特点

- ✅ 前后端分离架构
- ✅ RESTful API设计
- ✅ JWT身份认证
- ✅ RBAC权限控制
- ✅ 悲观锁防止并发超卖
- ✅ 支持暂估入库（货到票未到）
- ✅ 完整的库存流水追溯

## 技术栈

**后端**
- Go 1.20+
- Gin Web Framework
- GORM (MySQL)
- JWT
- Viper

**前端**
- Vue 3
- Element Plus
- Vite
- Pinia
- Axios
- ECharts

**数据库**
- MySQL 8.0
- InnoDB引擎

## 项目结构

```
EasyWMS/
├── apps/
│   ├── backend/            # 后端项目（Go）
│   └── frontend/           # 前端项目（Vue 3）
├── db/                     # 数据库脚本
│   ├── schema.sql          # 建表脚本
│   └── data.sql            # 初始化数据
└── docs/                   # 项目文档
    ├── 功能需求说明书.md
    └── 项目代码结构说明.md
```

## 快速开始

### 1. 初始化数据库

```bash
# 创建数据库并导入表结构
mysql -u root -p < db/schema.sql

# 导入初始化数据
mysql -u root -p < db/data.sql
```

### 2. 启动后端服务

```bash
cd apps/backend

# 复制配置文件
cp config/config.example.yaml config/config.yaml

# 编辑配置文件，修改数据库连接信息
vim config/config.yaml

# 安装依赖
go mod download

# 运行服务
go run cmd/server/main.go
```

后端服务将在 `http://localhost:8080` 启动

### 3. 启动前端服务

```bash
cd apps/frontend

# 安装依赖
pnpm install

# 运行开发服务器
pnpm dev
```

前端服务将在 `http://localhost:5666` 启动

### 4. 登录系统

默认测试账号：

| 用户名 | 密码 | 角色 |
| --- | --- | --- |
| admin | 123456 | 系统管理员 |
| buyer01 | 123456 | 采购专员 |
| warehouse01 | 123456 | 仓库管理员 |
| staff01 | 123456 | 部门员工 |

## 文档

- [功能需求说明书](docs/功能需求说明书.md) - 详细的功能需求和业务流程
- [项目代码结构说明](docs/项目代码结构说明.md) - 技术架构和代码结构说明
- [后端README](apps/backend/README.md) - 后端项目说明

## 系统角色

| 角色 | 权限 |
| --- | --- |
| 系统管理员 (ADMIN) | 全部功能 + 用户管理 + 采购审批 |
| 采购专员 (BUYER) | 采购申请、订单生成、供应商管理 |
| 仓库管理员 (W_MGR) | 入库管理、出库审核、库存盘点 |
| 部门员工 (STAFF) | 库存查询、领用申请 |

## 核心业务流程

### 采购流程
```
采购申请 → 管理员审核 → 生成订单 → 到货验收 → 入库 → 完成
```

### 出库流程
```
领用申请 → 仓管审核 → 执行出库 → 库存扣减 → 完成
```

### 盘点流程
```
创建盘点任务 → 录入实盘数量 → 生成差异报告 → 审批调整 → 完成
```

## 数据库设计

系统共14张表：

**基础数据表（5张）**
- sys_user - 系统用户表
- base_department - 部门表
- base_supplier - 供应商表
- base_category - 物资分类表
- base_product - 物资档案表

**业务单据表（9张）**
- biz_procurement - 采购订单主表
- biz_procurement_item - 采购明细表
- biz_inbound - 入库单主表
- biz_inbound_item - 入库明细表
- biz_outbound - 出库主表
- biz_outbound_item - 领用明细表
- biz_stock_log - 库存流水表
- biz_inventory_check - 盘点主表
- biz_inventory_check_item - 盘点差异表

## 开发规范

### Git提交规范

```
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建/工具链相关
```

### 代码规范

- Go代码遵循官方规范，使用 gofmt 格式化
- Vue代码遵循 Vue 3 官方风格指南
- 使用 ESLint 和 golint 进行代码检查

## 注意事项

1. **数据库字符集**：必须使用 `utf8mb4`
2. **密码加密**：使用 BCrypt 算法
3. **并发控制**：库存扣减使用悲观锁
4. **事务处理**：入库、出库操作必须在事务中执行
5. **JWT密钥**：生产环境必须修改JWT密钥

## 开发进度

### 已完成 ✅
- 项目结构搭建
- 数据库设计
- 后端框架搭建（Gin + GORM）
- 中间件实现（JWT、CORS、Logger）
- 基础工具函数
- 前端项目初始化

### 进行中 🚧
- DAO层实现
- Service层业务逻辑
- Controller层接口实现
- 前端页面开发

### 待开发 ⏳
- 完整的CRUD操作
- 采购管理业务流程
- 入库管理业务流程
- 出库管理业务流程
- 统计与盘点功能
- 单元测试
- 集成测试

## 许可证

MIT License

## 联系方式

如有问题或建议，请提交 Issue。

---

**EasyWMS** - 让仓库管理更简单
