package dto

// Create{{ .Entity.Name }}Request 创建{{ .Entity.NameCN }}请求
type Create{{ .Entity.Name }}Request struct {
	{{- range .Entity.CreateFields }}
	{{ .Name }} {{ .HTTPType }} `json:"{{ .JSONTag }}" binding:"{{ .Validation }}"` // {{ .Comment }}
	{{- end }}
}

// Update{{ .Entity.Name }}Request 更新{{ .Entity.NameCN }}请求
type Update{{ .Entity.Name }}Request struct {
	{{- range .Entity.UpdateFields }}
	{{ .Name }} {{ .HTTPType }} `json:"{{ .JSONTag }}" binding:"{{ .Validation }}"` // {{ .Comment }}
	{{- end }}
}

// Validation 说明：
// - required: 必填字段
// - email: 邮箱格式验证
// - min=X: 字符串最小长度
// - max=X: 字符串最大长度
// - gte=X: 数值大于等于
// - lte=X: 数值小于等于
// - oneof=a b c: 枚举值验证
//
// 示例：
// Email string `json:"email" binding:"required,email"`
// Name  string `json:"name" binding:"required,min=1,max=100"`
// Age   int    `json:"age" binding:"gte=0,lte=150"`
