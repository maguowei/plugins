.PHONY: help build run test clean docker migrate lint

# 默认目标
help:
	@echo "{{ .ProjectName }} - Makefile 帮助"
	@echo ""
	@echo "可用命令:"
	@echo "  make build        - 构建二进制文件"
	@echo "  make run          - 运行服务器"
	@echo "  make test         - 运行所有测试"
	@echo "  make test-unit    - 运行单元测试"
	@echo "  make test-int     - 运行集成测试"
	@echo "  make coverage     - 生成测试覆盖率报告"
	@echo "  make migrate      - 运行数据库迁移"
	@echo "  make lint         - 运行代码检查"
	@echo "  make fmt          - 格式化代码"
	@echo "  make clean        - 清理构建产物"
	@echo "  make docker-build - 构建 Docker 镜像"
	@echo "  make docker-up    - 启动 Docker Compose"
	@echo "  make docker-down  - 停止 Docker Compose"

# 构建配置
BINARY_NAME={{ .ProjectName }}
BINARY_SERVER=bin/server
BINARY_MIGRATE=bin/migrate
GO_FILES=$(shell find . -type f -name '*.go' -not -path "./vendor/*")

# 构建二进制文件
build:
	@echo "构建服务器..."
	@mkdir -p bin
	@go build -o $(BINARY_SERVER) ./cmd/server
	@echo "构建迁移工具..."
	@go build -o $(BINARY_MIGRATE) ./cmd/migrate
	@echo "✅ 构建完成"

# 运行服务器
run:
	@echo "启动服务器..."
	@go run ./cmd/server

# 运行所有测试
test:
	@echo "运行所有测试..."
	@go test -v ./...

# 运行单元测试
test-unit:
	@echo "运行单元测试..."
	@go test -v ./internal/app/domain/... ./internal/app/application/...

# 运行集成测试
test-int:
	@echo "运行集成测试..."
	@go test -v ./test/integration/...

# 生成测试覆盖率报告
coverage:
	@echo "生成测试覆盖率报告..."
	@go test -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "✅ 覆盖率报告已生成: coverage.html"

# 运行数据库迁移
migrate:
	@echo "运行数据库迁移..."
	@go run ./cmd/migrate

# 代码检查
lint:
	@echo "运行代码检查..."
	@golangci-lint run ./...

# 格式化代码
fmt:
	@echo "格式化代码..."
	@gofmt -s -w $(GO_FILES)
	@goimports -w $(GO_FILES)

# 安装依赖
deps:
	@echo "安装依赖..."
	@go mod download
	@go mod tidy

# 生成 Ent 代码
ent-generate:
	@echo "生成 Ent 代码..."
	@go generate ./internal/ent

# 清理构建产物
clean:
	@echo "清理构建产物..."
	@rm -rf bin/
	@rm -f coverage.out coverage.html
	@echo "✅ 清理完成"

# Docker 构建
docker-build:
	@echo "构建 Docker 镜像..."
	@docker build -t {{ .ProjectName }}:latest .

# 启动 Docker Compose
docker-up:
	@echo "启动 Docker Compose..."
	@docker-compose up -d

# 停止 Docker Compose
docker-down:
	@echo "停止 Docker Compose..."
	@docker-compose down

# 查看 Docker Compose 日志
docker-logs:
	@docker-compose logs -f

# 开发模式 (使用 air 热重载)
dev:
	@echo "启动开发模式..."
	@air

# 安装开发工具
install-tools:
	@echo "安装开发工具..."
	@go install github.com/cosmtrek/air@latest
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@go install golang.org/x/tools/cmd/goimports@latest
	@echo "✅ 开发工具安装完成"
