# React 代码审查检查清单

## 1. Hooks 使用规范

### ✅ 检查项

- [ ] **依赖数组正确**
  - useEffect、useMemo、useCallback 的依赖数组包含所有使用的外部变量
  - 不要遗漏依赖

  ```typescript
  // ❌ 错误示例 - 遗漏依赖
  useEffect(() => {
      fetchData(userId);
  }, []);  // userId 应该在依赖数组中

  // ✅ 正确示例
  useEffect(() => {
      fetchData(userId);
  }, [userId]);
  ```

- [ ] **避免不必要的依赖**
  - 使用函数式更新避免依赖 state

  ```typescript
  // ❌ 依赖 count
  useEffect(() => {
      const timer = setInterval(() => {
          setCount(count + 1);
      }, 1000);
      return () => clearInterval(timer);
  }, [count]);

  // ✅ 函数式更新，无需依赖 count
  useEffect(() => {
      const timer = setInterval(() => {
          setCount(c => c + 1);
      }, 1000);
      return () => clearInterval(timer);
  }, []);
  ```

- [ ] **useEffect 清理函数**
  - 及时清理订阅、定时器、事件监听器

  ```typescript
  // ✅ 正确清理
  useEffect(() => {
      const subscription = source$.subscribe();
      const timer = setInterval(() => {}, 1000);
      window.addEventListener('resize', handleResize);

      return () => {
          subscription.unsubscribe();
          clearInterval(timer);
          window.removeEventListener('resize', handleResize);
      };
  }, []);
  ```

- [ ] **Hooks 调用顺序**
  - 不在条件语句、循环或嵌套函数中调用 Hooks
  - Hooks 必须在组件顶层调用

  ```typescript
  // ❌ 错误 - 条件调用
  if (condition) {
      useEffect(() => {}, []);
  }

  // ✅ 正确
  useEffect(() => {
      if (condition) {
          // 条件逻辑在 Hook 内部
      }
  }, [condition]);
  ```

- [ ] **自定义 Hooks 命名**
  - 以 use 开头
  - 驼峰命名

  ```typescript
  // ✅ 正确命名
  function useLocalStorage<T>(key: string, initialValue: T) {
      const [value, setValue] = useState<T>(() => {
          const stored = localStorage.getItem(key);
          return stored ? JSON.parse(stored) : initialValue;
      });

      useEffect(() => {
          localStorage.setItem(key, JSON.stringify(value));
      }, [key, value]);

      return [value, setValue] as const;
  }
  ```

## 2. 组件设计

### ✅ 检查项

- [ ] **组件职责单一**
  - 每个组件只负责一件事
  - 大组件拆分成小组件

  ```typescript
  // ❌ 组件过大
  function UserProfile() {
      // 100+ 行代码，包含多个职责
  }

  // ✅ 拆分成小组件
  function UserProfile() {
      return (
          <div>
              <UserAvatar />
              <UserInfo />
              <UserActions />
          </div>
      );
  }
  ```

- [ ] **Props 类型定义**
  - 所有 Props 都有类型
  - 使用 interface 或 type 定义

  ```typescript
  interface UserCardProps {
      user: User;
      onEdit?: (user: User) => void;
      showActions?: boolean;
  }

  function UserCard({ user, onEdit, showActions = true }: UserCardProps) {
      // ...
  }
  ```

- [ ] **Props 解构**
  - 在函数参数中解构 Props
  - 提供默认值

  ```typescript
  // ✅ 解构和默认值
  function Button({
      children,
      variant = 'primary',
      size = 'medium',
      onClick
  }: ButtonProps) {
      // ...
  }
  ```

- [ ] **避免 Props drilling**
  - 使用 Context 或状态管理库
  - 组合组件

  ```typescript
  // ❌ Props drilling
  <Parent>
      <Child1 data={data}>
          <Child2 data={data}>
              <Child3 data={data} />
          </Child2>
      </Child1>
  </Parent>

  // ✅ 使用 Context
  const DataContext = createContext<Data | null>(null);

  function Parent() {
      const data = useData();
      return (
          <DataContext.Provider value={data}>
              <Child1>
                  <Child2>
                      <Child3 />
                  </Child2>
              </Child1>
          </DataContext.Provider>
      );
  }

  function Child3() {
      const data = useContext(DataContext);
      // 使用 data
  }
  ```

