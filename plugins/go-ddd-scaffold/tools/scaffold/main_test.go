package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRenderTemplate(t *testing.T) {
	// 创建临时模板目录
	tmpDir := t.TempDir()
	tplDir := filepath.Join(tmpDir, "templates")
	outDir := filepath.Join(tmpDir, "output")
	os.MkdirAll(filepath.Join(tplDir, "sub"), 0o755)

	// 写入测试模板
	os.WriteFile(filepath.Join(tplDir, "hello.txt.tpl"), []byte("Hello {{.project_name}}!"), 0o644)
	os.WriteFile(filepath.Join(tplDir, "sub", "nested.go.tpl"), []byte("package {{.project_name}}"), 0o644)

	// 写入变量文件
	varsFile := filepath.Join(tmpDir, "vars.yaml")
	os.WriteFile(varsFile, []byte("project_name: myapp\ngo_module: github.com/me/myapp\n"), 0o644)

	// 执行渲染
	err := render(varsFile, tplDir, outDir)
	require.NoError(t, err)

	// 验证输出
	content, err := os.ReadFile(filepath.Join(outDir, "hello.txt"))
	require.NoError(t, err)
	assert.Equal(t, "Hello myapp!", string(content))

	content, err = os.ReadFile(filepath.Join(outDir, "sub", "nested.go"))
	require.NoError(t, err)
	assert.Equal(t, "package myapp", string(content))
}

func TestSkipUserFilesWhenNoExamples(t *testing.T) {
	tmpDir := t.TempDir()
	tplDir := filepath.Join(tmpDir, "templates")
	outDir := filepath.Join(tmpDir, "output")
	os.MkdirAll(filepath.Join(tplDir, "handler"), 0o755)

	os.WriteFile(filepath.Join(tplDir, "handler", "user.go.tpl"), []byte("package handler"), 0o644)
	os.WriteFile(filepath.Join(tplDir, "config.go.tpl"), []byte("package config"), 0o644)

	varsFile := filepath.Join(tmpDir, "vars.yaml")
	os.WriteFile(varsFile, []byte("project_name: test\ninclude_examples: false\n"), 0o644)

	err := render(varsFile, tplDir, outDir)
	require.NoError(t, err)

	// user.go 应该被跳过
	_, err = os.Stat(filepath.Join(outDir, "handler", "user.go"))
	assert.True(t, os.IsNotExist(err))

	// config.go 应该存在
	_, err = os.Stat(filepath.Join(outDir, "config.go"))
	assert.NoError(t, err)
}

func TestCopyNonTplFiles(t *testing.T) {
	tmpDir := t.TempDir()
	tplDir := filepath.Join(tmpDir, "templates")
	outDir := filepath.Join(tmpDir, "output")
	os.MkdirAll(tplDir, 0o755)

	os.WriteFile(filepath.Join(tplDir, "static.txt"), []byte("raw content"), 0o644)

	varsFile := filepath.Join(tmpDir, "vars.yaml")
	os.WriteFile(varsFile, []byte("project_name: test\n"), 0o644)

	err := render(varsFile, tplDir, outDir)
	require.NoError(t, err)

	content, err := os.ReadFile(filepath.Join(outDir, "static.txt"))
	require.NoError(t, err)
	assert.Equal(t, "raw content", string(content))
}
