package main

import (
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"gopkg.in/yaml.v3"
)

func main() {
	varsFile := flag.String("vars", "", "变量文件路径 (YAML)")
	tplDir := flag.String("templates", "", "模板目录路径")
	outDir := flag.String("output", "", "输出目录路径")
	flag.Parse()

	if *varsFile == "" || *tplDir == "" || *outDir == "" {
		flag.Usage()
		os.Exit(1)
	}

	if err := render(*varsFile, *tplDir, *outDir); err != nil {
		log.Fatalf("渲染失败: %v", err)
	}
}

// render 读取变量并将模板目录渲染到输出目录
func render(varsFile, tplDir, outDir string) error {
	// 读取变量
	vars, err := loadVars(varsFile)
	if err != nil {
		return fmt.Errorf("加载变量失败: %w", err)
	}

	includeExamples, _ := vars["include_examples"].(bool)

	// 遍历模板目录
	return filepath.WalkDir(tplDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// 计算相对路径
		relPath, err := filepath.Rel(tplDir, path)
		if err != nil {
			return err
		}

		// 跳过根目录和 vars.yaml
		if relPath == "." || relPath == "vars.yaml" {
			return nil
		}

		// 创建目录
		if d.IsDir() {
			return os.MkdirAll(filepath.Join(outDir, relPath), 0o755)
		}

		// 检查是否为 user 相关文件（include_examples 控制）
		baseName := filepath.Base(relPath)
		if !includeExamples && isUserFile(baseName) {
			return nil
		}

		// 处理 .tpl 文件
		if strings.HasSuffix(relPath, ".tpl") {
			outputPath := filepath.Join(outDir, strings.TrimSuffix(relPath, ".tpl"))
			return renderTemplate(path, outputPath, vars)
		}

		// 非 .tpl 文件直接复制
		outputPath := filepath.Join(outDir, relPath)
		return copyFile(path, outputPath)
	})
}

// loadVars 加载 YAML 变量文件
func loadVars(path string) (map[string]any, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var vars map[string]any
	if err := yaml.Unmarshal(data, &vars); err != nil {
		return nil, err
	}
	return vars, nil
}

// isUserFile 判断文件名是否包含 "user"
func isUserFile(name string) bool {
	lower := strings.ToLower(name)
	return strings.Contains(lower, "user")
}

// renderTemplate 渲染单个模板文件
func renderTemplate(tplPath, outputPath string, vars map[string]any) error {
	content, err := os.ReadFile(tplPath)
	if err != nil {
		return err
	}

	tmpl, err := template.New(filepath.Base(tplPath)).Parse(string(content))
	if err != nil {
		return fmt.Errorf("解析模板 %s 失败: %w", tplPath, err)
	}

	if err := os.MkdirAll(filepath.Dir(outputPath), 0o755); err != nil {
		return err
	}

	f, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	defer f.Close()

	return tmpl.Execute(f, vars)
}

// copyFile 复制文件
func copyFile(src, dst string) error {
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}

	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	return err
}
