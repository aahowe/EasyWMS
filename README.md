# EasyWMS - 简易仓库管理系统

<p align="center">
  <img src="https://img.shields.io/badge/Go-1.20+-00ADD8?style=flat-square&logo=go" alt="Go Version" />
  <img src="https://img.shields.io/badge/Vue-3.5+-4FC08D?style=flat-square&logo=vue.js" alt="Vue Version" />
  <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat-square&logo=mysql" alt="MySQL Version" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" />
</p>

一套轻量级、高并发的仓库管理系统，基于 Go + Vue 3 + MySQL 技术栈开发。

## 📖 项目简介

EasyWMS 旨在为中小企业提供一套完整的物资管理解决方案，实现物资从采购申请到入库、再到消耗出库的全生命周期数字化管理。

### ✨ 核心功能

| 模块 | 功能 | 描述 |
| --- | --- | --- |
| 📦 **基础数据管理** | 物资档案、供应商、部门、用户管理 | 系统基础配置和主数据维护 |
| 🛒 **采购管理** | 采购申请、审核、订单生成 | 完整的采购业务流程 |
| 📥 **入库管理** | 到货验收、正常入库、暂估入库 | 支持货到票未到场景 |
| 📤 **出库管理** | 领用申请、审核、出库执行 | 规范的物资领用流程 |
| 📊 **统计与盘点** | 库存查询、统计报表、库存盘点 | 数据分析与账实核对 |

### 🛠️ 技术特点

- ✅ 前后端分离架构
- ✅ RESTful API 设计
- ✅ JWT 身份认证
- ✅ RBAC 权限控制
- ✅ 悲观锁防止并发超卖
- ✅ 支持暂估入库（货到票未到）
- ✅ 完整的库存流水追溯
- ✅ Docker 一键部署

## 🏗️ 技术栈

### 后端

| 技术 | 版本 | 说明 |
| --- | --- | --- |
| Go | 1.20+ | 主开发语言 |
| Gin | 1.9+ | Web 框架 |
| GORM | 1.25+ | ORM 框架 |
| JWT | - | 身份认证 |
| Viper | - | 配置管理 |
| BCrypt | - | 密码加密 |

### 前端

| 技术 | 版本 | 说明 |
| --- | --- | --- |
| Vue | 3.5+ | 前端框架 |
| Ant Design Vue | 4.x | UI 组件库 |
| Vite | 7.x | 构建工具 |
| Pinia | 3.x | 状态管理 |
| Vue Router | 4.x | 路由管理 |
| Axios | - | HTTP 客户端 |
| ECharts | 6.x | 图表库 |
| VxeTable | 4.x | 表格组件 |

### 数据库

- MySQL 8.0（InnoDB 引擎，UTF8MB4 字符集）

## 📁 项目结构

```
EasyWMS/
├── apps/
│   ├── backend/                # 后端项目（Go）
│   │   ├── cmd/server/         # 应用入口
│   │   ├── internal/           # 内部模块
│   │   │   ├── config/         # 配置管理
│   │   │   ├── database/       # 数据库连接
│   │   │   ├── handler/        # HTTP 处理器
│   │   │   ├── middleware/     # 中间件
│   │   │   ├── model/          # 数据模型
│   │   │   ├── router/         # 路由配置
│   │   │   └── utils/          # 工具函数
│   │   └── config/             # 配置文件
│   └── frontend/               # 前端项目（Vue 3）
│       └── src/
│           ├── api/            # API 接口
│           ├── views/          # 页面组件
│           │   ├── _core/      # 核心页面（登录、个人中心等）
│           │   ├── dashboard/  # 仪表盘
│           │   └── wms/        # 仓库管理业务页面
│           ├── router/         # 路由配置
│           └── store/          # 状态管理
├── db/                         # 数据库脚本
│   └── init_all.sql            # 初始化脚本
├── docker/                     # Docker 配置
├── docs/                       # 项目文档
│   ├── 功能需求说明书.md
│   ├── 项目代码结构说明.md
│   └── Docker部署指南.md
├── packages/                   # 公共包
│   ├── @core/                  # 核心模块
│   └── effects/                # 效果模块
├── internal/                   # 内部工具
├── docker-compose.yml          # Docker Compose 配置
└── README.md
```

## 🚀 快速开始

### 环境要求

- Node.js >= 20.12.0
- pnpm >= 10.0.0
- Go >= 1.20
- MySQL >= 8.0

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd EasyWMS
```

### 2. 初始化数据库

```bash
# 创建数据库并导入初始化脚本
mysql -u root -p < db/init_all.sql
```

### 3. 启动后端服务

```bash
cd apps/backend

