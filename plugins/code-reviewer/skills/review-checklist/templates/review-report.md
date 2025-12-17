# 代码审查报告

**审查时间：**{TIME}

**审查文件：**
- {FILE_LIST}

---

## 概述

{SUMMARY}

**主要发现：**
- {KEY_FINDINGS}

---

## 详细审查

### 1. 代码质量 {QUALITY_SCORE}

#### ✅ 优点

- {POSITIVE_POINTS}

#### ⚠️ 改进建议

**问题 1：{ISSUE_TITLE}**
- **位置：**{FILE}:{LINE}
- **问题：**{DESCRIPTION}
- **建议：**{SUGGESTION}
- **示例：**

```{LANGUAGE}
{CODE_EXAMPLE}
```

---

### 2. 安全性 {SECURITY_SCORE}

#### ❌ 严重问题

**问题：{SECURITY_ISSUE}**
- **严重性：**{SEVERITY} (严重/高/中/低)
- **位置：**{FILE}:{LINE}
- **问题描述：**{DESCRIPTION}
- **风险：**{RISK_DESCRIPTION}
- **修复建议：**

```{LANGUAGE}
// 修复前
{BEFORE_CODE}

// 修复后
{AFTER_CODE}
```

#### ⚠️ 次要问题

- {LIST_OF_MINOR_ISSUES}

---

### 3. 性能 {PERFORMANCE_SCORE}

#### 优化建议

**建议 1：{PERFORMANCE_ISSUE}**
- **位置：**{FILE}:{LINE}
- **问题：**{DESCRIPTION}
- **影响：**{IMPACT}
- **优化方案：**{SOLUTION}
- **预期效果：**{EXPECTED_IMPROVEMENT}

```{LANGUAGE}
{OPTIMIZED_CODE}
```

---

### 4. 最佳实践 {BEST_PRACTICES_SCORE}

#### 架构和设计

**符合的原则：**
- ✅ {PRINCIPLE_1}
- ✅ {PRINCIPLE_2}

**需要改进：**
- ⚠️ {IMPROVEMENT_1}
- ⚠️ {IMPROVEMENT_2}

#### DDD 架构（如适用）

**Domain 层：**
- {DOMAIN_REVIEW}

**Application 层：**
- {APPLICATION_REVIEW}

**Infrastructure 层：**
- {INFRASTRUCTURE_REVIEW}

**Interfaces 层：**
- {INTERFACES_REVIEW}

---

### 5. 测试覆盖 {TEST_SCORE}

#### 当前测试状态

- 单元测试覆盖率：{COVERAGE_PERCENTAGE}%
- 集成测试：{INTEGRATION_TEST_STATUS}
- E2E 测试：{E2E_TEST_STATUS}

#### 测试建议

**建议添加的测试：**

1. **{TEST_CASE_1}**
   ```{LANGUAGE}
   {TEST_CODE_EXAMPLE}
   ```

2. **{TEST_CASE_2}**
   - 测试场景：{SCENARIO}
   - 测试目的：{PURPOSE}

---

### 6. 文档 {DOCUMENTATION_SCORE}

#### 文档完整性

- 函数/方法注释：{STATUS}
- API 文档：{STATUS}
- README 更新：{STATUS}
- 架构文档：{STATUS}

#### 建议

- {DOCUMENTATION_IMPROVEMENTS}

---

## 评分

### 维度评分

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | ★★★★☆ (4/5) | {QUALITY_COMMENT} |
| 安全性 | ★★★☆☆ (3/5) | {SECURITY_COMMENT} |
| 性能 | ★★★★☆ (4/5) | {PERFORMANCE_COMMENT} |
| 最佳实践 | ★★★☆☆ (3/5) | {PRACTICES_COMMENT} |
| 测试覆盖 | ★★☆☆☆ (2/5) | {TEST_COMMENT} |
| 文档 | ★★★☆☆ (3/5) | {DOCS_COMMENT} |

**总体评分：{OVERALL_SCORE}/5**

### 评分说明

- ★★★★★ (5分) - 优秀，无明显问题
- ★★★★☆ (4分) - 良好，有少量改进空间
- ★★★☆☆ (3分) - 合格，有明显改进空间
- ★★☆☆☆ (2分) - 需要改进，存在多个问题
- ★☆☆☆☆ (1分) - 严重问题，需要重构

---

## 优先级建议

### 🔴 立即修复（高优先级）

这些问题可能导致安全漏洞、数据丢失或严重性能问题，需要立即处理。

1. **{CRITICAL_ISSUE_1}**
   - 文件：{FILE}:{LINE}
   - 原因：{REASON}
   - 修复时间：建议在 24 小时内完成

2. **{CRITICAL_ISSUE_2}**
   - 文件：{FILE}:{LINE}
   - 原因：{REASON}
   - 修复时间：建议在 24 小时内完成

### 🟡 尽快改进（中优先级）

这些问题影响代码质量和可维护性，建议在下个迭代中处理。

1. **{MAJOR_ISSUE_1}**
   - 文件：{FILE}:{LINE}
   - 影响：{IMPACT}

2. **{MAJOR_ISSUE_2}**
   - 文件：{FILE}:{LINE}
   - 影响：{IMPACT}

### 🟢 后续优化（低优先级）

这些是优化建议，可以在时间允许时处理。

1. **{MINOR_ISSUE_1}**
   - 优化方向：{DIRECTION}

2. **{MINOR_ISSUE_2}**
   - 优化方向：{DIRECTION}

---

## 总结

### 主要成就

{POSITIVE_SUMMARY}

### 改进方向

{IMPROVEMENT_SUMMARY}

### 下一步行动

1. {ACTION_ITEM_1}
2. {ACTION_ITEM_2}
3. {ACTION_ITEM_3}

---

## 附录

### 参考资源

- [相关最佳实践文档]({LINK})
- [安全指南]({LINK})
- [性能优化指南]({LINK})

### 代码统计

- 总行数：{TOTAL_LINES}
- 新增代码：{ADDED_LINES}
- 删除代码：{DELETED_LINES}
- 修改文件数：{FILES_CHANGED}

---

**审查者：** Claude Code Reviewer
**报告生成时间：** {TIMESTAMP}
