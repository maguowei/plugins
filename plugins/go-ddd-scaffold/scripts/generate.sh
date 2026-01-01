#!/bin/bash
#
# Go DDD Scaffold 项目生成脚本
#
# 使用模板系统生成符合 DDD 架构的 Go Web 项目
#
# 用法:
#   bash generate.sh <project_name> <go_module> <database> <include_examples> <plugin_root>
#
# 参数:
#   project_name      - 项目目录名称（例如：my-service）
#   go_module         - Go 模块路径（例如：github.com/myorg/my-service）
#   database          - 数据库类型（mysql 或 sqlite）
#   include_examples  - 是否包含示例（yes 或 no）
#   plugin_root       - 插件根目录路径
#

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 参数验证
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

# 脚本目录
SCRIPT_DIR="$PLUGIN_ROOT/scripts"
TEMPLATE_DIR="$PLUGIN_ROOT/templates"

echo -e "${GREEN}=== Go DDD Scaffold 项目生成器 ===${NC}"
echo ""
echo "项目名称: $PROJECT_NAME"
echo "Go 模块: $GO_MODULE"
echo "数据库: $DATABASE"
echo "包含示例: $INCLUDE_EXAMPLES"
echo ""

# 验证 Go 安装
echo -e "${BLUE}[验证] 检查 Go 安装...${NC}"
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go 未安装，请先安装 Go 1.21+${NC}"
    exit 1
fi
GO_VERSION=$(go version)
echo -e "${GREEN}✓ $GO_VERSION${NC}"

# 验证 Python3 和依赖
echo -e "${BLUE}[验证] 检查 Python3 和依赖...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python3 未安装${NC}"
    exit 1
fi

if ! python3 -c "import jinja2, yaml" 2>/dev/null; then
    echo -e "${YELLOW}⚠ Jinja2 或 PyYAML 未安装${NC}"
    echo "请运行: pip3 install -r $SCRIPT_DIR/requirements.txt"
    exit 1
fi
echo -e "${GREEN}✓ Python3 和依赖已安装${NC}"

