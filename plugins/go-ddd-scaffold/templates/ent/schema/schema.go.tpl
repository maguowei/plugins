package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// {{ .Entity.Name }} {{ .Entity.NameCN }}的 Ent Schema
// Ent 会根据此 Schema 自动生成数据库表结构和 CRUD 代码
type {{ .Entity.Name }} struct {
	ent.Schema
}

// Fields 字段定义
func ({{ .Entity.Name }}) Fields() []ent.Field {
	return []ent.Field{
		// ID 字段（UUID）
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			StorageKey("id").
			Immutable().
			Comment("{{ .Entity.NameCN }} ID"),

		{{- range .Entity.EntFields }}
		// {{ .Comment }}
		{{ .FieldDefinition }},
		{{- end }}

		// 时间戳字段
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("创建时间"),

		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Comment("更新时间"),
	}
}

// Edges 边（关联关系）定义
func ({{ .Entity.Name }}) Edges() []ent.Edge {
	return []ent.Edge{
		// 示例：一对多关系
		// edge.To("orders", Order.Type).
		//     Comment("用户的订单"),
	}
}

// Indexes 索引定义
func ({{ .Entity.Name }}) Indexes() []ent.Index {
	return []ent.Index{
		{{- range .Entity.EntIndexes }}
		// {{ .Comment }}
		{{ .IndexDefinition }},
		{{- end }}
	}
}

// Hooks 钩子函数
// 可以在数据库操作前后执行自定义逻辑
// func ({{ .Entity.Name }}) Hooks() []ent.Hook {
//     return []ent.Hook{
//         // 示例：创建前验证
//         hook.On(
//             func(next ent.Mutator) ent.Mutator {
//                 return hook.{{ .Entity.Name }}Func(func(ctx context.Context, m *ent.{{ .Entity.Name }}Mutation) (ent.Value, error) {
//                     // 验证逻辑
//                     return next.Mutate(ctx, m)
//                 })
//             },
//             ent.OpCreate,
//         ),
//     }
// }

// Mixin 混入
// 可以复用通用字段定义
// func ({{ .Entity.Name }}) Mixin() []ent.Mixin {
//     return []ent.Mixin{
//         // 示例：软删除混入
//         // mixin.SoftDelete{},
//     }
// }

// Policy 策略
// 定义访问控制规则
// func ({{ .Entity.Name }}) Policy() ent.Policy {
//     return privacy.Policy{
//         Mutation: privacy.MutationPolicy{
//             // 示例：只允许创建者更新
//             // rule.AllowIfOwner(),
//         },
//         Query: privacy.QueryPolicy{
//             // 示例：只能查询自己的数据
//             // rule.AllowIfOwner(),
//         },
//     }
// }
