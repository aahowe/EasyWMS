# =============================================
# EasyWMS Frontend Dockerfile
# 多阶段构建：pnpm 构建 + nginx 运行
# =============================================

# Stage 1: 构建阶段
FROM node:20-alpine AS builder

# 设置 npm 镜像加速（国内服务器）
RUN npm config set registry https://registry.npmmirror.com

# 安装 pnpm（使用 npm 安装，避免 corepack 网络问题）
RUN npm install -g pnpm@10.22.0

# 设置工作目录（整个项目根目录）
WORKDIR /build

# 复制 pnpm 相关文件
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./

# 复制 packages 目录（包含依赖的 workspace 包）
COPY packages/ ./packages/

# 复制 internal 目录
COPY internal/ ./internal/

# 复制 apps/frontend 目录
COPY apps/frontend/ ./apps/frontend/

# 安装依赖（使用国内镜像）
RUN pnpm config set registry https://registry.npmmirror.com && \
    pnpm install --frozen-lockfile

# 构建前端
RUN pnpm run build:frontend

# Stage 2: 运行阶段
FROM nginx:alpine

# 使用国内 alpine 镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装时区数据
RUN apk add --no-cache tzdata

# 设置时区
ENV TZ=Asia/Shanghai

# 删除默认 nginx 配置
RUN rm -rf /etc/nginx/conf.d/default.conf

# 复制自定义 nginx 配置
COPY apps/frontend/nginx.conf /etc/nginx/conf.d/default.conf

# 从构建阶段复制构建产物
COPY --from=builder /build/apps/frontend/dist /usr/share/nginx/html

# 创建非 root 用户运行 nginx（可选，增强安全性）
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80 || exit 1

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
