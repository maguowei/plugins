# 安全性审查检查清单

基于 OWASP Top 10 和常见安全最佳实践。

## 1. 注入攻击 (Injection)

### ✅ 检查项

- [ ] **SQL 注入防护**
  - 使用参数化查询
  - 不拼接SQL字符串

  ```go
  // ❌ SQL 注入风险
  query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)

  // ✅ 参数化查询
  query := "SELECT * FROM users WHERE id = ?"
  db.QueryRow(query, userID)
  ```

  ```typescript
  // ✅ 使用 ORM 或查询构建器
  const user = await db.user.findUnique({
      where: { id: userId }
  });
  ```

- [ ] **NoSQL 注入防护**
  - 验证和清理输入
  - 使用 ORM/ODM

- [ ] **命令注入防护**
  - 避免执行用户输入的命令
  - 使用白名单验证

  ```go
  // ❌ 命令注入风险
  cmd := exec.Command("sh", "-c", userInput)

  // ✅ 使用受控参数
  cmd := exec.Command("ls", "-l", filepath.Clean(userInput))
  ```

## 2. 跨站脚本 (XSS)

### ✅ 检查项

- [ ] **输出编码**
  - HTML 编码用户输入
  - 使用框架的自动编码功能

  ```typescript
  // ❌ 未编码，XSS 风险
  element.innerHTML = userInput;

  // ✅ React 自动编码
  <div>{userInput}</div>

  // ❌ dangerouslySetInnerHTML 需谨慎
  <div dangerouslySetInnerHTML={{ __html: untrustedHTML }} />

  // ✅ 使用 DOMPurify 清理
  import DOMPurify from 'dompurify';
  <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(html) }} />
  ```

- [ ] **Content Security Policy (CSP)**
  - 设置 CSP 头
  - 限制脚本来源

- [ ] **避免 eval()**
  - 不使用 eval()、new Function()
  - 不执行用户输入的代码

## 3. 身份验证和会话管理

### ✅ 检查项

- [ ] **密码存储**
  - 使用 bcrypt、scrypt 或 Argon2
  - 不明文存储密码
  - 加盐哈希

  ```go
  // ✅ 使用 bcrypt
  import "golang.org/x/crypto/bcrypt"

  hashedPassword, err := bcrypt.GenerateFromPassword(
      []byte(password),
      bcrypt.DefaultCost,
  )

  // 验证
  err = bcrypt.CompareHashAndPassword(hashedPassword, []byte(password))
  ```

- [ ] **会话管理**
  - 使用安全的会话 ID
  - 会话过期时间合理
  - 登出时销毁会话

  ```go
  // 设置 session cookie
  http.SetCookie(w, &http.Cookie{
      Name:     "session_id",
      Value:    sessionID,
      HttpOnly: true,  // 防止 XSS
      Secure:   true,  // 仅 HTTPS
      SameSite: http.SameSiteStrictMode,  // CSRF 防护
      MaxAge:   3600,  // 1小时
  })
  ```

- [ ] **JWT 使用**
  - 签名验证
  - 过期时间设置
  - 敏感信息不放 payload

  ```typescript
  // ✅ JWT 配置
  const token = jwt.sign(
      { userId: user.id },  // payload - 不包含敏感信息
      process.env.JWT_SECRET!,  // 密钥
      {
          expiresIn: '1h',  // 过期时间
          algorithm: 'HS256'
      }
  );

  // 验证
  try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET!);
  } catch (error) {
      // 无效或过期的 token
  }
  ```

## 4. 访问控制

### ✅ 检查项

- [ ] **权限检查**
  - 每个操作都检查权限
  - 不仅在前端检查，后端也要检查

  ```go
  // ✅ 后端权限检查
  func DeleteUser(w http.ResponseWriter, r *http.Request) {
      userID := getUserID(r)
      targetID := r.URL.Query().Get("id")

      // 检查权限
      if !hasPermission(userID, "user:delete", targetID) {
          http.Error(w, "Forbidden", http.StatusForbidden)
          return
      }

      // 执行删除
  }
  ```

- [ ] **对象级访问控制**
  - 验证用户是否有权访问特定资源
  - 防止横向越权

  ```go
  // ✅ 检查资源所有权
  func GetOrder(userID, orderID string) (*Order, error) {
      order, err := db.GetOrder(orderID)
      if err != nil {
          return nil, err
      }

      // 检查所有权
      if order.UserID != userID {
          return nil, errors.New("access denied")
      }

      return order, nil
  }
  ```

## 5. 安全配置错误

### ✅ 检查项

- [ ] **敏感信息不硬编码**
  - 使用环境变量
  - 使用配置管理服务

  ```go
  // ❌ 硬编码
  const APIKey = "sk_live_1234567890"

  // ✅ 环境变量
  apiKey := os.Getenv("API_KEY")
  if apiKey == "" {
      log.Fatal("API_KEY not set")
  }
  ```

- [ ] **错误信息不泄露**
  - 生产环境不返回详细错误
  - 记录日志但不暴露给用户

  ```go
  // ❌ 泄露内部信息
  if err != nil {
      http.Error(w, err.Error(), http.StatusInternalServerError)
  }

  // ✅ 通用错误信息
  if err != nil {
      log.Printf("Database error: %v", err)
      http.Error(w, "Internal server error", http.StatusInternalServerError)
  }
  ```

- [ ] **HTTPS 强制**
  - 所有通信使用 HTTPS
  - 重定向 HTTP 到 HTTPS

- [ ] **安全响应头**

  ```go
  // ✅ 设置安全头
  w.Header().Set("X-Content-Type-Options", "nosniff")
  w.Header().Set("X-Frame-Options", "DENY")
  w.Header().Set("X-XSS-Protection", "1; mode=block")
  w.Header().Set("Strict-Transport-Security", "max-age=31536000")
  w.Header().Set("Content-Security-Policy", "default-src 'self'")
  ```

