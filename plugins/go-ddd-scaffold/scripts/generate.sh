#!/bin/bash
# Go DDD Scaffold 项目生成脚本
#
# 用法: bash generate.sh <project_name> <go_module> <database> <include_examples> <plugin_root>

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$#" -ne 5 ]; then
    echo -e "${RED}错误: 参数数量不正确${NC}"
    echo "用法: $0 <project_name> <go_module> <database> <include_examples> <plugin_root>"
    exit 1
fi

PROJECT_NAME=$1
GO_MODULE=$2
DATABASE=$3
INCLUDE_EXAMPLES=$4
PLUGIN_ROOT=$5

TEMPLATE_DIR="$PLUGIN_ROOT/templates"
TOOL_DIR="$PLUGIN_ROOT/tools/scaffold"

echo -e "${GREEN}=== Go DDD Scaffold ===${NC}"
echo "项目: $PROJECT_NAME | 模块: $GO_MODULE | 数据库: $DATABASE | 示例: $INCLUDE_EXAMPLES"
echo ""

# 验证 Go
echo -e "${BLUE}[1/6] 验证环境...${NC}"
if ! command -v go &> /dev/null; then
    echo -e "${RED}Go 未安装${NC}"
    exit 1
fi
echo -e "${GREEN}$(go version)${NC}"

# 检查目录
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}目录已存在: $PROJECT_NAME${NC}"
    exit 1
fi

# 构建 scaffold CLI
echo -e "${BLUE}[2/6] 构建渲染工具...${NC}"
SCAFFOLD_BIN=$(mktemp)
(cd "$TOOL_DIR" && go build -o "$SCAFFOLD_BIN" .)
echo -e "${GREEN}scaffold CLI 构建完成${NC}"

# 生成变量文件
echo -e "${BLUE}[3/6] 生成项目文件...${NC}"
VARS_FILE=$(mktemp)
INCLUDE_BOOL="true"
if [ "$INCLUDE_EXAMPLES" = "no" ]; then
    INCLUDE_BOOL="false"
fi

cat > "$VARS_FILE" << EOF
project_name: "$PROJECT_NAME"
go_module: "$GO_MODULE"
database: "$DATABASE"
include_examples: $INCLUDE_BOOL
go_version: "1.24"
entity_name: "User"
entity_name_lower: "user"
entity_id_type: "uuid.UUID"
EOF

# 渲染模板
"$SCAFFOLD_BIN" -vars "$VARS_FILE" -templates "$TEMPLATE_DIR" -output "$PROJECT_NAME"
echo -e "${GREEN}文件生成完成${NC}"

# 初始化 Go 模块 + Ent 代码生成
echo -e "${BLUE}[4/6] 初始化 Go 模块...${NC}"
cd "$PROJECT_NAME"

echo -e "${BLUE}[5/6] 生成 Ent 代码...${NC}"
if [ "$INCLUDE_EXAMPLES" = "yes" ]; then
    # infrastructure/repository 和 cmd 引用了尚未生成的 ent/user 包
    # 临时移开这些文件，让 go mod tidy 和 ent generate 能成功
    mv internal/app/infrastructure/repository/user.go internal/app/infrastructure/repository/user.go.bak
    mv internal/app/interface/http/router.go internal/app/interface/http/router.go.bak
    mv cmd/server/main.go cmd/server/main.go.bak
    mv cmd/migrate/main.go cmd/migrate/main.go.bak

    go mod tidy
    go generate ./internal/ent/...
    go mod tidy

    # 恢复文件
    mv internal/app/infrastructure/repository/user.go.bak internal/app/infrastructure/repository/user.go
    mv internal/app/interface/http/router.go.bak internal/app/interface/http/router.go
    mv cmd/server/main.go.bak cmd/server/main.go
    mv cmd/migrate/main.go.bak cmd/migrate/main.go

    go mod tidy
    echo -e "${GREEN}Ent 代码生成完成${NC}"
else
    # 无示例模式：删除引用了 user/handler 的文件（scaffold 已跳过 user 文件，
    # 但 router.go 等仍引用了空的 handler 包）
    rm -f internal/app/interface/http/router.go
    rm -rf internal/app/interface/http/handler
    rm -rf internal/app/interface/http/dto
    rm -rf internal/ent/schema
    rm -f internal/ent/generate.go
    go mod tidy
    echo "跳过 Ent（无示例）"
fi
echo -e "${GREEN}模块初始化完成${NC}"

# 验证
echo -e "${BLUE}[6/6] 验证构建...${NC}"
go build ./...
echo -e "${GREEN}构建验证通过${NC}"
cd ..

# 清理临时文件
rm -f "$SCAFFOLD_BIN" "$VARS_FILE"

echo ""
echo -e "${GREEN}=== 项目生成完成 ===${NC}"
echo ""
echo "后续步骤:"
echo "  cd $PROJECT_NAME"
if [ "$DATABASE" = "mysql" ]; then
    echo "  docker-compose -f docker/docker-compose.yaml up -d"
fi
echo "  make migrate"
echo "  make run"
echo "  curl http://localhost:8080/health"
