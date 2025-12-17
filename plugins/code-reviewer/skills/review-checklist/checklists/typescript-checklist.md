# TypeScript 代码审查检查清单

## 1. 类型定义

### ✅ 检查项

- [ ] **避免使用 `any`**
  - 使用具体类型或 `unknown`
  - 如果必须使用 `any`，添加注释说明原因

  ```typescript
  // ❌ 错误示例
  function processData(data: any) {
      return data.value;
  }

  // ✅ 正确示例
  interface Data {
      value: string;
  }

  function processData(data: Data) {
      return data.value;
  }

  // ✅ 使用 unknown 更安全
  function processUnknown(data: unknown) {
      if (typeof data === 'object' && data !== null && 'value' in data) {
          return (data as Data).value;
      }
  }
  ```

- [ ] **完整的接口定义**
  - 所有属性都有类型
  - 使用可选属性 `?` 而非 `| undefined`

  ```typescript
  // ✅ 正确示例
  interface User {
      id: string;
      name: string;
      email?: string;  // 可选属性
      age: number | null;  // 可以为 null
  }
  ```

- [ ] **使用联合类型和字面量类型**

  ```typescript
  // ✅ 字面量类型
  type Status = 'pending' | 'approved' | 'rejected';

  interface Task {
      id: string;
      status: Status;
  }
  ```

- [ ] **泛型使用恰当**
  - 使用泛型提高代码复用性
  - 泛型命名有意义（不仅仅是 T）

  ```typescript
  // ✅ 正确使用泛型
  interface ApiResponse<TData> {
      code: number;
      message: string;
      data: TData;
  }

  function getData<T>(url: string): Promise<ApiResponse<T>> {
      // ...
  }

  // 使用
  const response = await getData<User[]>('/api/users');
  ```

## 2. 类型安全

### ✅ 检查项

- [ ] **类型断言谨慎使用**
  - 优先使用类型守卫
  - 避免 `as any`

  ```typescript
  // ❌ 不安全的断言
  const value = data as string;

  // ✅ 类型守卫
  function isString(value: unknown): value is string {
      return typeof value === 'string';
  }

  if (isString(data)) {
      // data 在这里是 string 类型
      console.log(data.toUpperCase());
  }
  ```

- [ ] **非空断言谨慎使用**
  - 避免使用 `!` 非空断言
  - 使用可选链 `?.` 和空值合并 `??`

  ```typescript
  // ❌ 不安全
  const name = user!.name;

  // ✅ 安全
  const name = user?.name ?? 'Unknown';
  ```

- [ ] **类型收窄**
  - 使用类型守卫收窄类型

  ```typescript
  function process(value: string | number) {
      if (typeof value === 'string') {
          // value 是 string
          return value.toUpperCase();
      } else {
          // value 是 number
          return value.toFixed(2);
      }
  }
  ```

## 3. 异步处理

### ✅ 检查项

- [ ] **Promise 错误处理**
  - 使用 try-catch 处理 async/await
  - Promise 链使用 .catch()

  ```typescript
  // ✅ async/await with try-catch
  async function fetchUser(id: string): Promise<User> {
      try {
          const response = await fetch(`/api/users/${id}`);
          if (!response.ok) {
              throw new Error(`HTTP error! status: ${response.status}`);
          }
          return await response.json();
      } catch (error) {
          console.error('Failed to fetch user:', error);
          throw error;
      }
  }

  // ✅ Promise 链
  fetchUser(id)
      .then(user => console.log(user))
      .catch(error => console.error(error));
  ```

- [ ] **避免未处理的 Promise**
  - 所有 Promise 都要处理错误
  - 不要忘记 await

  ```typescript
  // ❌ 忘记 await
  async function badExample() {
      fetchUser('123');  // Promise 未被等待
  }

  // ✅ 正确
  async function goodExample() {
      await fetchUser('123');
  }
  ```

- [ ] **正确的返回类型**
  - async 函数返回 Promise

  ```typescript
  // ✅ 正确的类型
  async function getUser(id: string): Promise<User> {
      // ...
  }
  ```

## 4. 函数和方法

### ✅ 检查项

- [ ] **函数签名完整**
  - 参数类型
  - 返回类型

  ```typescript
  // ✅ 完整的函数签名
  function calculateTotal(
      items: Item[],
      discount: number = 0
  ): number {
      // ...
  }
  ```

- [ ] **可选参数和默认值**
  - 可选参数使用 `?`
  - 默认值放在最后

  ```typescript
  function createUser(
      name: string,
      email?: string,
      role: string = 'user'
  ): User {
      // ...
  }
  ```

- [ ] **函数重载**
  - 使用函数重载提供更好的类型推断

  ```typescript
  function format(value: string): string;
  function format(value: number): string;
  function format(value: Date): string;
  function format(value: string | number | Date): string {
      if (typeof value === 'string') return value;
      if (typeof value === 'number') return value.toString();
      return value.toISOString();
  }
  ```