## 3. 性能优化

### ✅ 检查项

- [ ] **避免不必要的重新渲染**
  - 使用 React.memo 包装纯组件
  - 使用 useMemo 缓存计算结果
  - 使用 useCallback 缓存函数

  ```typescript
  // ✅ 使用 React.memo
  const UserCard = React.memo(({ user }: UserCardProps) => {
      return <div>{user.name}</div>;
  });

  // ✅ 使用 useMemo
  const expensiveValue = useMemo(() => {
      return computeExpensiveValue(data);
  }, [data]);

  // ✅ 使用 useCallback
  const handleClick = useCallback(() => {
      doSomething(id);
  }, [id]);
  ```

- [ ] **列表渲染使用 key**
  - 使用稳定的唯一 key
  - 不使用数组索引作为 key

  ```typescript
  // ❌ 使用索引
  {items.map((item, index) => (
      <Item key={index} {...item} />
  ))}

  // ✅ 使用唯一 ID
  {items.map(item => (
      <Item key={item.id} {...item} />
  ))}
  ```

- [ ] **避免在渲染中创建新对象/函数**

  ```typescript
  // ❌ 每次渲染创建新对象
  function Component() {
      return <Child style={{ margin: 10 }} onClick={() => {}} />;
  }

  // ✅ 提取到外部或使用 useMemo/useCallback
  const style = { margin: 10 };
  function Component() {
      const handleClick = useCallback(() => {}, []);
      return <Child style={style} onClick={handleClick} />;
  }
  ```

- [ ] **懒加载**
  - 使用 React.lazy 和 Suspense
  - 按需加载大组件

  ```typescript
  const HeavyComponent = React.lazy(() => import('./HeavyComponent'));

  function App() {
      return (
          <Suspense fallback={<Loading />}>
              <HeavyComponent />
          </Suspense>
      );
  }
  ```

## 4. 状态管理

### ✅ 检查项

- [ ] **状态位置合理**
  - 状态尽可能接近使用处
  - 共享状态提升到共同父组件

  ```typescript
  // ❌ 不必要的全局状态
  // 如果状态只在一个组件中使用，应该是本地状态

  // ✅ 本地状态
  function Counter() {
      const [count, setCount] = useState(0);
      // count 只在这里使用
  }
  ```

- [ ] **状态更新正确**
  - 使用函数式更新
  - 不直接修改状态

  ```typescript
  // ❌ 直接修改
  const [user, setUser] = useState({ name: 'John' });
  user.name = 'Jane';  // 错误！

  // ✅ 创建新对象
  setUser({ ...user, name: 'Jane' });

  // ✅ 函数式更新
  setUser(prev => ({ ...prev, name: 'Jane' }));
  ```

- [ ] **复杂状态使用 useReducer**

  ```typescript
  type Action =
      | { type: 'increment' }
      | { type: 'decrement' }
      | { type: 'reset'; payload: number };

  function reducer(state: number, action: Action): number {
      switch (action.type) {
          case 'increment':
              return state + 1;
          case 'decrement':
              return state - 1;
          case 'reset':
              return action.payload;
      }
  }

  function Counter() {
      const [count, dispatch] = useReducer(reducer, 0);
      // ...
  }
  ```

## 5. 副作用管理

### ✅ 检查项

- [ ] **数据获取**
  - 处理加载状态
  - 处理错误状态
  - 取消请求（防止内存泄漏）

  ```typescript
  function UserList() {
      const [users, setUsers] = useState<User[]>([]);
      const [loading, setLoading] = useState(true);
      const [error, setError] = useState<string | null>(null);

      useEffect(() => {
          const controller = new AbortController();

          fetchUsers({ signal: controller.signal })
              .then(data => {
                  setUsers(data);
                  setLoading(false);
              })
              .catch(err => {
                  if (err.name !== 'AbortError') {
                      setError(err.message);
                      setLoading(false);
                  }
              });

          return () => controller.abort();
      }, []);

      if (loading) return <Loading />;
      if (error) return <Error message={error} />;
      return <ul>{users.map(/* ... */)}</ul>;
  }
  ```

