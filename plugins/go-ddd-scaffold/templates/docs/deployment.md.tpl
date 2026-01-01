# {{ .Project.Name }} 部署指南

## 目录

- [部署方式](#部署方式)
- [Docker 部署](#docker-部署)
- [Kubernetes 部署](#kubernetes-部署)
- [环境变量配置](#环境变量配置)
- [监控和告警](#监控和告警)
- [备份和恢复](#备份和恢复)

## 部署方式

本项目支持多种部署方式：

1. **Docker Compose**：适合小规模部署和开发环境
2. **Docker**：单容器部署
3. **Kubernetes**：适合生产环境和大规模部署
4. **二进制文件**：直接在服务器上运行编译好的二进制文件

## Docker 部署

### 使用 Docker Compose（推荐用于开发/测试环境）

#### 1. 准备配置文件

```bash
# 复制并编辑配置文件
cp configs/config.yaml configs/config.prod.yaml
```

#### 2. 修改 Docker Compose 配置

确保 `docker-compose.yml` 中的环境变量适合生产环境：

```yaml
environment:
  - APP_SERVER_MODE=release
  - APP_LOGGING_LEVEL=info
  - APP_LOGGING_FORMAT=json
  {{- if eq .Database.Driver "mysql" }}
  - APP_DATABASE_DSN=root:your_password@tcp(mysql:3306)/{{ .Project.Name }}?parseTime=true
  {{- end }}
  - APP_SENTRY_DSN=your_sentry_dsn
```

#### 3. 启动服务

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f app

# 停止服务
docker-compose down
```

#### 4. 运行数据库迁移

```bash
docker-compose exec app /app/migrate
```

### 使用 Docker（单容器）

#### 1. 构建镜像

```bash
# 构建镜像
docker build -t {{ .Project.Name }}:latest .

# 或指定版本
docker build -t {{ .Project.Name }}:v1.0.0 .
```

#### 2. 运行容器

```bash
docker run -d \
  --name {{ .Project.Name }}-app \
  -p {{ .Server.Port }}:{{ .Server.Port }} \
  -e APP_SERVER_MODE=release \
  -e APP_LOGGING_LEVEL=info \
  {{- if eq .Database.Driver "mysql" }}
  -e APP_DATABASE_DSN="root:password@tcp(mysql:3306)/{{ .Project.Name }}?parseTime=true" \
  {{- else if eq .Database.Driver "sqlite3" }}
  -v /path/to/data:/data \
  -e APP_DATABASE_DSN="file:/data/{{ .Project.Name }}.db?cache=shared&mode=rwc" \
  {{- end }}
  {{ .Project.Name }}:latest
```

#### 3. 查看日志

```bash
docker logs -f {{ .Project.Name }}-app
```

## Kubernetes 部署

### 1. 创建命名空间

```bash
kubectl create namespace {{ .Project.Name }}
```

### 2. 创建 ConfigMap

创建 `k8s/configmap.yaml`：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Project.Name }}-config
  namespace: {{ .Project.Name }}
data:
  APP_SERVER_MODE: "release"
  APP_SERVER_PORT: "{{ .Server.Port }}"
  APP_LOGGING_LEVEL: "info"
  APP_LOGGING_FORMAT: "json"
  {{- if eq .Database.Driver "mysql" }}
  APP_DATABASE_DRIVER: "mysql"
  {{- else if eq .Database.Driver "sqlite3" }}
  APP_DATABASE_DRIVER: "sqlite3"
  {{- end }}
  APP_PROMETHEUS_ENABLED: "true"
  APP_PROMETHEUS_PATH: "/metrics"
```

```bash
kubectl apply -f k8s/configmap.yaml
```

### 3. 创建 Secret

创建 `k8s/secret.yaml`：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Project.Name }}-secret
  namespace: {{ .Project.Name }}
type: Opaque
stringData:
  {{- if eq .Database.Driver "mysql" }}
  APP_DATABASE_DSN: "root:password@tcp(mysql:3306)/{{ .Project.Name }}?parseTime=true"
  {{- else if eq .Database.Driver "sqlite3" }}
  APP_DATABASE_DSN: "file:/data/{{ .Project.Name }}.db?cache=shared&mode=rwc"
  {{- end }}
  APP_SENTRY_DSN: "your_sentry_dsn_here"
```

```bash
kubectl apply -f k8s/secret.yaml
```

### 4. 创建 Deployment

创建 `k8s/deployment.yaml`：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Project.Name }}
  namespace: {{ .Project.Name }}
spec:
  replicas: 3
  selector:
    matchLabels:
      app: {{ .Project.Name }}
  template:
    metadata:
      labels:
        app: {{ .Project.Name }}
    spec:
      containers:
      - name: {{ .Project.Name }}
        image: {{ .Project.Name }}:latest
        ports:
        - containerPort: {{ .Server.Port }}
        envFrom:
        - configMapRef:
            name: {{ .Project.Name }}-config
        - secretRef:
            name: {{ .Project.Name }}-secret
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: {{ .Server.Port }}
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: {{ .Server.Port }}
          initialDelaySeconds: 5
          periodSeconds: 10
```

```bash
kubectl apply -f k8s/deployment.yaml
```

### 5. 创建 Service

创建 `k8s/service.yaml`：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Project.Name }}
  namespace: {{ .Project.Name }}
spec:
  selector:
    app: {{ .Project.Name }}
  ports:
  - protocol: TCP
    port: 80
    targetPort: {{ .Server.Port }}
  type: LoadBalancer
```

```bash
kubectl apply -f k8s/service.yaml
```

### 6. 创建 Ingress（可选）

创建 `k8s/ingress.yaml`：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Project.Name }}
  namespace: {{ .Project.Name }}
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: {{ .Project.Name }}-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{ .Project.Name }}
            port:
              number: 80
```

```bash
kubectl apply -f k8s/ingress.yaml
```

## 环境变量配置

### 必需的环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `APP_SERVER_PORT` | 服务器端口 | `8080` |
| `APP_DATABASE_DRIVER` | 数据库驱动 | `mysql` 或 `sqlite3` |
| `APP_DATABASE_DSN` | 数据库连接字符串 | 见下方 |

{{- if eq .Database.Driver "mysql" }}
### MySQL DSN 格式

```
用户名:密码@tcp(主机:端口)/数据库名?parseTime=true&charset=utf8mb4&loc=Local
```

示例：
```
root:password@tcp(localhost:3306)/{{ .Project.Name }}?parseTime=true&charset=utf8mb4&loc=Local
```
{{- else if eq .Database.Driver "sqlite3" }}
### SQLite DSN 格式

```
file:文件路径?cache=shared&mode=rwc&_journal_mode=WAL
```

示例：
```
file:/data/{{ .Project.Name }}.db?cache=shared&mode=rwc&_journal_mode=WAL
```
{{- end }}

### 可选的环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `APP_SERVER_MODE` | 运行模式 | `release` |
| `APP_LOGGING_LEVEL` | 日志级别 | `info` |
| `APP_LOGGING_FORMAT` | 日志格式 | `json` |
| `APP_SENTRY_DSN` | Sentry DSN | 空（禁用）|
| `APP_SENTRY_ENVIRONMENT` | Sentry 环境 | `production` |
| `APP_SENTRY_TRACES_SAMPLE_RATE` | Sentry 采样率 | `0.1` |
| `APP_PROMETHEUS_ENABLED` | 启用 Prometheus | `true` |
| `APP_PROMETHEUS_PATH` | Metrics 路径 | `/metrics` |

## 监控和告警

### Prometheus 监控

应用暴露了 Prometheus metrics 端点：`/metrics`

**主要指标**：

- `http_requests_total`: HTTP 请求总数
- `http_request_duration_seconds`: HTTP 请求延迟
- `database_queries_total`: 数据库查询总数
- `database_query_duration_seconds`: 数据库查询延迟
- `business_events_total`: 业务事件总数

**配置 Prometheus**（`prometheus.yml`）：

```yaml
scrape_configs:
  - job_name: '{{ .Project.Name }}'
    static_configs:
      - targets: ['{{ .Project.Name }}:{{ .Server.Port }}']
```

### Grafana 仪表板

导入以下查询创建仪表板：

```promql
# HTTP 请求 QPS
rate(http_requests_total[5m])

# HTTP 请求 P95 延迟
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# 错误率
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
```

### Sentry 错误追踪

配置 Sentry DSN：

```bash
export APP_SENTRY_DSN="https://xxx@sentry.io/xxx"
export APP_SENTRY_ENVIRONMENT="production"
export APP_SENTRY_TRACES_SAMPLE_RATE="0.1"
```

### 日志聚合

使用 ELK、Loki 或其他日志聚合系统收集 JSON 格式的日志。

**Filebeat 配置示例**：

```yaml
filebeat.inputs:
- type: docker
  containers.ids:
    - '*'
  processors:
    - decode_json_fields:
        fields: ["message"]
        target: ""
```

## 备份和恢复

{{- if eq .Database.Driver "mysql" }}
### MySQL 备份

```bash
# 手动备份
docker exec {{ .Project.Name }}-mysql mysqldump \
  -u root -ppassword {{ .Project.Name }} > backup.sql

# 定时备份（crontab）
0 2 * * * docker exec {{ .Project.Name }}-mysql mysqldump \
  -u root -ppassword {{ .Project.Name }} | gzip > /backup/{{ .Project.Name }}-$(date +\%Y\%m\%d).sql.gz
```

### MySQL 恢复

```bash
# 从备份恢复
docker exec -i {{ .Project.Name }}-mysql mysql \
  -u root -ppassword {{ .Project.Name }} < backup.sql
```
{{- else if eq .Database.Driver "sqlite3" }}
### SQLite 备份

```bash
# 手动备份
cp {{ .Project.Name }}.db {{ .Project.Name }}-backup-$(date +%Y%m%d).db

# 定时备份（crontab）
0 2 * * * cp /data/{{ .Project.Name }}.db /backup/{{ .Project.Name }}-$(date +\%Y\%m\%d).db
```

### SQLite 恢复

```bash
# 从备份恢复
cp {{ .Project.Name }}-backup-20240101.db {{ .Project.Name }}.db
```
{{- end }}

## 性能优化建议

### 1. 数据库连接池

在生产环境中调整连接池参数：

```yaml
database:
  max_open_conns: 25
  max_idle_conns: 25
  conn_max_lifetime: "5m"
```

### 2. 启用 HTTP 压缩

在 Nginx 或 Ingress 前添加 gzip 压缩。

### 3. 设置合理的超时时间

```yaml
server:
  read_timeout: "10s"
  write_timeout: "10s"
```

### 4. 使用 CDN

为静态资源配置 CDN。

## 滚动更新

### Kubernetes 滚动更新

```bash
# 更新镜像
kubectl set image deployment/{{ .Project.Name }} \
  {{ .Project.Name }}={{ .Project.Name }}:v1.0.1 \
  -n {{ .Project.Name }}

# 查看更新状态
kubectl rollout status deployment/{{ .Project.Name }} -n {{ .Project.Name }}

# 回滚
kubectl rollout undo deployment/{{ .Project.Name }} -n {{ .Project.Name }}
```

### Docker Compose 滚动更新

```bash
# 拉取新镜像
docker-compose pull

# 重启服务（零停机）
docker-compose up -d --no-deps --build app
```

## 故障排查

### 1. 查看日志

```bash
# Docker
docker logs {{ .Project.Name }}-app

# Kubernetes
kubectl logs -f deployment/{{ .Project.Name }} -n {{ .Project.Name }}
```

### 2. 进入容器

```bash
# Docker
docker exec -it {{ .Project.Name }}-app sh

# Kubernetes
kubectl exec -it deployment/{{ .Project.Name }} -n {{ .Project.Name }} -- sh
```

### 3. 检查健康状态

```bash
curl http://localhost:{{ .Server.Port }}/health
```

### 4. 查看指标

```bash
curl http://localhost:{{ .Server.Port }}/metrics
```
