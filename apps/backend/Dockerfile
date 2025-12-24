# =============================================
# EasyWMS Backend Dockerfile
# 多阶段构建，最终镜像基于 alpine
# =============================================

# Stage 1: 构建阶段
FROM golang:1.20-alpine AS builder

# 使用国内 alpine 镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装必要的构建工具
RUN apk add --no-cache git ca-certificates tzdata

# 设置 Go 代理（加速国内下载）
ENV GOPROXY=https://goproxy.cn,direct
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

# 设置工作目录
WORKDIR /build

# 复制 go.mod 和 go.sum，利用 Docker 缓存
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 编译
RUN go build -ldflags="-w -s" -o easywms ./cmd/server

# Stage 2: 运行阶段
FROM alpine:3.19

# 使用国内 alpine 镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装必要的运行时依赖
RUN apk add --no-cache ca-certificates tzdata

# 设置时区为上海
ENV TZ=Asia/Shanghai

# 创建非 root 用户
RUN adduser -D -g '' appuser

# 设置工作目录
WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /build/easywms .

# 创建配置目录和日志目录
RUN mkdir -p /app/config /app/logs && chown -R appuser:appuser /app

# 切换到非 root 用户
USER appuser

# 暴露端口
EXPOSE 9527

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9527/health || exit 1

# 启动命令
CMD ["./easywms"]

