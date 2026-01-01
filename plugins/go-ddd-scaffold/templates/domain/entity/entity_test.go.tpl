package entity

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/valueobject"
)

func TestNew{{ .Entity.Name }}(t *testing.T) {
	// 准备测试数据
{{- range .Entity.ConstructorParams }}
{{- if eq .Type "valueobject.Email" }}
	{{ .Name }}, err := valueobject.NewEmail("test@example.com")
	require.NoError(t, err)
{{- else if eq .Type "string" }}
	{{ .Name }} := "Test {{ .Name }}"
{{- end }}
{{- end }}

	// 创建实体
	entity, err := New{{ .Entity.Name }}({{ range $i, $p := .Entity.ConstructorParams }}{{ if $i }}, {{ end }}{{ .Name }}{{ end }})

	// 断言
	require.NoError(t, err)
	require.NotNil(t, entity)
	assert.NotEqual(t, "", entity.ID().String())
{{- range .Entity.Fields }}
	assert.Equal(t, {{ .Name }}, entity.{{ .GetterName }}())
{{- end }}
	assert.False(t, entity.CreatedAt().IsZero())
	assert.False(t, entity.UpdatedAt().IsZero())
}

func TestNew{{ .Entity.Name }}_ValidationError(t *testing.T) {
	testCases := []struct {
		name      string
{{- range .Entity.ConstructorParams }}
		{{ .Name }}  {{ .Type }}
{{- end }}
		wantError bool
	}{
		{
			name: "空名称应该返回错误",
{{- range .Entity.ConstructorParams }}
{{- if eq .Type "valueobject.Email" }}
			{{ .Name }}: func() valueobject.Email { email, _ := valueobject.NewEmail("test@example.com"); return email }(),
{{- else if eq .Type "string" }}
			{{ .Name }}: "",
{{- end }}
{{- end }}
			wantError: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			entity, err := New{{ .Entity.Name }}({{ range $i, $p := .Entity.ConstructorParams }}{{ if $i }}, {{ end }}tc.{{ .Name }}{{ end }})

			if tc.wantError {
				assert.Error(t, err)
				assert.Nil(t, entity)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, entity)
			}
		})
	}
}

{{- range .Entity.Methods }}

func Test{{ $.Entity.Name }}_{{ .Name }}(t *testing.T) {
	// 准备测试数据
{{- range $.Entity.ConstructorParams }}
{{- if eq .Type "valueobject.Email" }}
	{{ .Name }}, _ := valueobject.NewEmail("test@example.com")
{{- else if eq .Type "string" }}
	{{ .Name }} := "Test {{ .Name }}"
{{- end }}
{{- end }}

	entity, err := New{{ $.Entity.Name }}({{ range $i, $p := $.Entity.ConstructorParams }}{{ if $i }}, {{ end }}{{ .Name }}{{ end }})
	require.NoError(t, err)

	// 测试正常情况
{{- range .Params }}
{{- if eq .Type "string" }}
	new{{ .Name | title }} := "New {{ .Name }}"
{{- else if eq .Type "valueobject.Email" }}
	new{{ .Name | title }}, _ := valueobject.NewEmail("new@example.com")
{{- end }}
{{- end }}

	err = entity.{{ .Name }}({{ range $i, $p := .Params }}{{ if $i }}, {{ end }}new{{ .Name | title }}{{ end }})
	assert.NoError(t, err)

	// 测试验证失败情况
	err = entity.{{ .Name }}({{ range $i, $p := .Params }}{{ if $i }}, {{ end }}{{ if eq .Type "string" }}""{{ else }}new{{ .Name | title }}{{ end }}{{ end }})
	assert.Error(t, err)
}
{{- end }}

func Test{{ .Entity.Name }}_Equals(t *testing.T) {
	// 准备测试数据
{{- range .Entity.ConstructorParams }}
{{- if eq .Type "valueobject.Email" }}
	{{ .Name }}, _ := valueobject.NewEmail("test@example.com")
{{- else if eq .Type "string" }}
	{{ .Name }} := "Test {{ .Name }}"
{{- end }}
{{- end }}

	entity1, _ := New{{ .Entity.Name }}({{ range $i, $p := .Entity.ConstructorParams }}{{ if $i }}, {{ end }}{{ .Name }}{{ end }})
	entity2, _ := New{{ .Entity.Name }}({{ range $i, $p := .Entity.ConstructorParams }}{{ if $i }}, {{ end }}{{ .Name }}{{ end }})

	// 不同 ID 的实体不相等
	assert.False(t, entity1.Equals(entity2))

	// 与自己相等
	assert.True(t, entity1.Equals(entity1))

	// 与 nil 不相等
	assert.False(t, entity1.Equals(nil))
}
