# EasyWMS Docker 部署指南

本文档介绍如何使用 Docker 和 Docker Compose 部署 EasyWMS 仓库管理系统。

## 📋 前提条件

- Docker 20.10+
- Docker Compose 2.0+
- 服务器已安装 MySQL 8.0，并创建好 `easywms` 数据库和用户
- 至少 1GB 可用内存

## 🚀 快速部署

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd EasyWMS
```

### 2. 启动服务（零配置）

默认配置已可直接使用，无需额外配置：

```bash
# 构建并启动所有服务
docker compose up -d --build

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f
```

### 3. 访问系统

- 前端地址：`http://your-server-ip:9528`
- 后端 API：`http://your-server-ip:9527/api`

默认管理员账号：
- 用户名：`admin`
- 密码：`admin123`

### 4. 自定义配置（可选）

如需自定义端口或密码，可复制环境变量示例文件：

```bash
cp env.example .env
# 编辑 .env 文件修改配置
```

## 📁 目录结构

```
EasyWMS/
├── docker-compose.yml      # Docker Compose 编排文件（仅前后端）
├── env.example             # 环境变量示例
├── deploy.sh               # 一键部署脚本
├── .dockerignore           # Docker 构建忽略文件
├── apps/
│   ├── backend/
│   │   ├── Dockerfile      # 后端 Dockerfile
│   │   └── config/
│   │       └── config.yaml # 后端配置（含数据库连接）
│   └── frontend/
│       ├── Dockerfile      # 前端 Dockerfile
│       └── nginx.conf      # Nginx 配置
└── db/
    ├── schema.sql          # 数据库结构（需手动导入）
    └── data.sql            # 初始数据（需手动导入）
```

## ⚙️ 配置说明

### 数据库配置

数据库连接配置在 `apps/backend/config/config.yaml` 中：

```yaml
database:
  host: host.docker.internal  # 连接宿主机 MySQL
  port: 3306
  username: easywms
  password: 111111
  dbname: easywms
```

> `host.docker.internal` 是 Docker 提供的特殊域名，用于从容器内访问宿主机服务。

### 环境变量（可选）

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `BACKEND_PORT` | 后端 API 端口 | `9527` |
| `FRONTEND_PORT` | 前端访问端口 | `9528` |

### 数据持久化

Docker Compose 使用命名卷进行日志持久化：

- `backend_logs`：后端日志目录

查看卷信息：

```bash
docker volume ls
docker volume inspect easywms_backend_logs
```

## 🔧 常用命令

### 服务管理

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 重启单个服务
docker compose restart backend

# 查看服务状态
docker compose ps

# 查看实时日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f backend
```

### 镜像管理

```bash
# 重新构建镜像
docker compose build

# 强制重新构建（不使用缓存）
docker compose build --no-cache

# 拉取最新基础镜像并重建
docker compose build --pull
```

### 数据库管理

数据库在服务器本地，使用本地 MySQL 客户端管理：

```bash
# 连接数据库
mysql -u easywms -p easywms

# 导出数据库
mysqldump -u easywms -p easywms > backup.sql

# 导入数据库
mysql -u easywms -p easywms < backup.sql
```

### 清理

```bash
# 停止并删除容器、网络
docker compose down

# 停止并删除容器、网络、卷（⚠️ 会删除数据）
docker compose down -v

# 清理未使用的镜像
docker image prune -f
```

## 🔒 生产环境建议

### 1. 使用 HTTPS

建议在前端使用 HTTPS，可以通过以下方式实现：

**方式一：使用反向代理（推荐）**

在服务器上配置 Nginx 或 Traefik 作为反向代理，处理 SSL 终止。

**方式二：修改前端 Nginx 配置**

1. 获取 SSL 证书（Let's Encrypt 或商业证书）
2. 修改 `apps/frontend/nginx.conf`
3. 重新构建前端镜像

### 2. 安全加固

```bash
# 修改默认密码
MYSQL_ROOT_PASSWORD=<强密码>
MYSQL_PASSWORD=<强密码>
JWT_SECRET=<至少32字符的随机字符串>
```

### 3. 防火墙配置

```bash
# 只开放必要端口
sudo ufw allow 9528/tcp  # 前端
sudo ufw allow 443/tcp   # HTTPS（如果配置）
# 不要对外开放 MySQL 端口 3306 和后端 9527
```

### 4. 定期备份

```bash
# 创建备份脚本
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker compose exec -T mysql mysqldump -u easywms -p${MYSQL_PASSWORD} easywms > backup_${DATE}.sql
```

### 5. 监控和日志

```bash
# 查看容器资源使用
docker stats

# 配置日志轮转（在 docker-compose.yml 中添加）
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## 🐛 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker compose logs backend
docker compose logs mysql

# 检查容器状态
docker compose ps -a
```

### 数据库连接失败

1. 检查服务器 MySQL 是否正常运行：`systemctl status mysql`
2. 确认 MySQL 允许本地连接
3. 检查 `apps/backend/config/config.yaml` 中的数据库配置是否正确
4. 确认 `easywms` 用户有访问权限

```bash
# 测试数据库连接
mysql -u easywms -p111111 -e "SELECT 1"
```

### 前端无法访问后端

1. 检查后端容器是否正常运行
2. 确认 nginx.conf 中的 proxy_pass 配置正确
3. 检查网络连接

```bash
# 从前端容器测试后端连接
docker compose exec frontend wget -qO- http://backend:8080/health
```

## 📞 技术支持

如有问题，请提交 Issue 或联系技术支持。

