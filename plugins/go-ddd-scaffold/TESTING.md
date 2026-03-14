# Go DDD Scaffold 插件测试指南

## 测试环境准备

### 前置条件

1. **Claude Code CLI 已安装**
2. **Go 1.21+ 已安装** (插件需要验证)
3. **Docker 已安装** (用于测试生成的项目)

## 插件安装测试

### 方法 1: 本地测试 (推荐)

```bash
# 从插件市场目录启动 Claude Code
cd /Users/maguowei/Work/AI/my-claude-code-plugin
cc --plugin-dir ./plugins/go-ddd-scaffold
```

### 方法 2: 复制到用户插件目录

```bash
# 复制插件到 Claude Code 插件目录
cp -r plugins/go-ddd-scaffold ~/.claude-plugins/

# 正常启动 Claude Code
cc
```

## 测试清单

### ✅ Phase 1: Skills 加载测试

测试所有 6 个 Skills 是否正确加载和触发。

#### 测试 ddd-core-concepts

```
用户提问: "什么是 DDD 中的 Entity?"
预期: 加载 ddd-core-concepts skill,解释 Entity 概念
```

#### 测试 ddd-layered-architecture

```
用户提问: "DDD 四层架构的依赖规则是什么?"
预期: 加载 ddd-layered-architecture skill,解释依赖规则
```

#### 测试 go-project-structure

```
用户提问: "Go 标准项目布局中 cmd 目录的作用是什么?"
预期: 加载 go-project-structure skill,解释目录用途
```

#### 测试 go-tech-stack-integration

```
用户提问: "如何在 Go 中集成 Gin 和 Ent?"
预期: 加载 go-tech-stack-integration skill,提供集成指南
```

#### 测试 clean-architecture-principles

```
用户提问: "SOLID 原则中的依赖倒置原则是什么?"
预期: 加载 clean-architecture-principles skill,解释 DIP
```

#### 测试 cloudevents-pattern

```
用户提问: "如何使用 CloudEvents 发布领域事件?"
预期: 加载 cloudevents-pattern skill,提供实现指南
```

### ✅ Phase 2: Command 测试

测试 `/init-go-web` 命令是否正确执行。

#### 测试命令可用性

```bash
# 在 Claude Code 中检查命令
/help

# 应该看到:
# /init-go-web - 初始化一个新的 Go Web 项目...
```

#### 测试交互式流程

```
用户: /init-go-web

预期交互:
1. 询问项目名称
2. 询问 Go module 路径
3. 询问数据库类型
4. 询问是否包含示例
5. 调用生成脚本创建项目
```

#### 测试参数模式 (如果支持)

```
用户: /init-go-web --name test-service --db mysql --module github.com/test/test-service

预期: 直接调用生成脚本,不询问参数
```

### ✅ Phase 3: 项目生成测试

测试 `/init-go-web` 命令通过生成脚本能否成功生成项目。

#### 基础项目生成测试

```
用户: /init-go-web test-project

预期脚本行为:
1. 创建项目目录结构
2. 生成所有四层代码
3. 创建配置文件
4. 初始化 Go modules
5. 安装依赖
6. 生成 Ent schema
7. 创建文档
8. 验证项目可构建
9. 返回成功消息和后续步骤
```

#### 验证生成的项目结构

```bash
cd test-project

# 检查目录结构
ls -la
# 应包含: cmd/, internal/, pkg/, configs/, docs/, scripts/, deployments/

# 检查 Go modules
cat go.mod
# 应包含所有依赖

# 检查核心文件
ls internal/app/domain/user/entity/
ls internal/app/application/service/
ls internal/app/infrastructure/repository/
ls internal/app/interface/http/handler/
```

#### 验证生成的项目可运行

```bash
# 构建测试
go build ./cmd/server
go build ./cmd/migrate

# 单元测试
go test ./internal/app/domain/...

# 启动数据库
docker-compose up -d db

# 运行迁移
go run ./cmd/migrate

# 启动服务器
go run ./cmd/server

# 测试 API (新终端)
curl http://localhost:8080/health
# 预期: {"status":"ok"}

curl http://localhost:8080/metrics
# 预期: Prometheus metrics

curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test User"}'
# 预期: 创建用户成功

curl http://localhost:8080/api/v1/users
# 预期: 返回用户列表
```

### ✅ Phase 4: 代码质量测试

#### 检查代码规范

```bash
# 安装 linter (如果没有)
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# 运行 linter
golangci-lint run

# 预期: 无严重错误
```

#### 检查测试覆盖率

```bash
go test -cover ./internal/app/domain/...

# 预期: 至少 70% 覆盖率
```

#### 检查 DDD 架构合规性

手动验证:
- [ ] Domain layer 不依赖任何框架
- [ ] Repository 接口在 Domain layer 定义
- [ ] Repository 实现在 Infrastructure layer
- [ ] Application Service 编排业务逻辑
- [ ] Handler 只处理 HTTP 层

