# {{ .Project.Name }} 配置文件
# 配置加载优先级：环境变量 > 配置文件
# 环境变量格式：APP_<SECTION>_<KEY>，例如 APP_SERVER_PORT=8080

# 服务器配置
server:
  # HTTP 服务器端口
  port: "{{ .Server.Port }}"

  # 运行模式：debug, release, test
  mode: "{{ .Server.Mode }}"

  # 读取超时时间
  read_timeout: "30s"

  # 写入超时时间
  write_timeout: "30s"

# 数据库配置
database:
  # 数据库驱动：mysql, sqlite3, postgres
  driver: "{{ .Database.Driver }}"

  # 数据源名称（DSN）
  {{- if eq .Database.Driver "mysql" }}
  # MySQL DSN 格式：user:password@tcp(host:port)/dbname?parseTime=true
  dsn: "{{ .Database.DSN }}"
  {{- else if eq .Database.Driver "sqlite3" }}
  # SQLite DSN 格式：file:dbname.db?cache=shared&mode=rwc
  dsn: "{{ .Database.DSN }}"
  {{- else }}
  dsn: "{{ .Database.DSN }}"
  {{- end }}

  # 最大打开连接数
  max_open_conns: {{ .Database.MaxOpenConns }}

  # 最大空闲连接数
  max_idle_conns: {{ .Database.MaxIdleConns }}

  # 连接最大生命周期
  conn_max_lifetime: "{{ .Database.ConnMaxLifetime }}"

# 日志配置
logging:
  # 日志级别：debug, info, warn, error
  level: "{{ .Logging.Level }}"

  # 日志格式：text, json
  format: "{{ .Logging.Format }}"

# Sentry 配置（错误追踪）
sentry:
  # Sentry DSN（为空则禁用 Sentry）
  # 从 Sentry 项目设置中获取
  dsn: ""

  # 环境标识：development, staging, production
  environment: "development"

  # 性能监控采样率（0.0 - 1.0）
  # 0.0 = 不采样，1.0 = 采样所有请求
  # 生产环境建议设置为 0.1 - 0.2
  traces_sample_rate: 0.0

# Prometheus 配置（指标监控）
prometheus:
  # 是否启用 Prometheus metrics 端点
  enabled: true

  # Metrics 端点路径
  path: "/metrics"
