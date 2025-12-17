---
name: review-checklist
description: 代码审查检查清单。提供 Go、TypeScript、React 和安全性等多维度的专业审查标准。在进行代码审查时使用。
allowed-tools: Read
---

# 代码审查检查清单

本技能提供结构化的代码审查检查清单，帮助进行全面、专业的代码审查。

## 使用方式

根据被审查代码的类型，选择合适的检查清单：

1. **Go 代码** → 使用 `checklists/go-checklist.md`
2. **TypeScript 代码** → 使用 `checklists/typescript-checklist.md`
3. **React 代码** → 使用 `checklists/react-checklist.md` + TypeScript checklist
4. **所有代码** → 使用 `checklists/security-checklist.md`（安全性检查）

## 检查清单概览

### Go Checklist
专注于 Go 语言特定的最佳实践：
- 错误处理
- Goroutine 和并发
- Context 使用
- 内存管理
- DDD 架构

### TypeScript Checklist
专注于 TypeScript 类型系统和最佳实践：
- 类型定义
- 类型安全
- 异步处理
- 模块组织

### React Checklist
专注于 React 组件和 Hooks：
- Hooks 规则
- 组件设计
- 性能优化
- 状态管理

### Security Checklist
通用安全性检查：
- SQL 注入
- XSS
- CSRF
- 敏感信息
- 输入验证

## 审查报告格式

使用 `templates/review-report.md` 作为报告模板，包含：
- 概述
- 详细审查（按维度组织）
- 评分
- 优先级建议
- 总结

## 严重性等级

对发现的问题，使用以下严重性等级：

- **高（Critical）** - 安全漏洞、数据丢失风险、严重性能问题
- **中（Major）** - 功能缺陷、次要安全问题、明显的性能问题
- **低（Minor）** - 代码风格、轻微优化、文档完善

## 审查原则

1. **全面性** - 覆盖所有重要维度
2. **具体性** - 指出具体问题和位置
3. **建设性** - 提供改进建议和示例
4. **优先级** - 区分严重问题和优化建议
5. **可操作性** - 提供可以直接使用的解决方案

## 文件组织

```
review-checklist/
├── SKILL.md                      # 本文件
├── checklists/                   # 检查清单目录
│   ├── go-checklist.md          # Go 检查清单
│   ├── typescript-checklist.md  # TypeScript 检查清单
│   ├── react-checklist.md       # React 检查清单
│   └── security-checklist.md    # 安全性检查清单
└── templates/
    └── review-report.md         # 审查报告模板
```

## 使用流程

1. **识别代码类型** - 根据文件扩展名和内容识别技术栈
2. **选择检查清单** - 加载相应的 checklist 文件
3. **逐项检查** - 按照清单逐项审查代码
4. **记录问题** - 记录发现的问题和改进建议
5. **生成报告** - 使用模板生成结构化报告

## 示例

对于一个 Go 文件的审查流程：

1. 识别为 Go 代码
2. 读取 `checklists/go-checklist.md`
3. 读取 `checklists/security-checklist.md`
4. 读取被审查的代码文件
5. 按照清单逐项检查
6. 使用 `templates/review-report.md` 生成报告

## 持续改进

检查清单会根据最佳实践的演进持续更新：
- 添加新的检查项
- 更新示例代码
- 改进建议的质量
- 反映最新的安全威胁

## 参考资源

- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [TypeScript 官方文档](https://www.typescriptlang.org/docs/)
- [React 最佳实践](https://react.dev/learn)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Domain-Driven Design](https://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215)
