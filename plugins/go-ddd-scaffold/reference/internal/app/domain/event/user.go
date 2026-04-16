package event

import (
	"time"

	cloudevents "github.com/cloudevents/sdk-go/v2"
	"github.com/google/uuid"
)

// UserCreated 用户创建事件
type UserCreated struct {
	UserID    uuid.UUID `json:"user_id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

func NewUserCreated(userID uuid.UUID, email, name string) UserCreated {
	return UserCreated{
		UserID:    userID,
		Email:     email,
		Name:      name,
		CreatedAt: time.Now(),
	}
}

func (e UserCreated) ToCloudEvent() cloudevents.Event {
	ce := cloudevents.NewEvent()
	ce.SetID(uuid.New().String())
	ce.SetSource("my-service")
	ce.SetType("com.example.user.created")
	ce.SetTime(e.CreatedAt)
	_ = ce.SetData(cloudevents.ApplicationJSON, e)
	return ce
}

// UserUpdated 用户更新事件
type UserUpdated struct {
	UserID    uuid.UUID `json:"user_id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	UpdatedAt time.Time `json:"updated_at"`
}

func NewUserUpdated(userID uuid.UUID, email, name string) UserUpdated {
	return UserUpdated{
		UserID:    userID,
		Email:     email,
		Name:      name,
		UpdatedAt: time.Now(),
	}
}

func (e UserUpdated) ToCloudEvent() cloudevents.Event {
	ce := cloudevents.NewEvent()
	ce.SetID(uuid.New().String())
	ce.SetSource("my-service")
	ce.SetType("com.example.user.updated")
	ce.SetTime(e.UpdatedAt)
	_ = ce.SetData(cloudevents.ApplicationJSON, e)
	return ce
}
