module {{ .GoModule }}

go {{ .Go.Version }}

require (
{{- range .Go.Dependencies }}
	{{ .Name }} {{ .Version }}
{{- end }}
{{- if .GoDependencies }}
{{- range .GoDependencies }}
	{{ .Name }} {{ .Version }}
{{- end }}
{{- end }}
)
