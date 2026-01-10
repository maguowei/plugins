#!/usr/bin/env python3
"""
Go DDD Scaffold 模板渲染器

使用 Jinja2 渲染 Go 项目模板文件。
支持变量合并、条件判断、循环等高级功能。

用法:
    python3 render.py \\
        --template-dir /path/to/templates \\
        --manifest base/_manifest.yaml \\
        --output-dir /path/to/project \\
        --var project_name=my-service \\
        --var go_module=github.com/me/my-service \\
        --var database=mysql \\
        --var include_examples=yes
"""

import os
import sys
import argparse
import yaml
import re
from pathlib import Path
from typing import Dict, Any, List
from jinja2 import Environment, FileSystemLoader, Template


class TemplateRenderer:
    """模板渲染器类"""

    def __init__(self, template_dir: str, output_dir: str, variables: Dict[str, Any]):
        self.template_dir = Path(template_dir)
        self.output_dir = Path(output_dir)
        self.variables = variables
        self.generated_files = []

        # 创建 Jinja2 环境
        self.jinja_env = Environment(
            loader=FileSystemLoader(str(self.template_dir)),
            trim_blocks=True,
            lstrip_blocks=True
        )

    def load_yaml(self, file_path: Path) -> Dict[str, Any]:
        """读取 YAML 文件"""
        with open(file_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f) or {}

    def merge_variables(self, *dicts) -> Dict[str, Any]:
        """深度合并多个字典"""
        result = {}
        for d in dicts:
            if d:
                result = self._deep_merge(result, d)
        return result

    def _deep_merge(self, dict1: Dict, dict2: Dict) -> Dict:
        """递归深度合并两个字典"""
        result = dict1.copy()
        for key, value in dict2.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge(result[key], value)
            else:
                result[key] = value
        return result

    def capitalize_keys(self, data: Any) -> Any:
        """将字典的键首字母大写并转换为驼峰命名（递归处理）"""
        if isinstance(data, dict):
            result = {}
            for key, value in data.items():
                # 将下划线命名转换为驼峰命名
                # 例如: go_dependencies -> GoDependencies
                parts = key.split('_')
                new_key = ''.join(part.capitalize() for part in parts)
                # 递归处理值
                result[new_key] = self.capitalize_keys(value)
            return result
        elif isinstance(data, list):
            return [self.capitalize_keys(item) for item in data]
        else:
            return data

    def load_all_variables(self) -> Dict[str, Any]:
        """加载并合并所有变量配置"""
        vars_dir = self.template_dir / 'vars'

        # 1. 读取 default.yaml
        default_vars = self.load_yaml(vars_dir / 'default.yaml')

        # 2. 读取数据库特定配置
        database = self.variables.get('database', 'mysql')
        db_vars = self.load_yaml(vars_dir / f'db_{database}.yaml')

        # 3. 读取聚合配置（如果 include_examples=yes）
        include_examples = self.variables.get('include_examples', 'no')
        aggregate_vars = {}
        if include_examples.lower() in ['yes', 'true', '1']:
            aggregates_dir = vars_dir / 'aggregates'
            if aggregates_dir.exists():
                for agg_file in aggregates_dir.glob('*.yaml'):
                    agg_data = self.load_yaml(agg_file)
                    aggregate_vars = self.merge_variables(aggregate_vars, agg_data)

        # 合并所有变量
        all_vars = self.merge_variables(
            default_vars,
            db_vars,
            aggregate_vars,
            self.variables  # 命令行参数优先级最高
        )

        # 更新 project 字段
        if 'project' not in all_vars:
            all_vars['project'] = {}
        all_vars['project'].update({
            'name': self.variables.get('project_name', ''),
            'go_module': self.variables.get('go_module', ''),
            'database': database,
            'include_examples': include_examples.lower() in ['yes', 'true', '1']
        })

        # 将所有键首字母大写（匹配 Go text/template 命名约定）
        all_vars = self.capitalize_keys(all_vars)

        return all_vars

    def preprocess_template(self, content: str) -> str:
        """
        预处理模板内容，转换 Go text/template 语法到 Jinja2

        处理顺序：
        1. 先处理控制结构（if, range, end）- 这些会改变模板的结构
        2. 再处理变量引用（移除 . 和 $ 前缀）- 这些只是简单替换
        """
        lines = content.split('\n')
        result_lines = []
        block_stack = []  # 栈：存储 ('if', ...) 或 ('for', ...)

        for line in lines:
            processed_line = line

            # ========== 第一阶段：处理控制结构 ==========

            # 1. 处理 range 循环（必须在处理变量引用之前）
            # 1a. range 带变量：{{- range $i, $p := .Params }}
            if re.search(r'\{\{-?\s*range\s+\$(\w+),\s*\$(\w+)\s*:=\s*\.([\w.]+)\s*\}\}', processed_line):
                processed_line = re.sub(
                    r'\{\{-?\s*range\s+\$(\w+),\s*\$(\w+)\s*:=\s*\.([\w.]+)\s*\}\}',
                    r'{% for \1, \2 in enumerate(\3) %}',
                    processed_line
                )
                block_stack.append('for')

            # 1b. 简单 range：{{- range .Items }}
            elif re.search(r'\{\{-?\s*range\s+\.([\w.]+)\s*\}\}', processed_line):
                processed_line = re.sub(r'\{\{-?\s*range\s+\.([\w.]+)\s*\}\}', r'{% for item in \1 %}', processed_line)
                block_stack.append('for')

            # 2. 处理 if 语句
            # 2a. if and eq：{{- if and .A (eq .B "v") }}
            elif re.search(r'\{\{-?\s*if\s+and\s+\.([\w.]+)\s+\(eq\s+\.([\w.]+)\s+"([^"]+)"\)\s*\}\}', processed_line):
                processed_line = re.sub(
                    r'\{\{-?\s*if\s+and\s+\.([\w.]+)\s+\(eq\s+\.([\w.]+)\s+"([^"]+)"\)\s*\}\}',
                    r'{% if \1 and \2 == "\3" %}',
                    processed_line
                )
                block_stack.append('if')

            # 2b. if eq：{{- if eq .Var "value" }}
            elif re.search(r'\{\{-?\s*if\s+eq\s+\.([\w.]+)\s+"([^"]+)"\s*\}\}', processed_line):
                processed_line = re.sub(
                    r'\{\{-?\s*if\s+eq\s+\.([\w.]+)\s+"([^"]+)"\s*\}\}',
                    r'{% if \1 == "\2" %}',
                    processed_line
                )
                block_stack.append('if')

            # 2c. 简单 if：{{- if .Cond }} 或 {{- if $var }}
            elif re.search(r'\{\{-?\s*if\s+[\.$]+([\w.]+)\s*\}\}', processed_line):
                processed_line = re.sub(r'\{\{-?\s*if\s+[\.$]+([\w.]+)\s*\}\}', r'{% if \1 %}', processed_line)
                block_stack.append('if')

            # 2d. else if：{{- else if eq .Var "value" }}
            elif re.search(r'\{\{-?\s*else\s+if\s+eq\s+\.([\w.]+)\s+"([^"]+)"\s*\}\}', processed_line):
                processed_line = re.sub(
                    r'\{\{-?\s*else\s+if\s+eq\s+\.([\w.]+)\s+"([^"]+)"\s*\}\}',
                    r'{% elif \1 == "\2" %}',
                    processed_line
                )
                # else if 不改变栈（仍在同一个 if 块中）

            # 3. 处理 end 标签（根据栈顶决定是 endif 还是 endfor）
            elif re.search(r'\{\{-?\s*end\s*\}\}', processed_line):
                if block_stack:
                    block_type = block_stack.pop()
                    if block_type == 'if':
                        processed_line = re.sub(r'\{\{-?\s*end\s*\}\}', r'{% endif %}', processed_line)
                    elif block_type == 'for':
                        processed_line = re.sub(r'\{\{-?\s*end\s*\}\}', r'{% endfor %}', processed_line)
                else:
                    # 栈为空，默认 endif
                    processed_line = re.sub(r'\{\{-?\s*end\s*\}\}', r'{% endif %}', processed_line)

            # ========== 第二阶段：处理变量引用 ==========

            # 4. 处理根上下文引用：{{ $.Var }} → {{ Var }}
            processed_line = re.sub(r'\{\{\s*\$\.([\w.]+)\s*\}\}', r'{{ \1 }}', processed_line)

            # 5. 处理变量引用：{{ $var }} → {{ var }} (移除 $)
            processed_line = re.sub(r'\{\{\s*\$(\w+)\s*\}\}', r'{{ \1 }}', processed_line)

            # 6. 处理点号引用：{{ .Var }} → {{ Var }}
            processed_line = re.sub(r'\{\{\s*\.([\w.]+)\s*\}\}', r'{{ \1 }}', processed_line)

            # 7. 处理 {% %} 标签中的点号引用：{% if .Var %} → {% if Var %}
            processed_line = re.sub(r'(\{%\s+\w+\s+)\.(\w+[\w.]*)', r'\1\2', processed_line)

            result_lines.append(processed_line)

        return '\n'.join(result_lines)

    def render_template(self, template_path: str, variables: Dict[str, Any]) -> str:
        """渲染单个模板文件"""
        # 读取模板文件
        full_path = self.template_dir / template_path
        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 预处理模板（转换 Go template 语法）
        content = self.preprocess_template(content)

        # 使用 Jinja2 渲染
        template = Template(content)
        return template.render(**variables)

    def evaluate_condition(self, condition: str, variables: Dict[str, Any]) -> bool:
        """评估 manifest 中的条件表达式"""
        if not condition or condition.strip() == '':
            return True

        # 简单的条件评估（仅支持基本的布尔值检查）
        # 例如：{{ .IncludeExamples }} 或 {{ and .A (eq .B "v") }}
        try:
            # 预处理条件
            condition = self.preprocess_template(condition)
            # 移除外层的 {{ }}
            condition = condition.replace('{{', '').replace('}}', '').strip()
            # 使用 Jinja2 评估
            template = Template('{% if ' + condition + ' %}True{% else %}False{% endif %}')
            result = template.render(**variables)
            return result == 'True'
        except Exception as e:
            print(f"警告: 条件评估失败: {condition}, 错误: {e}", file=sys.stderr)
            return True  # 默认包含

    def process_manifest(self, manifest_path: str):
        """处理 manifest 文件并生成所有文件"""
        # 读取 manifest
        manifest_full_path = self.template_dir / manifest_path
        manifest = self.load_yaml(manifest_full_path)

        # 获取 manifest 所在目录（用于解析相对路径）
        manifest_dir = Path(manifest_path).parent

        # 加载所有变量
        all_variables = self.load_all_variables()

        # 获取 output_base（如果有）
        output_base = manifest.get('output_base', '')
        if output_base:
            # 预处理 output_base（可能包含 Go template 语法）
            output_base = self.preprocess_template(output_base)
            # 渲染 output_base（可能包含变量）
            output_base = Template(output_base).render(**all_variables)

        # 处理每个文件
        files = manifest.get('files', [])
        for file_config in files:
            template_file = file_config.get('template')
            output_file = file_config.get('output')
            condition = file_config.get('condition', '')

            # 评估条件
            if not self.evaluate_condition(condition, all_variables):
                print(f"  跳过 {output_file} (条件不满足)", file=sys.stderr)
                continue

            # 构建模板文件的完整路径
            template_full_path = str(manifest_dir / template_file)

            # 预处理并渲染 output 路径（可能包含 Go template 语法和变量）
            output_path = self.preprocess_template(output_file)
            output_path = Template(output_path).render(**all_variables)

            # 构建完整的输出路径
            if output_base:
                final_output_path = self.output_dir / output_base / output_path
            else:
                final_output_path = self.output_dir / output_path

            # 创建输出目录
            final_output_path.parent.mkdir(parents=True, exist_ok=True)

            # 渲染模板
            try:
                rendered_content = self.render_template(template_full_path, all_variables)

                # 写入文件
                with open(final_output_path, 'w', encoding='utf-8') as f:
                    f.write(rendered_content)

                self.generated_files.append(str(final_output_path))
                print(f"✓ 生成 {final_output_path}")

            except Exception as e:
                print(f"✗ 生成失败 {final_output_path}: {e}", file=sys.stderr)
                raise

    def get_generated_files(self) -> List[str]:
        """获取已生成的文件列表"""
        return self.generated_files


