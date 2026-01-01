version: '3.8'

services:
  # {{ .Project.Name }} 应用服务
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: {{ .Project.Name }}-app
    ports:
      - "{{ .Server.Port }}:{{ .Server.Port }}"
    environment:
      # 服务器配置
      - APP_SERVER_PORT={{ .Server.Port }}
      - APP_SERVER_MODE=release

      {{- if eq .Database.Driver "mysql" }}
      # 数据库配置（MySQL）
      - APP_DATABASE_DRIVER=mysql
      - APP_DATABASE_DSN=root:password@tcp(mysql:3306)/{{ .Project.Name }}?parseTime=true&charset=utf8mb4
      {{- else if eq .Database.Driver "sqlite3" }}
      # 数据库配置（SQLite）
      - APP_DATABASE_DRIVER=sqlite3
      - APP_DATABASE_DSN=file:/data/{{ .Project.Name }}.db?cache=shared&mode=rwc
      {{- end }}

      # 日志配置
      - APP_LOGGING_LEVEL=info
      - APP_LOGGING_FORMAT=json

      # Prometheus 配置
      - APP_PROMETHEUS_ENABLED=true
      - APP_PROMETHEUS_PATH=/metrics

    {{- if eq .Database.Driver "mysql" }}
    depends_on:
      mysql:
        condition: service_healthy
    {{- end }}

    {{- if eq .Database.Driver "sqlite3" }}
    volumes:
      - app-data:/data
    {{- end }}

    networks:
      - {{ .Project.Name }}-network

    restart: unless-stopped

    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:{{ .Server.Port }}/health"]
      interval: 30s
      timeout: 3s
      start_period: 10s
      retries: 3

  {{- if eq .Database.Driver "mysql" }}
  # MySQL 数据库服务
  mysql:
    image: mysql:8.0
    container_name: {{ .Project.Name }}-mysql
    environment:
      - MYSQL_ROOT_PASSWORD=password
      - MYSQL_DATABASE={{ .Project.Name }}
      - MYSQL_CHARACTER_SET_SERVER=utf8mb4
      - MYSQL_COLLATION_SERVER=utf8mb4_unicode_ci
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - {{ .Project.Name }}-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-ppassword"]
      interval: 10s
      timeout: 3s
      start_period: 30s
      retries: 5
  {{- end }}

# 网络配置
networks:
  {{ .Project.Name }}-network:
    driver: bridge

# 卷配置
volumes:
  {{- if eq .Database.Driver "mysql" }}
  mysql-data:
    driver: local
  {{- else if eq .Database.Driver "sqlite3" }}
  app-data:
    driver: local
  {{- end }}
