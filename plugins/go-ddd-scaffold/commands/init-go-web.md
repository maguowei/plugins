---
name: init-go-web
description: 初始化一个新的 Go Web 项目,使用 DDD 架构和标准技术栈 (Gin + Ent + Viper + slog + Prometheus + Sentry)
argument-hint: "[--name <project-name>] [--db mysql|sqlite] [--module <go-module-path>]"
allowed-tools:
  - Bash
  - AskUserQuestion
---

# 初始化 Go DDD Web 项目

使用脚本驱动的方式创建一个完整的 Go Web 项目,包含 DDD 四层架构、完整的 CRUD 示例、Docker 配置和文档。

## 执行流程

### 第 1 步: 收集项目信息

使用 AskUserQuestion 工具收集以下信息:

1. **项目名称** (必需):
   - 提示: "项目名称 (如: my-service)"
   - 验证: 只包含小写字母、数字和连字符
   - 用于创建项目目录

2. **Go Module 路径** (必需):
   - 提示: "Go module 路径 (如: github.com/myorg/my-service)"
   - 用于 `go mod init`

3. **数据库类型** (必需):
   - 选项: `mysql` 或 `sqlite`
   - 默认: `mysql`
   - 影响 Ent schema 和 docker-compose 配置

4. **是否包含完整示例** (必需):
   - 选项: `yes` 或 `no`
   - 默认: `yes`
   - 如果选 `yes`,生成完整的 User CRUD 示例代码

### 第 2 步: 调用生成脚本

使用 Bash 工具执行以下命令:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate.sh \
  "<project_name>" \
  "<go_module>" \
  "<database>" \
  "<include_examples>" \
  "${CLAUDE_PLUGIN_ROOT}"
```

**重要**:
- 确保替换所有 `<参数>` 为实际值
- 项目名称需要加引号以处理特殊字符
- `${CLAUDE_PLUGIN_ROOT}` 会自动展开为插件根目录

脚本将自动完成:
- 验证环境（Go、Python3、依赖）
- 创建完整目录结构
- 生成所有四层代码（45+ 个文件）
- 配置 Docker 和 docker-compose
- 初始化 Go modules
- 安装依赖
- 生成 Ent ORM 代码
- 验证构建
- 创建文档

### 第 3 步: 显示后续步骤

项目生成完成后,向用户显示以下信息:

```
✅ Go DDD 项目创建成功!

项目位置: ./<project-name>/

后续步骤:

1. 进入项目目录:
   cd <project-name>

2. 启动数据库 (如果使用 MySQL):
   docker-compose up -d db

3. 运行数据库迁移:
   go run ./cmd/migrate

4. 启动开发服务器:
   go run ./cmd/server

5. 测试 API:
   curl http://localhost:8080/health
   curl http://localhost:8080/api/v1/users

6. 查看文档:
   - 架构设计: docs/architecture.md
   - 开发指南: docs/development.md
   - 部署指南: docs/deployment.md

7. 运行测试:
   go test ./...

8. 代码检查:
   golangci-lint run

项目包含:
✅ DDD 四层架构 (Domain, Application, Infrastructure, Interface)
✅ User CRUD 完整实现 (Entity, Value Object, Repository, Service, Handler)
✅ Gin Web 框架配置
✅ Ent ORM + MySQL/SQLite
✅ Viper 配置管理
✅ slog 结构化日志
✅ Prometheus 监控
✅ Sentry 错误追踪
✅ Docker + docker-compose
✅ OpenAPI 3.1 规范
✅ 单元测试 + 集成测试
✅ 完整文档

开始开发吧! 🚀
```

## 使用示例

### 交互式使用

```
用户: /init-go-web

系统询问:
1. 项目名称: my-service
2. Go module 路径: github.com/myorg/my-service
3. 数据库类型: mysql
4. 包含示例: yes

[脚本自动生成项目]

系统显示: ✅ 项目创建成功! [后续步骤]
```

## 错误处理

如果发生错误,清晰地告知用户:

- **项目名称无效**: "项目名称只能包含小写字母、数字和连字符"
- **目录已存在**: "目录 '<name>' 已存在,请选择其他名称或删除现有目录"
- **Go 未安装**: "未检测到 Go,请先安装 Go 1.21+"
- **Python3 未安装**: "未检测到 Python3,请先安装 Python 3.8+"
- **依赖未安装**: "Jinja2 或 PyYAML 未安装,请运行: pip3 install jinja2 pyyaml"
- **依赖安装失败**: "依赖安装失败: <error>,请检查网络连接"

## 前置依赖

运行此命令前,请确保已安装:

1. **Go 1.21+**
   ```bash
   # macOS
   brew install go

   # 验证
   go version
   ```

2. **Python 3.8+**
   ```bash
   # macOS
   brew install python3

   # 验证
   python3 --version
   ```

3. **Python 依赖**
   ```bash
   pip3 install jinja2 pyyaml
   ```

4. **Docker** (可选,用于运行数据库)
   ```bash
   # macOS
   brew install --cask docker
   ```

## 注意事项

- 确保在调用脚本前验证所有输入
- 项目生成过程可能需要几分钟 (下载 Go 依赖)
- 生成的项目目录在当前工作目录下
- 不要覆盖现有目录
- 脚本会自动验证环境并提供清晰的错误提示

## 相关文档

此命令生成的项目包含以下文档:
- DDD 核心概念 (参考 ddd-core-concepts skill)
- DDD 四层架构 (参考 ddd-layered-architecture skill)
- Go 项目结构 (参考 go-project-structure skill)
- 技术栈集成 (参考 go-tech-stack-integration skill)
- Clean Architecture 原则 (参考 clean-architecture-principles skill)
- CloudEvents 模式 (参考 cloudevents-pattern skill)
