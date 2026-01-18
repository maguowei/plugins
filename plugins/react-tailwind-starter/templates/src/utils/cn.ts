/**
 * 合并 className 的工具函数
 * 简化版的 clsx/classnames
 */
export function cn(...classes: (string | undefined | null | false)[]): string {
  return classes.filter(Boolean).join(' ');
}
