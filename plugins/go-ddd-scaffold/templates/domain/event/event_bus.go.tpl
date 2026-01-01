package event

import (
	cloudevents "github.com/cloudevents/sdk-go/v2"
)

// EventBus 事件总线接口
// 提供事件发布订阅机制，实现事件驱动架构
//
// 设计原则：
// 1. 接口定义在领域层
// 2. 实现在基础设施层（内存、Kafka、NATS 等）
// 3. 支持领域事件的异步处理
type EventBus interface {
	// Publish 发布事件
	Publish(event cloudevents.Event) error

	// Subscribe 订阅事件
	// eventType: 事件类型（如 "com.example.user.created"）
	// handler: 事件处理器
	Subscribe(eventType string, handler EventHandler) error
}

// EventHandler 事件处理器接口
type EventHandler interface {
	// Handle 处理事件
	Handle(event cloudevents.Event) error
}
