#!/bin/bash

# {{ .Project.Name }} 代码检查脚本
# 用于运行代码质量检查

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计变量
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo -e "${GREEN}=== {{ .Project.Name }} 代码质量检查 ===${NC}"
echo ""

# 运行检查并统计结果
run_check() {
  local name="$1"
  shift
  local cmd="$@"

  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

  echo -e "${BLUE}[$TOTAL_CHECKS] 运行 $name...${NC}"

  if eval "$cmd"; then
    echo -e "${GREEN}✓ $name 通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo ""
    return 0
  else
    echo -e "${RED}✗ $name 失败${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo ""
    return 1
  fi
}

# 1. 运行 go fmt
run_check "代码格式检查 (go fmt)" \
  "test -z \"\$(gofmt -l .)\""

# 2. 运行 go vet
run_check "代码静态分析 (go vet)" \
  "go vet ./..."

# 3. 检查 go.mod 是否整洁
run_check "依赖检查 (go mod tidy)" \
  "go mod tidy && git diff --exit-code go.mod go.sum"

# 4. 运行单元测试
run_check "单元测试 (go test)" \
  "go test -short -race -coverprofile=coverage.out ./..."

# 5. 检查测试覆盖率
if [ -f coverage.out ]; then
  COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//')
  echo -e "${BLUE}[5] 测试覆盖率检查${NC}"

  if (( $(echo "$COVERAGE >= 50" | bc -l) )); then
    echo -e "${GREEN}✓ 测试覆盖率: $COVERAGE% (>= 50%)${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
  else
    echo -e "${YELLOW}⚠ 测试覆盖率: $COVERAGE% (< 50%)${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
  fi

  echo ""
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
fi

# 6. golangci-lint（如果已安装）
if command -v golangci-lint &> /dev/null; then
  run_check "代码质量检查 (golangci-lint)" \
    "golangci-lint run"
else
  echo -e "${YELLOW}⚠ golangci-lint 未安装，跳过${NC}"
  echo "安装方法: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
  echo ""
fi

# 7. 检查是否有 TODO 或 FIXME
echo -e "${BLUE}[$((TOTAL_CHECKS + 1))] 检查 TODO/FIXME${NC}"
TODO_COUNT=$(grep -r "TODO\|FIXME" --include="*.go" . | wc -l | tr -d ' ')

if [ "$TODO_COUNT" -gt 0 ]; then
  echo -e "${YELLOW}⚠ 发现 $TODO_COUNT 个 TODO/FIXME${NC}"
  grep -rn "TODO\|FIXME" --include="*.go" . | head -n 10
else
  echo -e "${GREEN}✓ 没有发现 TODO/FIXME${NC}"
fi

echo ""
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# 8. 检查代码行数
echo -e "${BLUE}[$((TOTAL_CHECKS + 1))] 代码统计${NC}"
echo "Go 代码行数:"
find . -name "*.go" -not -path "./vendor/*" -not -path "./internal/ent/*" | xargs wc -l | tail -n 1
echo ""
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# 9. 检查循环复杂度（如果安装了 gocyclo）
if command -v gocyclo &> /dev/null; then
  echo -e "${BLUE}[$((TOTAL_CHECKS + 1))] 循环复杂度检查 (gocyclo)${NC}"

  COMPLEX_FUNCS=$(gocyclo -over 15 . | wc -l | tr -d ' ')

  if [ "$COMPLEX_FUNCS" -eq 0 ]; then
    echo -e "${GREEN}✓ 没有发现高复杂度函数 (复杂度 > 15)${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
  else
    echo -e "${YELLOW}⚠ 发现 $COMPLEX_FUNCS 个高复杂度函数:${NC}"
    gocyclo -over 15 .
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi

  echo ""
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
else
  echo -e "${YELLOW}⚠ gocyclo 未安装，跳过循环复杂度检查${NC}"
  echo "安装方法: go install github.com/fzipp/gocyclo/cmd/gocyclo@latest"
  echo ""
fi

# 10. 安全检查（如果安装了 gosec）
if command -v gosec &> /dev/null; then
  run_check "安全检查 (gosec)" \
    "gosec -quiet ./..."
else
  echo -e "${YELLOW}⚠ gosec 未安装，跳过安全检查${NC}"
  echo "安装方法: go install github.com/securego/gosec/v2/cmd/gosec@latest"
  echo ""
fi

# 显示统计结果
echo -e "${GREEN}=== 检查完成 ===${NC}"
echo "总计: $TOTAL_CHECKS 项检查"
echo -e "${GREEN}通过: $PASSED_CHECKS${NC}"

if [ $FAILED_CHECKS -gt 0 ]; then
  echo -e "${RED}失败: $FAILED_CHECKS${NC}"
  echo ""
  echo -e "${RED}代码质量检查未完全通过，请修复上述问题${NC}"
  exit 1
else
  echo -e "${RED}失败: $FAILED_CHECKS${NC}"
  echo ""
  echo -e "${GREEN}所有代码质量检查通过！${NC}"
  exit 0
fi
