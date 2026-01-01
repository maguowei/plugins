package valueobject

import (
	"errors"
	"regexp"
	"strings"
)

// Email 邮箱值对象
// Value Object 特征：不可变、无唯一标识、基于值相等
type Email struct {
	value string
}

// NewEmail 创建邮箱值对象
// 构造函数是创建值对象的唯一方式，强制验证业务规则
func NewEmail(email string) (Email, error) {
	// 业务规则验证
	email = strings.TrimSpace(strings.ToLower(email))

	if email == "" {
		return Email{}, errors.New("email cannot be empty")
	}

	if !isValidEmail(email) {
		return Email{}, errors.New("invalid email format")
	}

	return Email{value: email}, nil
}

// Value 获取邮箱值
func (e Email) Value() string {
	return e.value
}

// Equals 判断两个邮箱是否相等
// Value Object 的相等性基于属性值，而不是标识
func (e Email) Equals(other Email) bool {
	return e.value == other.value
}

// String 字符串表示
func (e Email) String() string {
	return e.value
}

// isValidEmail 验证邮箱格式
func isValidEmail(email string) bool {
	// RFC 5322 简化正则表达式
	regex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	return regex.MatchString(email)
}
