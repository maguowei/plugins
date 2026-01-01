package event

import (
	"log"
	"sync"

	cloudevents "github.com/cloudevents/sdk-go/v2"
	domainevent "{{ .GoModule }}/{{ .Paths.Domain }}/event"
)

// MemoryEventBus 内存事件总线实现
// 用于开发和测试环境的简单事件总线
// 生产环境建议使用 Kafka、NATS 等消息队列
type MemoryEventBus struct {
	handlers map[string][]domainevent.EventHandler
	mu       sync.RWMutex
}

// NewMemoryEventBus 创建内存事件总线
func NewMemoryEventBus() *MemoryEventBus {
	return &MemoryEventBus{
		handlers: make(map[string][]domainevent.EventHandler),
	}
}

// Publish 发布事件
// 同步调用所有订阅该事件类型的处理器
func (b *MemoryEventBus) Publish(event cloudevents.Event) error {
	b.mu.RLock()
	defer b.mu.RUnlock()

	eventType := event.Type()

	handlers, exists := b.handlers[eventType]
	if !exists {
		// 没有处理器订阅此事件类型
		log.Printf("no handlers for event type: %s", eventType)
		return nil
	}

	// 调用所有处理器
	for _, handler := range handlers {
		if err := handler.Handle(event); err != nil {
			// 错误处理：记录日志但继续执行其他处理器
			log.Printf("handler error for event %s: %v", eventType, err)
			// 可以选择返回错误或继续
			// return fmt.Errorf("handler failed: %w", err)
		}
	}

	return nil
}

// Subscribe 订阅事件
// eventType: 事件类型，如 "com.example.user.created"
// handler: 事件处理器
func (b *MemoryEventBus) Subscribe(eventType string, handler domainevent.EventHandler) error {
	b.mu.Lock()
	defer b.mu.Unlock()

	b.handlers[eventType] = append(b.handlers[eventType], handler)

	log.Printf("subscribed to event type: %s", eventType)

	return nil
}

// Unsubscribe 取消订阅（可选功能）
func (b *MemoryEventBus) Unsubscribe(eventType string) {
	b.mu.Lock()
	defer b.mu.Unlock()

	delete(b.handlers, eventType)
	log.Printf("unsubscribed from event type: %s", eventType)
}

// Clear 清空所有订阅（用于测试）
func (b *MemoryEventBus) Clear() {
	b.mu.Lock()
	defer b.mu.Unlock()

	b.handlers = make(map[string][]domainevent.EventHandler)
	log.Println("cleared all event subscriptions")
}

// GetSubscriberCount 获取订阅者数量（用于调试）
func (b *MemoryEventBus) GetSubscriberCount(eventType string) int {
	b.mu.RLock()
	defer b.mu.RUnlock()

	handlers, exists := b.handlers[eventType]
	if !exists {
		return 0
	}

	return len(handlers)
}
