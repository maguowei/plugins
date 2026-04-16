package valueobject

import (
	"errors"
	"strings"
)

// Email 值对象（不可变）
type Email struct {
	value string
}

// NewEmail 创建 Email，强制验证格式
func NewEmail(raw string) (Email, error) {
	email := strings.TrimSpace(strings.ToLower(raw))
	if email == "" {
		return Email{}, errors.New("邮箱不能为空")
	}
	if !strings.Contains(email, "@") || !strings.Contains(email, ".") {
		return Email{}, errors.New("邮箱格式无效")
	}
	return Email{value: email}, nil
}

func (e Email) Value() string          { return e.value }
func (e Email) String() string          { return e.value }
func (e Email) Equals(other Email) bool { return e.value == other.value }
