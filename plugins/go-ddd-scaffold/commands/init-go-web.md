---
name: init-go-web
description: 初始化 Go DDD Web 项目（Gin + Ent + Viper + slog + Prometheus + Sentry）
argument-hint: "[项目名称]"
allowed-tools:
  - Bash
  - AskUserQuestion
---

# 初始化 Go DDD Web 项目

## 执行流程

### 第 1 步: 收集项目信息

使用 AskUserQuestion 逐步收集:

1. **项目名称**（必需）: 小写字母、数字、连字符
2. **Go module 路径**（必需）: 如 `github.com/myorg/my-service`
3. **数据库类型**: mysql（默认）或 sqlite
4. **是否包含示例代码**: yes（默认）或 no

### 第 2 步: 调用生成脚本

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate.sh \
  "<project_name>" \
  "<go_module>" \
  "<database>" \
  "<include_examples>" \
  "${CLAUDE_PLUGIN_ROOT}"
```

### 第 3 步: 显示后续步骤

```
cd <project-name>
docker-compose -f docker/docker-compose.yaml up -d  # MySQL
make migrate
make run
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/users
```

## 前置依赖

- Go 1.22+

## 错误处理

- 目录已存在: 提示选择其他名称
- Go 未安装: 提示安装 Go
- 构建失败: 显示错误信息
