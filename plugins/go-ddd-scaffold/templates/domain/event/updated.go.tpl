package event

import (
	"time"

	"github.com/google/uuid"
	cloudevents "github.com/cloudevents/sdk-go/v2"
)

// {{ .Events.1.Name }} {{ .Events.1.NameCN }}
// 领域事件：表示领域中已发生的业务事实
type {{ .Events.1.Name }} struct {
{{- range .Events.1.Fields }}
	{{ .Name }} {{ .Type }} `json:"{{ .JsonTag }}"` // {{ .Comment }}
{{- end }}
}

// New{{ .Events.1.Name }} 创建{{ .Events.1.NameCN }}
func New{{ .Events.1.Name }}({{ range $i, $f := .Events.1.Fields }}{{ if $i }}, {{ end }}{{ .Name | lower }} {{ .Type }}{{ end }}) {{ .Events.1.Name }} {
	return {{ .Events.1.Name }}{
{{- range .Events.1.Fields }}
		{{ .Name }}: {{ .Name | lower }},
{{- end }}
	}
}

// ToCloudEvent 转换为 CloudEvents 标准格式
func (e {{ .Events.1.Name }}) ToCloudEvent() cloudevents.Event {
	event := cloudevents.NewEvent()

	// 必需属性
	event.SetID(uuid.New().String())
	event.SetSource("{{ .Events.1.CloudEventSource }}")
	event.SetType("{{ .Events.1.CloudEventType }}")
	event.SetTime(e.UpdatedAt)

	// 数据负载
	event.SetData(cloudevents.ApplicationJSON, e)

	return event
}