## 6. 事件处理

### ✅ 检查项

- [ ] **事件处理器命名**
  - 使用 handle 前缀
  - 清晰描述行为

  ```typescript
  function Form() {
      const handleSubmit = (e: React.FormEvent) => {
          e.preventDefault();
          // ...
      };

      const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
          // ...
      };

      return (
          <form onSubmit={handleSubmit}>
              <input onChange={handleInputChange} />
          </form>
      );
  }
  ```

- [ ] **避免内联函数（在性能敏感场景）**

  ```typescript
  // ❌ 每次渲染创建新函数
  <button onClick={() => handleDelete(id)}>Delete</button>

  // ✅ 使用 useCallback
  const handleDelete = useCallback(() => {
      deleteItem(id);
  }, [id]);

  <button onClick={handleDelete}>Delete</button>
  ```

## 7. 表单处理

### ✅ 检查项

- [ ] **受控组件**
  - 表单输入使用受控组件
  - value 和 onChange 配对

  ```typescript
  function LoginForm() {
      const [email, setEmail] = useState('');
      const [password, setPassword] = useState('');

      return (
          <form>
              <input
                  type="email"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
              />
              <input
                  type="password"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
              />
          </form>
      );
  }
  ```

- [ ] **表单验证**
  - 实时验证
  - 提交时验证
  - 显示错误信息

  ```typescript
  function EmailInput() {
      const [email, setEmail] = useState('');
      const [error, setError] = useState('');

      const validateEmail = (value: string) => {
          if (!value) {
              setError('Email is required');
          } else if (!/\S+@\S+\.\S+/.test(value)) {
              setError('Email is invalid');
          } else {
              setError('');
          }
      };

      const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
          const value = e.target.value;
          setEmail(value);
          validateEmail(value);
      };

      return (
          <div>
              <input
                  type="email"
                  value={email}
                  onChange={handleChange}
                  aria-invalid={!!error}
              />
              {error && <span role="alert">{error}</span>}
          </div>
      );
  }
  ```

## 8. 可访问性 (A11y)

### ✅ 检查项

- [ ] **语义化 HTML**
  - 使用适当的 HTML 标签
  - button 而非 div onClick

- [ ] **ARIA 属性**
  - aria-label, aria-describedby 等
  - role 属性

  ```typescript
  <button
      aria-label="Close modal"
      onClick={onClose}
  >
      <CloseIcon aria-hidden="true" />
  </button>
  ```

- [ ] **键盘导航**
  - 可通过键盘操作
  - Tab 键顺序合理

## 9. 错误边界

### ✅ 检查项

- [ ] **使用错误边界**
  - 包装可能出错的组件
  - 提供回退 UI

  ```typescript
  class ErrorBoundary extends React.Component<
      { children: React.ReactNode },
      { hasError: boolean }
  > {
      state = { hasError: false };

      static getDerivedStateFromError() {
          return { hasError: true };
      }

      componentDidCatch(error: Error, info: React.ErrorInfo) {
          console.error('Error caught:', error, info);
      }

      render() {
          if (this.state.hasError) {
              return <ErrorFallback />;
          }
          return this.props.children;
      }
  }

  // 使用
  <ErrorBoundary>
      <App />
  </ErrorBoundary>
  ```

## 10. TypeScript 集成

### ✅ 检查项

- [ ] **事件类型**

  ```typescript
  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {};
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {};
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {};
  ```

- [ ] **组件类型**

  ```typescript
  // 函数组件
  const Component: React.FC<Props> = ({ prop1, prop2 }) => {
      // 或不使用 FC
  };

  function Component({ prop1, prop2 }: Props): JSX.Element {
      // ...
  }
  ```

- [ ] **Ref 类型**

  ```typescript
  const inputRef = useRef<HTMLInputElement>(null);

  <input ref={inputRef} />
  ```

## 严重性评估

| 问题 | 严重性 |
|------|--------|
| 依赖数组错误 | 高 |
| 内存泄漏（未清理副作用） | 高 |
| 缺少 key | 中 |
| 不必要的重新渲染 | 中 |
| Props drilling | 低 |
| 缺少可访问性属性 | 中 |
