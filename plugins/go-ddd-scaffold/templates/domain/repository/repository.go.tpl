package repository

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/entity"
)

// 领域错误定义
var (
{{- range .Repository.Errors }}
	{{ .Name }} = errors.New("{{ .Message }}")
{{- end }}
)

// {{ .Repository.Name }} {{ .Repository.NameCN }}接口
// Repository 模式：提供类似集合的操作，隔离领域层和数据访问层
//
// 设计原则：
// 1. 接口定义在领域层，实现在基础设施层（依赖倒置）
// 2. 使用领域语言，不暴露技术细节
// 3. 返回领域对象，不返回 ORM 对象
// 4. 只为聚合根创建仓储
type {{ .Repository.Name }} interface {
{{- range .Repository.Methods }}
	// {{ .Name }} {{ .Comment }}
	{{ .Name }}({{ range $i, $p := .Params }}{{ if $i }}, {{ end }}{{ .Name }} {{ .Type }}{{ end }}) ({{ range $i, $r := .Returns }}{{ if $i }}, {{ end }}{{ .Type }}{{ end }})
{{- end }}
}