# 复制配置文件
cp config/config.example.yaml config/config.yaml

# 编辑配置文件，修改数据库连接信息
vim config/config.yaml

# 安装依赖并运行
go mod download
go run cmd/server/main.go
```

后端服务将在 `http://localhost:8080` 启动

### 4. 启动前端服务

```bash
# 在项目根目录执行
pnpm install
pnpm dev:frontend
```

前端服务将在 `http://localhost:5666` 启动

### 5. 登录系统

默认测试账号：

| 用户名 | 密码 | 角色 | 权限说明 |
| --- | --- | --- | --- |
| admin | 123456 | 系统管理员 | 全部功能 + 用户管理 + 采购审批 |
| buyer01 | 123456 | 采购专员 | 采购申请、订单生成、供应商管理 |
| warehouse01 | 123456 | 仓库管理员 | 入库管理、出库审核、库存盘点 |
| staff01 | 123456 | 部门员工 | 库存查询、领用申请 |

## 🐳 Docker 部署

### 快速部署

```bash
# 构建并启动所有服务
docker compose up -d --build

# 查看服务状态
docker compose ps
```

访问地址：
- 前端：`http://your-server-ip:9528`
- 后端 API：`http://your-server-ip:9527/api`

详细部署指南请参考 [Docker部署指南](docs/Docker部署指南.md)

## 📊 系统角色权限

| 角色代码 | 角色名称 | 核心职责 |
| --- | --- | --- |
| ADMIN | 系统管理员 | 系统配置、基础数据管理、采购审批 |
| BUYER | 采购专员 | 供应商管理、采购申请、订单生成 |
| W_MGR | 仓库管理员 | 入库验收、出库审核、库存盘点 |
| STAFF | 部门员工 | 库存查询、物资领用申请 |

## 🔄 核心业务流程

### 采购流程

```
采购申请 → 管理员审核 → 生成订单 → 到货验收 → 入库 → 完成
    ↓           ↓
  驳回回退    驳回回退
```

### 出库流程

```
领用申请 → 仓管审核 → 执行出库 → 库存扣减 → 完成
    ↓          ↓
  驳回回退   驳回回退
```

### 盘点流程

```
创建盘点任务 → 录入实盘数量 → 生成差异报告 → 审批调整 → 完成
```

## 📚 数据库设计

系统共 14 张表：

### 基础数据表（5张）

| 表名 | 说明 |
| --- | --- |
| sys_user | 系统用户表 |
| base_department | 部门表 |
| base_supplier | 供应商表 |
| base_category | 物资分类表 |
| base_product | 物资档案表 |

### 业务单据表（9张）

| 表名 | 说明 |
| --- | --- |
| biz_procurement | 采购订单主表 |
| biz_procurement_item | 采购明细表 |
| biz_inbound | 入库单主表 |
| biz_inbound_item | 入库明细表 |
| biz_outbound | 出库主表 |
| biz_outbound_item | 领用明细表 |
| biz_stock_log | 库存流水表 |
| biz_inventory_check | 盘点主表 |
| biz_inventory_check_item | 盘点差异表 |

## 🔧 开发命令

```bash
# 安装依赖
pnpm install

# 启动前端开发服务器
pnpm dev:frontend

# 构建前端
pnpm build:frontend

# 代码格式化
pnpm format

# 代码检查
pnpm lint

# 清理构建产物
pnpm clean
```

## 📝 开发规范

### Git 提交规范

```
feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建/工具链相关
```

### 代码规范

- Go 代码遵循官方规范，使用 `gofmt` 格式化
- Vue 代码遵循 Vue 3 官方风格指南
- 使用 ESLint 和 Prettier 进行代码检查和格式化

## ⚠️ 注意事项

1. **数据库字符集**：必须使用 `utf8mb4` 以支持完整的 Unicode 字符
2. **密码加密**：使用 BCrypt 算法
3. **并发控制**：库存扣减使用悲观锁防止超卖
4. **事务处理**：入库、出库操作必须在事务中执行
5. **JWT 密钥**：生产环境必须修改 JWT 密钥

## 📖 文档

- [功能需求说明书](docs/功能需求说明书.md) - 详细的功能需求和业务流程
- [项目代码结构说明](docs/项目代码结构说明.md) - 技术架构和代码结构说明
- [Docker 部署指南](docs/Docker部署指南.md) - Docker 容器化部署指南
- [后端 README](apps/backend/README.md) - 后端项目详细说明

## 📄 许可证

[MIT License](LICENSE)

## 🤝 贡献

如有问题或建议，请提交 Issue 或 Pull Request。

---

<p align="center">
  <b>EasyWMS</b> - 让仓库管理更简单
</p>
