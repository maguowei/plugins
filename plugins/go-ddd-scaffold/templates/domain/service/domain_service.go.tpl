package service

import (
	"context"

	"{{ .GoModule }}/{{ .Paths.Domain }}/{{ .Aggregate.Name }}/repository"
)

// {{ .DomainService.Name }} {{ .DomainService.NameCN }}
// Domain Service：处理不属于任何单个实体的领域逻辑
//
// 何时使用领域服务：
// 1. 操作涉及多个实体
// 2. 逻辑不自然属于任何一个实体
// 3. 需要访问多个仓储
// 4. 复杂的业务规则计算
//
// 特征：
// - 无状态（Stateless）
// - 纯业务逻辑（Pure Business Logic）
// - 使用领域语言（Domain Language）
type {{ .DomainService.Name }} struct {
	userRepo repository.UserRepository
}

// New{{ .DomainService.Name }} 创建{{ .DomainService.NameCN }}
func New{{ .DomainService.Name }}(userRepo repository.UserRepository) *{{ .DomainService.Name }} {
	return &{{ .DomainService.Name }}{
		userRepo: userRepo,
	}
}

{{- range .DomainService.Methods }}

// {{ .Name }} {{ .Comment }}
func (s *{{ $.DomainService.Name }}) {{ .Name }}({{ range $i, $p := .Params }}{{ if $i }}, {{ end }}{{ .Name }} {{ .Type }}{{ end }}) {{ range $i, $r := .Returns }}{{ if $i }}, {{ end }}{{ .Type }}{{ end }} {
	exists, err := s.userRepo.ExistsByEmail(ctx, email)
	if err != nil {
		return err
	}

	if exists {
		return repository.ErrEmailExists
	}

	return nil
}
{{- end }}
