package event

import (
	"log/slog"

	cloudevents "github.com/cloudevents/sdk-go/v2"
)

// Bus 内存事件总线
type Bus struct {
	handlers []func(cloudevents.Event)
}

func NewBus() *Bus {
	return &Bus{}
}

// Subscribe 订阅事件
func (b *Bus) Subscribe(handler func(cloudevents.Event)) {
	b.handlers = append(b.handlers, handler)
}

// Publish 发布事件
func (b *Bus) Publish(event cloudevents.Event) {
	slog.Info("发布领域事件", "type", event.Type(), "id", event.ID())
	for _, h := range b.handlers {
		go h(event)
	}
}
