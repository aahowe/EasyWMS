#!/bin/bash
# =============================================
# EasyWMS Docker 部署脚本
# =============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker 未安装，请先安装 Docker"
    fi
    
    if ! command -v docker compose &> /dev/null; then
        error "Docker Compose 未安装，请先安装 Docker Compose"
    fi
    
    success "Docker 环境检查通过"
}

# 检查环境变量文件（可选，默认配置已可直接使用）
check_env() {
    if [ ! -f ".env" ]; then
        info ".env 文件不存在，使用默认配置"
        info "如需自定义配置，可复制 env.example 为 .env 并修改"
    else
        success "检测到 .env 文件，将使用自定义配置"
    fi
}

# 构建镜像
build() {
    info "开始构建 Docker 镜像..."
    docker compose build --no-cache
    success "镜像构建完成"
}

# 启动服务
start() {
    info "启动服务..."
    docker compose up -d
    success "服务启动完成"
}

# 停止服务
stop() {
    info "停止服务..."
    docker compose down
    success "服务已停止"
}

# 重启服务
restart() {
    info "重启服务..."
    docker compose restart
    success "服务已重启"
}

# 查看状态
status() {
    info "服务状态："
    docker compose ps
}

# 查看日志
logs() {
    docker compose logs -f
}

# 清理
clean() {
    warn "此操作将删除所有容器和数据卷！"
    read -p "确认删除？(y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        docker compose down -v
        docker image prune -f
        success "清理完成"
    else
        info "操作已取消"
    fi
}

# 备份数据库
backup() {
    BACKUP_DIR="./backups"
    mkdir -p "$BACKUP_DIR"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${BACKUP_DIR}/easywms_${TIMESTAMP}.sql"
    
    info "开始备份数据库..."
    
    # 从 .env 文件读取密码
    source .env
    
    docker compose exec -T mysql mysqldump -u "${MYSQL_USER:-easywms}" -p"${MYSQL_PASSWORD:-easywms_123}" "${MYSQL_DATABASE:-easywms}" > "$BACKUP_FILE"
    
    if [ -f "$BACKUP_FILE" ]; then
        success "备份完成: $BACKUP_FILE"
    else
        error "备份失败"
    fi
}

# 部署（构建并启动）
deploy() {
    check_docker
    check_env
    build
    start
    
    info "等待服务启动..."
    sleep 10
    
    status
    
    echo ""
    success "🎉 EasyWMS 部署完成！"
    echo ""
    echo -e "  前端访问地址: ${GREEN}http://localhost:${FRONTEND_PORT:-9528}${NC}"
    echo -e "  后端 API 地址: ${GREEN}http://localhost:${BACKEND_PORT:-9527}/api${NC}"
    echo ""
    echo "  默认管理员账号: admin"
    echo "  默认管理员密码: admin123"
    echo ""
}

# 帮助信息
help() {
    echo "EasyWMS Docker 部署脚本"
    echo ""
    echo "用法: $0 <command>"
    echo ""
    echo "命令:"
    echo "  deploy    构建并启动所有服务（首次部署推荐）"
    echo "  build     构建 Docker 镜像"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  status    查看服务状态"
    echo "  logs      查看服务日志"
    echo "  backup    备份数据库"
    echo "  clean     清理容器和数据（危险操作）"
    echo "  help      显示帮助信息"
    echo ""
}

# 主入口
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    build)
        build
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    backup)
        backup
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        help
        ;;
    *)
        error "未知命令: $1"
        ;;
esac

