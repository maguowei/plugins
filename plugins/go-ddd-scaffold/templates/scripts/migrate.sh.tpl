#!/bin/bash

# {{ .Project.Name }} 数据库迁移脚本
# 用于运行数据库迁移

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认配置
CONFIG_FILE="${CONFIG_FILE:-./configs/config.yaml}"
MIGRATE_BIN="${MIGRATE_BIN:-./bin/migrate}"

# 检查是否编译了 migrate 二进制文件
if [ ! -f "$MIGRATE_BIN" ]; then
  echo -e "${YELLOW}未找到迁移工具，正在编译...${NC}"
  go build -o "$MIGRATE_BIN" ./cmd/migrate
  if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 迁移工具编译失败${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ 迁移工具编译成功${NC}"
fi

# 显示帮助信息
show_help() {
  echo "{{ .Project.Name }} 数据库迁移脚本"
  echo ""
  echo "用法:"
  echo "  $0 [选项]"
  echo ""
  echo "选项:"
  echo "  -h, --help       显示帮助信息"
  echo "  -d, --drop       删除所有表后重新创建"
  echo "  -D, --debug      启用调试模式"
  echo "  -c, --config     指定配置文件路径（默认: $CONFIG_FILE）"
  echo ""
  echo "示例:"
  echo "  $0                   # 运行迁移"
  echo "  $0 --drop            # 删除所有表并重新创建"
  echo "  $0 --debug           # 启用调试模式"
  echo "  $0 -c config.prod.yaml  # 使用指定的配置文件"
  echo ""
}

# 解析命令行参数
DROP_FLAG=""
DEBUG_FLAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -d|--drop)
      DROP_FLAG="-drop"
      shift
      ;;
    -D|--debug)
      DEBUG_FLAG="-debug"
      shift
      ;;
    -c|--config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}未知选项: $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${RED}✗ 配置文件不存在: $CONFIG_FILE${NC}"
  exit 1
fi

echo -e "${GREEN}=== {{ .Project.Name }} 数据库迁移 ===${NC}"
echo "配置文件: $CONFIG_FILE"
echo ""

# 设置环境变量（如果配置文件路径不是默认值）
if [ "$CONFIG_FILE" != "./configs/config.yaml" ]; then
  export CONFIG_PATH="$CONFIG_FILE"
fi

# 运行迁移
echo -e "${YELLOW}正在运行数据库迁移...${NC}"

if [ -n "$DROP_FLAG" ]; then
  echo -e "${RED}警告: 将删除所有表！${NC}"
  read -p "是否继续？(y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
  fi
fi

# 执行迁移
"$MIGRATE_BIN" $DROP_FLAG $DEBUG_FLAG

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ 数据库迁移成功${NC}"
else
  echo ""
  echo -e "${RED}✗ 数据库迁移失败${NC}"
  exit 1
fi

{{- if eq .Database.Driver "mysql" }}
# MySQL 特定操作
echo ""
echo -e "${YELLOW}MySQL 数据库信息:${NC}"

# 从配置文件或环境变量获取数据库连接信息
DB_DSN="${APP_DATABASE_DSN:-}"

if [ -z "$DB_DSN" ]; then
  echo "无法获取数据库连接信息"
else
  echo "DSN: $DB_DSN"
fi
{{- else if eq .Database.Driver "sqlite3" }}
# SQLite 特定操作
echo ""
echo -e "${YELLOW}SQLite 数据库信息:${NC}"

# 从配置文件或环境变量获取数据库文件路径
DB_FILE="${APP_DATABASE_DSN:-./{{ .Project.Name }}.db}"
DB_FILE=$(echo $DB_FILE | sed 's/file://g' | cut -d'?' -f1)

if [ -f "$DB_FILE" ]; then
  echo "数据库文件: $DB_FILE"
  echo "文件大小: $(du -h "$DB_FILE" | cut -f1)"
else
  echo "数据库文件不存在: $DB_FILE"
fi
{{- end }}

echo ""
echo -e "${GREEN}=== 迁移完成 ===${NC}"