## 6. 敏感数据暴露

### ✅ 检查项

- [ ] **数据加密**
  - 传输加密（HTTPS）
  - 静态数据加密（数据库、文件）

- [ ] **日志安全**
  - 不记录敏感信息（密码、Token、信用卡）
  - 日志访问权限控制

  ```go
  // ❌ 记录敏感信息
  log.Printf("User login: %s, password: %s", email, password)

  // ✅ 不记录敏感信息
  log.Printf("User login attempt: %s", email)
  ```

- [ ] **API 响应不包含敏感信息**

  ```go
  // ❌ 暴露密码哈希
  type User struct {
      ID       string `json:"id"`
      Email    string `json:"email"`
      Password string `json:"password"` // 不应该返回
  }

  // ✅ 使用 DTO
  type UserDTO struct {
      ID    string `json:"id"`
      Email string `json:"email"`
      Name  string `json:"name"`
  }
  ```

## 7. CSRF 防护

### ✅ 检查项

- [ ] **CSRF Token**
  - 状态改变操作使用 CSRF token
  - 验证 token

  ```typescript
  // 前端：发送 CSRF token
  fetch('/api/update', {
      method: 'POST',
      headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': getCsrfToken()
      },
      body: JSON.stringify(data)
  });
  ```

  ```go
  // 后端：验证 CSRF token
  func ValidateCSRF(r *http.Request) bool {
      token := r.Header.Get("X-CSRF-Token")
      sessionToken := getSessionCSRFToken(r)
      return token != "" && token == sessionToken
  }
  ```

- [ ] **SameSite Cookie**
  - 设置 SameSite=Strict 或 Lax

## 8. 输入验证

### ✅ 检查项

- [ ] **白名单验证**
  - 使用白名单而非黑名单
  - 验证数据类型、格式、范围

  ```go
  // ✅ 白名单验证
  func ValidateRole(role string) error {
      validRoles := map[string]bool{
          "admin": true,
          "user":  true,
          "guest": true,
      }

      if !validRoles[role] {
          return errors.New("invalid role")
      }
      return nil
  }
  ```

- [ ] **文件上传验证**
  - 验证文件类型（不仅依赖扩展名）
  - 限制文件大小
  - 扫描恶意软件

  ```go
  func ValidateUpload(file multipart.File, header *multipart.FileHeader) error {
      // 限制大小（5MB）
      if header.Size > 5*1024*1024 {
          return errors.New("file too large")
      }

      // 验证 MIME 类型
      buffer := make([]byte, 512)
      file.Read(buffer)
      file.Seek(0, 0)

      mimeType := http.DetectContentType(buffer)
      allowedTypes := []string{"image/jpeg", "image/png", "image/gif"}

      for _, allowed := range allowedTypes {
          if mimeType == allowed {
              return nil
          }
      }

      return errors.New("invalid file type")
  }
  ```

- [ ] **URL 验证**
  - 验证 URL 格式
  - 防止 SSRF

  ```go
  func ValidateURL(rawURL string) error {
      u, err := url.Parse(rawURL)
      if err != nil {
          return err
      }

      // 禁止私有 IP
      if u.Hostname() == "localhost" || u.Hostname() == "127.0.0.1" {
          return errors.New("private IP not allowed")
      }

      // 只允许 HTTPS
      if u.Scheme != "https" {
          return errors.New("only HTTPS allowed")
      }

      return nil
  }
  ```

## 9. 速率限制

### ✅ 检查项

- [ ] **API 速率限制**
  - 防止暴力破解
  - 防止 DoS

  ```go
  // ✅ 使用速率限制中间件
  import "golang.org/x/time/rate"

  var limiter = rate.NewLimiter(rate.Limit(10), 20) // 10 req/s, burst 20

  func RateLimitMiddleware(next http.Handler) http.Handler {
      return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
          if !limiter.Allow() {
              http.Error(w, "Too many requests", http.StatusTooManyRequests)
              return
          }
          next.ServeHTTP(w, r)
      })
  }
  ```

- [ ] **登录尝试限制**
  - 限制登录失败次数
  - 账户锁定机制

## 10. 依赖安全

### ✅ 检查项

- [ ] **依赖更新**
  - 使用最新的稳定版本
  - 定期更新依赖

- [ ] **漏洞扫描**
  - 使用 npm audit、go mod verify
  - 集成到 CI/CD

  ```bash
  # Go
  go mod verify
  go list -json -m all | nancy sleuth

  # Node.js
  npm audit
  npm audit fix
  ```

- [ ] **依赖来源**
  - 使用可信的包源
  - 验证包完整性

## 11. 服务端请求伪造 (SSRF)

### ✅ 检查项

- [ ] **URL 白名单**
  - 限制可访问的域名
  - 验证 URL

- [ ] **禁止访问内网**
  - 过滤私有 IP 范围
  - 禁止访问 metadata 服务

## 12. 日志和监控

### ✅ 检查项

- [ ] **安全事件记录**
  - 登录失败
  - 权限拒绝
  - 异常访问

- [ ] **日志审计**
  - 定期审查日志
  - 设置告警

## 严重性评估

| 漏洞类型 | 严重性 |
|---------|--------|
| SQL 注入 | 严重 |
| XSS | 严重 |
| 认证绕过 | 严重 |
| 敏感信息泄露 | 高 |
| CSRF | 高 |
| 权限控制缺失 | 高 |
| 配置错误 | 中 |
| 缺少速率限制 | 中 |
| 依赖漏洞 | 中-高 |

## 参考资源

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
