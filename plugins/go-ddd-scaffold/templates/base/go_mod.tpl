module {{ .GoModule }}

go {{ .Go.Version }}

require (
{{- range .Go.Dependencies }}
	{{ .Name }} {{ .Version }}
{{- end }}
{{- if eq .Database "mysql" }}
{{- range .DatabaseConfig.GoDepencies }}
	{{ .Name }} {{ .Version }}
{{- end }}
{{- else if eq .Database "sqlite" }}
{{- range .DatabaseConfig.GoDependencies }}
	{{ .Name }} {{ .Version }}
{{- end }}
{{- end }}
)