### ✅ Phase 5: 文档测试

验证生成的文档是否完整:

```bash
cd test-project/docs/

# 检查文档文件
ls -la
# 应包含: architecture.md, development.md, deployment.md

# 验证文档内容
cat architecture.md  # 应包含架构图和说明
cat development.md   # 应包含开发指南
cat deployment.md    # 应包含部署说明

# 检查 README
cat ../README.md     # 应包含快速开始指南
```

### ✅ Phase 6: Docker 测试

验证 Docker 配置是否正确:

```bash
# 检查 Dockerfile
cat Dockerfile
# 应该是多阶段构建

# 检查 docker-compose
cat docker-compose.yml
# 应包含 app 和 db 服务

# 完整 Docker 测试
docker-compose build
docker-compose up -d

# 等待服务启动
sleep 10

# 测试 API
curl http://localhost:8080/health

# 清理
docker-compose down -v
```

## 常见问题排查

### 问题 1: Skills 未加载

**症状**: 询问 DDD 概念时,Claude 没有加载对应 Skill

**排查**:
1. 检查插件是否正确安装: `cc --list-plugins`
2. 检查 SKILL.md 的 frontmatter 格式
3. 验证 description 字段包含触发短语

### 问题 2: Command 不可用

**症状**: `/init-go-web` 命令不存在

**排查**:
1. 检查 `commands/init-go-web.md` 文件是否存在
2. 验证 frontmatter 中的 `name` 字段
3. 重启 Claude Code

### 问题 3: 生成脚本执行失败

**症状**: 命令执行后项目未生成

**排查**:
1. 检查 `scripts/generate.sh` 是否存在且有执行权限
2. 验证传入的参数是否正确
3. 检查脚本输出的错误信息

### 问题 4: 生成的项目无法构建

**症状**: `go build` 失败

**排查**:
1. 检查 `go.mod` 是否正确生成
2. 运行 `go mod tidy`
3. 检查网络连接 (依赖下载)
4. 验证 Go 版本 >= 1.21

### 问题 5: Ent 生成失败

**症状**: Ent schema 生成报错

**排查**:
1. 检查 `pkg/ent/schema/user.go` 语法
2. 验证 Ent 依赖已安装
3. 手动运行: `go run entgo.io/ent/cmd/ent generate ./pkg/ent/schema`

## 成功标准

插件测试通过需要满足:

- ✅ 所有 6 个 Skills 正确加载
- ✅ `/init-go-web` 命令可用
- ✅ 生成脚本能够生成完整项目
- ✅ 生成的项目可以构建成功
- ✅ 生成的服务器可以运行
- ✅ API 端点正常工作
- ✅ 单元测试通过
- ✅ 文档完整
- ✅ Docker 配置正确
- ✅ 代码符合 DDD 架构

## 性能测试

### 项目生成时间

记录不同场景下的生成时间:

- **最小项目** (不含示例): 预期 < 2 分钟
- **完整项目** (含示例): 预期 < 5 分钟
- **包含依赖下载**: 预期 < 10 分钟 (取决于网络)

### 资源使用

监控生成过程中的资源使用:

- **内存**: < 500MB
- **CPU**: 正常编译负载
- **磁盘**: 生成的项目 < 50MB (不含依赖)

## 反馈和迭代

测试中发现问题,记录以下信息:

1. **问题描述**: 具体什么不工作
2. **复现步骤**: 如何触发问题
3. **预期行为**: 应该如何工作
4. **实际行为**: 实际发生了什么
5. **环境信息**: OS, Go 版本, Claude Code 版本

## 测试报告模板

```markdown
# Go DDD Scaffold 插件测试报告

**测试日期**: YYYY-MM-DD
**测试人**:
**Claude Code 版本**:
**Go 版本**:

## Skills 测试
- [ ] ddd-core-concepts
- [ ] ddd-layered-architecture
- [ ] go-project-structure
- [ ] go-tech-stack-integration
- [ ] clean-architecture-principles
- [ ] cloudevents-pattern

## Command 测试
- [ ] 命令可用
- [ ] 交互式流程
- [ ] 参数传递

## 项目生成测试
- [ ] 项目生成成功
- [ ] 目录结构正确
- [ ] 代码可构建
- [ ] 服务可运行
- [ ] API 正常

## 质量测试
- [ ] Linter 通过
- [ ] 测试通过
- [ ] DDD 架构合规
- [ ] 文档完整
- [ ] Docker 工作

## 问题记录

[记录发现的问题]

## 总体评价

[通过 / 需要修复]
```

## 下一步

测试通过后:

1. 发布插件到市场
2. 编写详细的用户文档
3. 创建视频教程
4. 收集用户反馈
5. 持续优化和改进
