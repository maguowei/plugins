package valueobject

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNewEmail(t *testing.T) {
	testCases := []struct {
		name      string
		input     string
		expected  string
		wantError bool
	}{
		{
			name:      "有效邮箱",
			input:     "test@example.com",
			expected:  "test@example.com",
			wantError: false,
		},
		{
			name:      "有效邮箱 - 带数字",
			input:     "user123@test.com",
			expected:  "user123@test.com",
			wantError: false,
		},
		{
			name:      "有效邮箱 - 带点号",
			input:     "user.name@example.co.uk",
			expected:  "user.name@example.co.uk",
			wantError: false,
		},
		{
			name:      "有效邮箱 - 大写转小写",
			input:     "Test@Example.COM",
			expected:  "test@example.com",
			wantError: false,
		},
		{
			name:      "有效邮箱 - 去除空格",
			input:     "  test@example.com  ",
			expected:  "test@example.com",
			wantError: false,
		},
		{
			name:      "无效邮箱 - 空字符串",
			input:     "",
			wantError: true,
		},
		{
			name:      "无效邮箱 - 只有空格",
			input:     "   ",
			wantError: true,
		},
		{
			name:      "无效邮箱 - 缺少 @",
			input:     "testexample.com",
			wantError: true,
		},
		{
			name:      "无效邮箱 - 缺少域名",
			input:     "test@",
			wantError: true,
		},
		{
			name:      "无效邮箱 - 缺少顶级域",
			input:     "test@example",
			wantError: true,
		},
		{
			name:      "无效邮箱 - 缺少用户名",
			input:     "@example.com",
			wantError: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			email, err := NewEmail(tc.input)

			if tc.wantError {
				assert.Error(t, err)
				assert.Equal(t, "", email.Value())
			} else {
				require.NoError(t, err)
				assert.Equal(t, tc.expected, email.Value())
				assert.Equal(t, tc.expected, email.String())
			}
		})
	}
}

func TestEmail_Equals(t *testing.T) {
	email1, _ := NewEmail("test@example.com")
	email2, _ := NewEmail("test@example.com")
	email3, _ := NewEmail("other@example.com")

	// 相同值的 Email 相等
	assert.True(t, email1.Equals(email2))

	// 不同值的 Email 不相等
	assert.False(t, email1.Equals(email3))

	// 与自己相等
	assert.True(t, email1.Equals(email1))
}

func TestEmail_Immutability(t *testing.T) {
	// 测试值对象的不可变性
	email, _ := NewEmail("test@example.com")
	originalValue := email.Value()

	// Value Object 没有 setter 方法，无法修改
	// 这个测试确保 Value() 方法返回的是副本或不可变值

	retrievedValue := email.Value()
	assert.Equal(t, originalValue, retrievedValue)
}
