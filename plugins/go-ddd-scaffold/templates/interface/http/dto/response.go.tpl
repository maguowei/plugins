package dto

import (
	"time"

	"github.com/google/uuid"
	appdto "{{ .GoModule }}/{{ .Paths.Application }}/{{ .Aggregate.Name }}/dto"
)

// {{ .Entity.Name }}Response {{ .Entity.NameCN }}响应
type {{ .Entity.Name }}Response struct {
	ID        string    `json:"id"`         // {{ .Entity.NameCN }} ID
	{{- range .Entity.ResponseFields }}
	{{ .Name }} {{ .HTTPType }} `json:"{{ .JSONTag }}"` // {{ .Comment }}
	{{- end }}
	CreatedAt time.Time `json:"created_at"` // 创建时间
	UpdatedAt time.Time `json:"updated_at"` // 更新时间
}

// {{ .Entity.Name }}ListResponse {{ .Entity.NameCN }}列表响应
type {{ .Entity.Name }}ListResponse struct {
	Items      []{{ .Entity.Name }}Response `json:"items"`       // {{ .Entity.NameCN }}列表
	Total      int64                        `json:"total"`       // 总数量
	Page       int                          `json:"page"`        // 当前页码
	PageSize   int                          `json:"page_size"`   // 每页数量
	TotalPages int                          `json:"total_pages"` // 总页数
}

// ErrorResponse 错误响应
type ErrorResponse struct {
	Error   string `json:"error"`   // 错误码
	Message string `json:"message"` // 错误消息
}

// To{{ .Entity.Name }}Response 将应用层 DTO 转换为 HTTP 响应
func To{{ .Entity.Name }}Response(dto appdto.{{ .Entity.Name }}Response) {{ .Entity.Name }}Response {
	return {{ .Entity.Name }}Response{
		ID: dto.ID.String(),
		{{- range .Entity.ResponseFields }}
		{{ .Name }}: {{ .ConversionFunc }},
		{{- end }}
		CreatedAt: dto.CreatedAt,
		UpdatedAt: dto.UpdatedAt,
	}
}

// To{{ .Entity.Name }}ListResponse 将应用层 DTO 列表转换为 HTTP 响应
func To{{ .Entity.Name }}ListResponse(dtos []appdto.{{ .Entity.Name }}Response, total int64, page, pageSize int) {{ .Entity.Name }}ListResponse {
	items := make([]{{ .Entity.Name }}Response, 0, len(dtos))
	for _, dto := range dtos {
		items = append(items, To{{ .Entity.Name }}Response(dto))
	}

	totalPages := int(total) / pageSize
	if int(total)%pageSize != 0 {
		totalPages++
	}

	return {{ .Entity.Name }}ListResponse{
		Items:      items,
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
	}
}
