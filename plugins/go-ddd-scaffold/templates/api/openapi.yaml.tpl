openapi: 3.0.3

info:
  title: {{ .Project.Name }} API
  description: |
    {{ .Project.Name }} RESTful API 文档

    采用 DDD 四层架构设计，提供完整的 CRUD 操作。

    ## 认证
    目前未启用认证，后续可添加 JWT 或 OAuth2。

    ## 错误处理
    所有错误响应遵循统一格式：
    ```json
    {
      "error": "error_code",
      "message": "错误描述"
    }
    ```

    ## 分页
    列表接口支持分页参数：
    - `page`: 页码（从 1 开始）
    - `page_size`: 每页数量（默认 20，最大 100）
  version: 1.0.0
  contact:
    name: API Support
    email: support@example.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: http://localhost:{{ .Server.Port }}/api/v1
    description: 本地开发环境
  - url: https://api.example.com/api/v1
    description: 生产环境

tags:
  - name: health
    description: 健康检查
  {{- if .IncludeExamples }}
  - name: users
    description: {{ .Entity.NameCN }}管理
  {{- end }}

paths:
  /health:
    get:
      tags:
        - health
      summary: 健康检查
      description: 检查服务是否正常运行
      operationId: healthCheck
      responses:
        '200':
          description: 服务正常
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: ok
                  service:
                    type: string
                    example: {{ .Project.Name }}

  {{- if .IncludeExamples }}
  /users:
    get:
      tags:
        - users
      summary: 获取{{ .Entity.NameCN }}列表
      description: 获取所有{{ .Entity.NameCN }}，支持分页
      operationId: listUsers
      parameters:
        - name: page
          in: query
          description: 页码（从 1 开始）
          required: false
          schema:
            type: integer
            minimum: 1
            default: 1
        - name: page_size
          in: query
          description: 每页数量
          required: false
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
      responses:
        '200':
          description: 成功返回{{ .Entity.NameCN }}列表
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserListResponse'
        '400':
          description: 请求参数错误
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: 服务器内部错误
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

    post:
      tags:
        - users
      summary: 创建{{ .Entity.NameCN }}
      description: 创建新的{{ .Entity.NameCN }}
      operationId: createUser
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: {{ .Entity.NameCN }}创建成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserResponse'
        '400':
          description: 请求参数错误
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: 服务器内部错误
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /users/{id}:
    get:
      tags:
        - users
      summary: 获取{{ .Entity.NameCN }}详情
      description: 根据 ID 获取{{ .Entity.NameCN }}详情
      operationId: getUser
      parameters:
        - name: id
          in: path
          description: {{ .Entity.NameCN }} ID（UUID 格式）
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: 成功返回{{ .Entity.NameCN }}详情
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserResponse'
        '400':
          description: 请求参数错误（ID 格式不正确）
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: {{ .Entity.NameCN }}不存在
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: 服务器内部错误
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

    put:
      tags:
        - users
      summary: 更新{{ .Entity.NameCN }}
      description: 根据 ID 更新{{ .Entity.NameCN }}信息
      operationId: updateUser
      parameters:
        - name: id
          in: path
          description: {{ .Entity.NameCN }} ID（UUID 格式）
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateUserRequest'
      responses:
        '200':
          description: {{ .Entity.NameCN }}更新成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserResponse'
        '400':
          description: 请求参数错误
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: {{ .Entity.NameCN }}不存在
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: 服务器内部错误
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

    delete:
      tags:
        - users
      summary: 删除{{ .Entity.NameCN }}
      description: 根据 ID 删除{{ .Entity.NameCN }}
      operationId: deleteUser
      parameters:
        - name: id
          in: path
          description: {{ .Entity.NameCN }} ID（UUID 格式）
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '204':
          description: 删除成功，无内容返回
        '400':
          description: 请求参数错误（ID 格式不正确）
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: {{ .Entity.NameCN }}不存在
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: 服务器内部错误
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
  {{- end }}

components:
  schemas:
    {{- if .IncludeExamples }}
    # {{ .Entity.NameCN }}相关 Schema
    UserResponse:
      type: object
      properties:
        id:
          type: string
          format: uuid
          description: {{ .Entity.NameCN }} ID
          example: "550e8400-e29b-41d4-a716-446655440000"
        email:
          type: string
          format: email
          description: {{ .Entity.NameCN }}邮箱
          example: "user@example.com"
        name:
          type: string
          description: {{ .Entity.NameCN }}名称
          example: "张三"
        created_at:
          type: string
          format: date-time
          description: 创建时间
          example: "2024-01-01T00:00:00Z"
        updated_at:
          type: string
          format: date-time
          description: 更新时间
          example: "2024-01-01T00:00:00Z"

    CreateUserRequest:
      type: object
      required:
        - email
        - name
      properties:
        email:
          type: string
          format: email
          description: {{ .Entity.NameCN }}邮箱
          example: "user@example.com"
        name:
          type: string
          minLength: 1
          maxLength: 100
          description: {{ .Entity.NameCN }}名称
          example: "张三"

    UpdateUserRequest:
      type: object
      required:
        - name
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
          description: {{ .Entity.NameCN }}名称
          example: "李四"

    UserListResponse:
      type: object
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/UserResponse'
          description: {{ .Entity.NameCN }}列表
        total:
          type: integer
          format: int64
          description: 总数量
          example: 100
        page:
          type: integer
          description: 当前页码
          example: 1
        page_size:
          type: integer
          description: 每页数量
          example: 20
        total_pages:
          type: integer
          description: 总页数
          example: 5
    {{- end }}

    # 通用错误响应
    ErrorResponse:
      type: object
      properties:
        error:
          type: string
          description: 错误码
          example: "invalid_request"
        message:
          type: string
          description: 错误消息
          example: "请求参数格式错误"
