export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // 新功能
        'fix',      // 修复 bug
        'docs',     // 文档变更
        'style',    // 代码格式 (不影响功能)
        'refactor', // 重构 (既不是新功能也不是 bug 修复)
        'perf',     // 性能优化
        'test',     // 添加/修改测试
        'chore',    // 构建过程或辅助工具变动
        'revert',   // 回滚
        'ci',       // CI 配置变更
        'build',    // 构建系统变更
      ],
    ],
    'subject-case': [0],
  },
};
