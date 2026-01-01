package entity

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/valueobject"
)

// {{ .Entity.Name }} {{ .Entity.NameCN }}实体
// 聚合根：管理{{ .Entity.NameCN }}的生命周期和业务规则
type {{ .Entity.Name }} struct {
	id        uuid.UUID  // 唯一标识
{{- range .Entity.Fields }}
	{{ .Name }}  {{ .Type }}  // {{ .Comment }}
{{- end }}
	createdAt time.Time  // 创建时间
	updatedAt time.Time  // 更新时间
}

// New{{ .Entity.Name }} 创建{{ .Entity.NameCN }}
// 构造函数确保实体创建时处于有效状态
func New{{ .Entity.Name }}({{ range $i, $p := .Entity.ConstructorParams }}{{ if $i }}, {{ end }}{{ .Name }} {{ .Type }}{{ end }}) (*{{ .Entity.Name }}, error) {
	// 业务验证
{{- range .Entity.ValidationRules }}
	{{ . }}
{{- end }}

	return &{{ .Entity.Name }}{
		id: uuid.New(),
{{- range .Entity.Fields }}
		{{ .Name }}: {{ .Name }},
{{- end }}
		createdAt: time.Now(),
		updatedAt: time.Now(),
	}, nil
}

// ID 获取实体唯一标识
func (e *{{ .Entity.Name }}) ID() uuid.UUID {
	return e.id
}

{{- range .Entity.Fields }}

// {{ .GetterName }} 获取{{ .Comment }}
func (e *{{ $.Entity.Name }}) {{ .GetterName }}() {{ .Type }} {
	return e.{{ .Name }}
}
{{- end }}

// CreatedAt 获取创建时间
func (e *{{ .Entity.Name }}) CreatedAt() time.Time {
	return e.createdAt
}

// UpdatedAt 获取更新时间
func (e *{{ .Entity.Name }}) UpdatedAt() time.Time {
	return e.updatedAt
}

{{- range .Entity.Methods }}

// {{ .Name }} {{ .Comment }}
func (e *{{ $.Entity.Name }}) {{ .Name }}({{ range $i, $p := .Params }}{{ if $i }}, {{ end }}{{ .Name }} {{ .Type }}{{ end }}) {{ .Return }} {
	// 验证
{{ .Validation }}

	// 执行业务逻辑
{{ .Action }}

	return nil
}
{{- end }}

// Equals 判断两个{{ .Entity.NameCN }}是否相等
// Entity 的相等性基于唯一标识 (ID)
func (e *{{ .Entity.Name }}) Equals(other *{{ .Entity.Name }}) bool {
	if other == nil {
		return false
	}
	return e.id == other.id
}