## 5. 类和面向对象

### ✅ 检查项

- [ ] **访问修饰符**
  - 明确使用 public、private、protected
  - 避免过度暴露内部实现

  ```typescript
  class User {
      public readonly id: string;
      private password: string;
      protected createdAt: Date;

      constructor(id: string, password: string) {
          this.id = id;
          this.password = password;
          this.createdAt = new Date();
      }

      public authenticate(pwd: string): boolean {
          return this.password === pwd;
      }
  }
  ```

- [ ] **抽象类和接口**
  - 合理使用抽象类和接口
  - 接口定义契约，类实现行为

  ```typescript
  // 接口定义契约
  interface IRepository<T> {
      findById(id: string): Promise<T | null>;
      save(entity: T): Promise<void>;
  }

  // 抽象类提供通用实现
  abstract class BaseRepository<T> implements IRepository<T> {
      abstract findById(id: string): Promise<T | null>;
      abstract save(entity: T): Promise<void>;

      protected logOperation(op: string): void {
          console.log(`Operation: ${op}`);
      }
  }
  ```

## 6. 模块和导入

### ✅ 检查项

- [ ] **导入路径**
  - 使用路径别名
  - 避免相对路径过深

  ```typescript
  // ❌ 深层相对路径
  import { User } from '../../../domain/entities/User';

  // ✅ 路径别名
  import { User } from '@/domain/entities/User';
  ```

- [ ] **导入组织**
  - 第三方库
  - 内部模块
  - 类型导入

  ```typescript
  // 第三方库
  import React from 'react';
  import { useQuery } from 'react-query';

  // 内部模块
  import { UserService } from '@/services/UserService';
  import { formatDate } from '@/utils/date';

  // 类型导入
  import type { User } from '@/types/User';
  ```

- [ ] **避免循环依赖**
  - 重构代码避免循环导入

## 7. 枚举和常量

### ✅ 检查项

- [ ] **使用枚举或常量对象**
  - 避免魔法值

  ```typescript
  // ✅ 使用枚举
  enum UserRole {
      Admin = 'admin',
      User = 'user',
      Guest = 'guest'
  }

  // ✅ 或常量对象
  const USER_ROLE = {
      ADMIN: 'admin',
      USER: 'user',
      GUEST: 'guest'
  } as const;

  type UserRole = typeof USER_ROLE[keyof typeof USER_ROLE];
  ```

## 8. 工具类型

### ✅ 检查项

- [ ] **使用内置工具类型**
  - Partial, Required, Readonly, Pick, Omit 等

  ```typescript
  interface User {
      id: string;
      name: string;
      email: string;
  }

  // Partial - 所有属性可选
  type UserUpdate = Partial<User>;

  // Pick - 选择特定属性
  type UserBasicInfo = Pick<User, 'id' | 'name'>;

  // Omit - 排除特定属性
  type UserWithoutId = Omit<User, 'id'>;

  // Readonly - 只读
  type ReadonlyUser = Readonly<User>;
  ```

## 9. 错误处理

### ✅ 检查项

- [ ] **自定义错误类型**

  ```typescript
  class ValidationError extends Error {
      constructor(
          message: string,
          public field: string
      ) {
          super(message);
          this.name = 'ValidationError';
      }
  }

  function validate(data: unknown) {
      if (!data) {
          throw new ValidationError('Data is required', 'data');
      }
  }
  ```

- [ ] **错误类型定义**

  ```typescript
  type Result<T, E = Error> =
      | { success: true; data: T }
      | { success: false; error: E };

  function parseUser(json: string): Result<User> {
      try {
          const data = JSON.parse(json);
          return { success: true, data };
      } catch (error) {
          return {
              success: false,
              error: error instanceof Error ? error : new Error('Unknown error')
          };
      }
  }
  ```

## 10. 配置和严格模式

### ✅ 检查项

- [ ] **tsconfig.json 严格配置**

  ```json
  {
      "compilerOptions": {
          "strict": true,
          "noImplicitAny": true,
          "strictNullChecks": true,
          "strictFunctionTypes": true,
          "noUnusedLocals": true,
          "noUnusedParameters": true,
          "noImplicitReturns": true
      }
  }
  ```

## 11. 性能优化

### ✅ 检查项

- [ ] **避免重复计算类型**
  - 使用类型别名

  ```typescript
  // ❌ 重复定义
  function process1(data: { id: string; name: string }) {}
  function process2(data: { id: string; name: string }) {}

  // ✅ 使用类型别名
  type Data = { id: string; name: string };
  function process1(data: Data) {}
  function process2(data: Data) {}
  ```

## 严重性评估

| 问题 | 严重性 |
|------|--------|
| 使用 any 且无注释 | 中 |
| 缺少错误处理 | 中 |
| 类型断言不安全 | 中 |
| 缺少类型定义 | 低 |
| 导入组织混乱 | 低 |
| 未使用 strict 模式 | 中 |
