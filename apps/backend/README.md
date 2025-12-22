# EasyWMS Backend (Go)

简易仓库管理系统后端服务

## 技术栈

- Go 1.20+
- Gin Web Framework
- GORM (MySQL)
- JWT Authentication
- Viper (Configuration)

## 项目结构

```
apps/backend/
├── cmd/
│   └── server/
│       └── main.go              # 应用入口
├── internal/
│   ├── config/                  # 配置管理
│   │   └── config.go
│   ├── model/                   # 数据模型（GORM实体）
│   │   ├── user.go
│   │   ├── product.go
│   │   ├── supplier.go
│   │   ├── department.go
│   │   ├── procurement.go
│   │   ├── inbound.go
│   │   ├── outbound.go
│   │   ├── stock_log.go
│   │   └── inventory_check.go
│   ├── dao/                     # 数据访问层
│   │   ├── user/
│   │   ├── basic/
│   │   ├── procure/
│   │   ├── stock/
│   │   └── inventory/
│   ├── service/                 # 业务逻辑层
│   │   ├── basic/
│   │   ├── procure/
│   │   ├── stock/
│   │   └── inventory/
│   ├── controller/              # 控制器层
│   │   ├── user_controller.go
│   │   ├── product_controller.go
│   │   ├── procurement_controller.go
│   │   ├── inbound_controller.go
│   │   ├── outbound_controller.go
│   │   └── inventory_controller.go
│   ├── middleware/              # 中间件
│   │   ├── auth.go
│   │   ├── cors.go
│   │   └── logger.go
│   ├── router/                  # 路由配置
│   │   └── router.go
│   └── utils/                   # 工具函数
│       ├── response.go
│       ├── jwt.go
│       └── password.go
├── config/                      # 配置文件
│   ├── config.yaml
│   └── config.example.yaml
└── README.md
```

## 快速开始

### 1. 安装依赖

```bash
cd apps/backend
go mod download
```

### 2. 配置数据库

复制配置文件并修改数据库连接信息：

```bash
cp config/config.example.yaml config/config.yaml
```

编辑 `config/config.yaml`，配置MySQL连接信息。

### 3. 初始化数据库

执行数据库脚本：

```bash
mysql -u root -p < ../../db/schema.sql
mysql -u root -p < ../../db/data.sql
```

### 4. 运行服务

```bash
go run cmd/server/main.go
```

服务将在 `http://localhost:8080` 启动。

## API文档

### 认证接口

- `POST /api/auth/login` - 用户登录
- `POST /api/auth/logout` - 用户登出

### 基础数据接口

- `GET /api/products` - 获取物资列表
- `POST /api/products` - 创建物资
- `PUT /api/products/:id` - 更新物资
- `DELETE /api/products/:id` - 删除物资

### 采购管理接口

- `GET /api/procurements` - 获取采购单列表
- `POST /api/procurements` - 创建采购申请
- `PUT /api/procurements/:id/approve` - 审批采购申请
- `POST /api/procurements/:id/order` - 生成采购订单

### 入库管理接口

- `GET /api/inbounds` - 获取入库单列表
- `POST /api/inbounds` - 创建入库单
- `PUT /api/inbounds/:id/confirm` - 确认入库

### 出库管理接口

- `GET /api/outbounds` - 获取出库单列表
- `POST /api/outbounds` - 创建领用申请
- `PUT /api/outbounds/:id/approve` - 审批领用申请
- `PUT /api/outbounds/:id/execute` - 执行出库

### 统计与盘点接口

- `GET /api/inventory/stock` - 查询库存
- `GET /api/inventory/reports` - 统计报表
- `POST /api/inventory/checks` - 创建盘点任务
- `PUT /api/inventory/checks/:id/adjust` - 盘点调整

## 开发规范

### 代码风格

- 遵循 Go 官方代码规范
- 使用 `gofmt` 格式化代码
- 使用 `golint` 进行代码检查

### 提交规范

- feat: 新功能
- fix: 修复bug
- docs: 文档更新
- refactor: 代码重构
- test: 测试相关

## 许可证

MIT License