# 检查项目目录
echo -e "${BLUE}[验证] 检查项目目录...${NC}"
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}✗ 目录已存在: $PROJECT_NAME${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 目录可用${NC}"
echo ""

# 创建项目目录结构
echo -e "${BLUE}[准备] 创建项目目录结构...${NC}"
mkdir -p "$PROJECT_NAME"/{cmd/{server,migrate},internal/{app/{domain,application,infrastructure,interface},ent/schema},api,configs,test/integration,docs,scripts,deployments/{docker,k8s}}
echo -e "${GREEN}✓ 目录结构创建完成${NC}"
echo ""

# 辅助函数：调用 render.py
render_batch() {
    local batch_name=$1
    local manifest=$2

    python3 "$SCRIPT_DIR/render.py" \
        --template-dir "$TEMPLATE_DIR" \
        --manifest "$manifest" \
        --output-dir "$PROJECT_NAME" \
        --var project_name="$PROJECT_NAME" \
        --var go_module="$GO_MODULE" \
        --var database="$DATABASE" \
        --var include_examples="$INCLUDE_EXAMPLES"
}

# 批次 1: 基础结构
echo -e "${BLUE}[1/8] 生成基础结构...${NC}"
render_batch "基础结构" "base/_manifest.yaml"
echo ""

# 初始化 Go 模块
echo -e "${BLUE}[1/8] 初始化 Go 模块...${NC}"
cd "$PROJECT_NAME" && go mod init "$GO_MODULE" && cd ..
echo -e "${GREEN}✓ Go 模块初始化完成${NC}"
echo ""

# 批次 2: 领域层
echo -e "${BLUE}[2/8] 生成领域层...${NC}"
render_batch "领域层" "domain/_manifest.yaml"
echo ""

# 批次 3: 应用层
echo -e "${BLUE}[3/8] 生成应用层...${NC}"
render_batch "应用层" "application/_manifest.yaml"
echo ""

# 批次 4: 基础设施层
echo -e "${BLUE}[4/8] 生成基础设施层...${NC}"
render_batch "基础设施层" "infrastructure/_manifest.yaml"
echo ""

# 批次 5: 接口层
echo -e "${BLUE}[5/8] 生成接口层...${NC}"
render_batch "接口层" "interface/_manifest.yaml"
echo ""

# 批次 6: Ent Schema & CMD
echo -e "${BLUE}[6/8] 生成 Ent Schema 和 CMD...${NC}"
render_batch "Ent Schema" "ent/_manifest.yaml"
render_batch "CMD" "cmd/_manifest.yaml"
echo ""

# 批次 7: 配置 & Docker
echo -e "${BLUE}[7/8] 生成配置和 Docker 文件...${NC}"
render_batch "配置文件" "configs/_manifest.yaml"
render_batch "Docker" "docker/_manifest.yaml"
echo ""

# 批次 8: 文档、API、脚本
echo -e "${BLUE}[8/8] 生成文档、API 规范和脚本...${NC}"
render_batch "文档" "docs/_manifest.yaml"
render_batch "API 规范" "api/_manifest.yaml"
render_batch "脚本" "scripts/_manifest.yaml"
echo ""

# 设置脚本可执行权限
echo -e "${BLUE}[后处理] 设置脚本权限...${NC}"
if [ -d "$PROJECT_NAME/scripts" ]; then
    chmod +x "$PROJECT_NAME/scripts"/*.sh 2>/dev/null || true
    echo -e "${GREEN}✓ 脚本权限已设置${NC}"
fi
echo ""

# 安装 Go 依赖
echo -e "${BLUE}[依赖] 安装 Go 依赖...${NC}"
cd "$PROJECT_NAME"

echo "  正在安装核心依赖..."
go get -u github.com/gin-gonic/gin
go get -u entgo.io/ent/cmd/ent
go get -u github.com/spf13/viper
go get -u github.com/prometheus/client_golang/prometheus
go get -u github.com/prometheus/client_golang/prometheus/promhttp
go get -u github.com/getsentry/sentry-go
go get -u github.com/google/uuid
go get -u github.com/cloudevents/sdk-go/v2

# 数据库驱动
if [ "$DATABASE" = "mysql" ]; then
    echo "  正在安装 MySQL 驱动..."
    go get -u github.com/go-sql-driver/mysql
else
    echo "  正在安装 SQLite 驱动..."
    go get -u github.com/mattn/go-sqlite3
fi

# 测试依赖
echo "  正在安装测试依赖..."
go get -u github.com/stretchr/testify/assert
go get -u github.com/stretchr/testify/mock

echo -e "${GREEN}✓ 依赖安装完成${NC}"
echo ""

# 生成 Ent 代码
echo -e "${BLUE}[代码生成] 生成 Ent ORM 代码...${NC}"
if [ "$INCLUDE_EXAMPLES" = "yes" ]; then
    go run -mod=mod entgo.io/ent/cmd/ent generate ./internal/ent/schema || {
        echo -e "${YELLOW}⚠ Ent 代码生成失败（可能是 schema 为空）${NC}"
    }
else
    echo -e "${YELLOW}⚠ 跳过 Ent 代码生成（无示例）${NC}"
fi
echo ""

# 整理依赖
echo -e "${BLUE}[依赖] 整理依赖...${NC}"
go mod tidy
echo -e "${GREEN}✓ 依赖整理完成${NC}"
echo ""

# 验证构建
echo -e "${BLUE}[验证] 验证构建...${NC}"
if go build ./cmd/server 2>/dev/null; then
    echo -e "${GREEN}✓ server 构建成功${NC}"
    rm -f server
else
    echo -e "${YELLOW}⚠ server 构建失败${NC}"
fi

if go build ./cmd/migrate 2>/dev/null; then
    echo -e "${GREEN}✓ migrate 构建成功${NC}"
    rm -f migrate
else
    echo -e "${YELLOW}⚠ migrate 构建失败${NC}"
fi
echo ""

cd ..

# 显示项目结构
echo -e "${BLUE}[完成] 项目结构:${NC}"
tree -L 3 -I 'vendor' "$PROJECT_NAME" 2>/dev/null || {
    echo "  (安装 tree 命令可查看结构: brew install tree)"
    ls -la "$PROJECT_NAME"
}
echo ""

# 最终总结
echo -e "${GREEN}=== ✅ 项目生成完成! ===${NC}"
echo ""
echo -e "${YELLOW}下一步操作:${NC}"
echo "  1. cd $PROJECT_NAME"
if [ "$DATABASE" = "mysql" ]; then
    echo "  2. docker-compose up -d db"
    echo "  3. go run ./cmd/migrate"
    echo "  4. go run ./cmd/server"
else
    echo "  2. go run ./cmd/migrate"
    echo "  3. go run ./cmd/server"
fi
echo "  5. curl http://localhost:8080/health"
echo ""
echo -e "${BLUE}查看文档:${NC}"
echo "  - 架构说明: $PROJECT_NAME/docs/architecture.md"
echo "  - 开发指南: $PROJECT_NAME/docs/development.md"
echo "  - 部署文档: $PROJECT_NAME/docs/deployment.md"
echo ""
echo -e "${GREEN}🚀 享受开发吧！${NC}"
