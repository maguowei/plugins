package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// User Ent Schema
type User struct {
	ent.Schema
}

func (User) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).Default(uuid.New),
		field.String("email").Unique().NotEmpty(),
		field.String("name").NotEmpty(),
		field.Time("created_at").Immutable(),
		field.Time("updated_at"),
	}
}

func (User) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("email").Unique(),
	}
}

func (User) Edges() []ent.Edge {
	return nil
}
