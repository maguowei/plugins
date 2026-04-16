package valueobject_test

import (
	"testing"

	"github.com/test/mysql-test/internal/app/domain/valueobject"
	"github.com/stretchr/testify/assert"
)

func TestNewEmail_Valid(t *testing.T) {
	email, err := valueobject.NewEmail("test@example.com")
	assert.NoError(t, err)
	assert.Equal(t, "test@example.com", email.Value())
}

func TestNewEmail_Empty(t *testing.T) {
	_, err := valueobject.NewEmail("")
	assert.Error(t, err)
}

func TestNewEmail_InvalidFormat(t *testing.T) {
	_, err := valueobject.NewEmail("not-an-email")
	assert.Error(t, err)
}

func TestNewEmail_Normalized(t *testing.T) {
	email, err := valueobject.NewEmail("  TEST@Example.COM  ")
	assert.NoError(t, err)
	assert.Equal(t, "test@example.com", email.Value())
}

func TestEmail_Equals(t *testing.T) {
	e1, _ := valueobject.NewEmail("test@example.com")
	e2, _ := valueobject.NewEmail("test@example.com")
	assert.True(t, e1.Equals(e2))
}
