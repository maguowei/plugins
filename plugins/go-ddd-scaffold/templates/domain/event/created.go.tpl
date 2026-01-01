package event

import (
	"time"

	"github.com/google/uuid"
	cloudevents "github.com/cloudevents/sdk-go/v2"
)

// {{ .Events.0.Name }} {{ .Events.0.NameCN }}
// 领域事件：表示领域中已发生的业务事实
type {{ .Events.0.Name }} struct {
{{- range .Events.0.Fields }}
	{{ .Name }} {{ .Type }} `json:"{{ .JsonTag }}"` // {{ .Comment }}
{{- end }}
}

// New{{ .Events.0.Name }} 创建{{ .Events.0.NameCN }}
func New{{ .Events.0.Name }}({{ range $i, $f := .Events.0.Fields }}{{ if $i }}, {{ end }}{{ .Name | lower }} {{ .Type }}{{ end }}) {{ .Events.0.Name }} {
	return {{ .Events.0.Name }}{
{{- range .Events.0.Fields }}
		{{ .Name }}: {{ .Name | lower }},
{{- end }}
	}
}

// ToCloudEvent 转换为 CloudEvents 标准格式
// CloudEvents 是 CNCF 的云原生事件规范，提供统一的事件描述格式
func (e {{ .Events.0.Name }}) ToCloudEvent() cloudevents.Event {
	event := cloudevents.NewEvent()

	// 必需属性
	event.SetID(uuid.New().String())
	event.SetSource("{{ .Events.0.CloudEventSource }}")
	event.SetType("{{ .Events.0.CloudEventType }}")
	event.SetTime(e.CreatedAt)

	// 数据负载
	event.SetData(cloudevents.ApplicationJSON, e)

	return event
}