def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(
        description='Go DDD Scaffold 模板渲染器',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    parser.add_argument(
        '--template-dir',
        required=True,
        help='模板目录路径'
    )

    parser.add_argument(
        '--manifest',
        required=True,
        help='Manifest 文件路径（相对于 template-dir）'
    )

    parser.add_argument(
        '--output-dir',
        required=True,
        help='输出目录路径'
    )

    parser.add_argument(
        '--var',
        action='append',
        dest='variables',
        help='变量定义（格式：key=value），可多次使用'
    )

    return parser.parse_args()


def main():
    """主函数"""
    args = parse_arguments()

    # 解析变量
    variables = {}
    if args.variables:
        for var in args.variables:
            if '=' not in var:
                print(f"错误: 变量格式无效: {var}（应为 key=value）", file=sys.stderr)
                sys.exit(1)
            key, value = var.split('=', 1)
            variables[key] = value

    # 创建渲染器
    renderer = TemplateRenderer(
        template_dir=args.template_dir,
        output_dir=args.output_dir,
        variables=variables
    )

    # 处理 manifest
    try:
        renderer.process_manifest(args.manifest)

        # 输出统计信息
        print(f"\n✅ 成功生成 {len(renderer.get_generated_files())} 个文件")

    except Exception as e:
        print(f"\n❌ 渲染失败: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
