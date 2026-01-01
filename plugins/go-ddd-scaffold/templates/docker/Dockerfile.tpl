# ============================================
# Builder Stage - 编译阶段
# ============================================
FROM golang:{{ .Go.Version }}-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache git make gcc musl-dev

# 设置工作目录
WORKDIR /build

# 复制 go.mod 和 go.sum（利用 Docker 缓存）
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 编译应用
# -ldflags="-w -s" 去除调试信息，减小二进制文件大小
# CGO_ENABLED=0 编译静态链接的二进制文件
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" \
    -o /build/bin/server \
    ./cmd/server

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" \
    -o /build/bin/migrate \
    ./cmd/migrate

# ============================================
# Runtime Stage - 运行阶段
# ============================================
FROM alpine:latest

# 安装运行时依赖
# ca-certificates: 支持 HTTPS 请求
# tzdata: 时区数据
RUN apk --no-cache add ca-certificates tzdata

# 设置时区
ENV TZ=Asia/Shanghai

# 创建非 root 用户
RUN addgroup -g 1000 app && \
    adduser -D -u 1000 -G app app

# 设置工作目录
WORKDIR /app

# 从 builder 阶段复制编译好的二进制文件
COPY --from=builder /build/bin/server /app/server
COPY --from=builder /build/bin/migrate /app/migrate

# 复制配置文件
COPY --from=builder /build/configs /app/configs

# 更改文件所有者
RUN chown -R app:app /app

# 切换到非 root 用户
USER app

# 暴露端口
EXPOSE {{ .Server.Port }}

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:{{ .Server.Port }}/health || exit 1

# 启动应用
CMD ["/app/server"]
