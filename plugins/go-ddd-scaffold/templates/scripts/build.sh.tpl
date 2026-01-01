#!/bin/bash

# {{ .Project.Name }} 构建脚本
# 用于编译所有二进制文件

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="{{ .Project.Name }}"
VERSION="${VERSION:-dev}"
BUILD_TIME=$(date -u '+%Y-%m-%d %H:%M:%S')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# 输出目录
OUTPUT_DIR="${OUTPUT_DIR:-./bin}"

# Go 编译参数
CGO_ENABLED="${CGO_ENABLED:-0}"
GOOS="${GOOS:-linux}"
GOARCH="${GOARCH:-amd64}"

# ldflags 编译参数（注入版本信息）
LDFLAGS="-w -s"
LDFLAGS="$LDFLAGS -X 'main.Version=$VERSION'"
LDFLAGS="$LDFLAGS -X 'main.BuildTime=$BUILD_TIME'"
LDFLAGS="$LDFLAGS -X 'main.GitCommit=$GIT_COMMIT'"

echo -e "${GREEN}=== {{ .Project.Name }} 构建脚本 ===${NC}"
echo "版本: $VERSION"
echo "构建时间: $BUILD_TIME"
echo "Git 提交: $GIT_COMMIT"
echo "目标平台: $GOOS/$GOARCH"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 构建服务器
echo -e "${YELLOW}正在构建服务器...${NC}"
CGO_ENABLED=$CGO_ENABLED GOOS=$GOOS GOARCH=$GOARCH \
  go build -ldflags="$LDFLAGS" \
  -o "$OUTPUT_DIR/server" \
  ./cmd/server

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ 服务器构建成功: $OUTPUT_DIR/server${NC}"
else
  echo -e "${RED}✗ 服务器构建失败${NC}"
  exit 1
fi

# 构建迁移工具
echo -e "${YELLOW}正在构建迁移工具...${NC}"
CGO_ENABLED=$CGO_ENABLED GOOS=$GOOS GOARCH=$GOARCH \
  go build -ldflags="$LDFLAGS" \
  -o "$OUTPUT_DIR/migrate" \
  ./cmd/migrate

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ 迁移工具构建成功: $OUTPUT_DIR/migrate${NC}"
else
  echo -e "${RED}✗ 迁移工具构建失败${NC}"
  exit 1
fi

# 显示构建结果
echo ""
echo -e "${GREEN}=== 构建完成 ===${NC}"
echo "输出目录: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"

# 显示使用说明
echo ""
echo -e "${YELLOW}使用说明:${NC}"
echo "  启动服务器: $OUTPUT_DIR/server"
echo "  运行迁移:   $OUTPUT_DIR/migrate"
echo ""

# 构建多平台版本（可选）
if [ "$MULTI_PLATFORM" = "true" ]; then
  echo -e "${YELLOW}正在构建多平台版本...${NC}"

  platforms=("linux/amd64" "linux/arm64" "darwin/amd64" "darwin/arm64" "windows/amd64")

  for platform in "${platforms[@]}"; do
    platform_split=(${platform//\// })
    GOOS=${platform_split[0]}
    GOARCH=${platform_split[1]}
    output_name="$OUTPUT_DIR/${PROJECT_NAME}-${GOOS}-${GOARCH}"

    if [ $GOOS = "windows" ]; then
      output_name+='.exe'
    fi

    echo "构建 $GOOS/$GOARCH..."
    CGO_ENABLED=0 GOOS=$GOOS GOARCH=$GOARCH \
      go build -ldflags="$LDFLAGS" \
      -o "$output_name" \
      ./cmd/server

    if [ $? -ne 0 ]; then
      echo -e "${RED}✗ $GOOS/$GOARCH 构建失败${NC}"
      continue
    fi

    echo -e "${GREEN}✓ $GOOS/$GOARCH 构建成功${NC}"
  done

  echo -e "${GREEN}=== 多平台构建完成 ===${NC}"
  ls -lh "$OUTPUT_DIR"
fi
