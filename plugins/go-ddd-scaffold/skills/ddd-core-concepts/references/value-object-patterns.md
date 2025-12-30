# Value Object 高级模式

## 常见值对象示例

### Email

```go
type Email struct {
    value string
}

func NewEmail(email string) (Email, error) {
    email = strings.TrimSpace(strings.ToLower(email))
    if !isValidEmail(email) {
        return Email{}, errors.New("invalid email")
    }
    return Email{value: email}, nil
}

func (e Email) Value() string { return e.value }
func (e Email) Domain() string {
    parts := strings.Split(e.value, "@")
    if len(parts) == 2 {
        return parts[1]
    }
    return ""
}
```

### Money

```go
type Money struct {
    amount   int64  // 以分为单位
    currency string
}

func NewMoney(amount int64, currency string) (Money, error) {
    if currency == "" {
        return Money{}, errors.New("currency required")
    }
    return Money{amount: amount, currency: currency}, nil
}

func (m Money) Add(other Money) (Money, error) {
    if m.currency != other.currency {
        return Money{}, errors.New("currency mismatch")
    }
    return Money{m.amount + other.amount, m.currency}, nil
}

func (m Money) Multiply(factor int) Money {
    return Money{m.amount * int64(factor), m.currency}
}
```

### Address

```go
type Address struct {
    street     string
    city       string
    state      string
    postalCode string
    country    string
}

func NewAddress(street, city, state, postalCode, country string) (Address, error) {
    if street == "" || city == "" || country == "" {
        return Address{}, errors.New("required fields missing")
    }
    return Address{street, city, state, postalCode, country}, nil
}

func (a Address) FullAddress() string {
    return fmt.Sprintf("%s, %s, %s %s, %s",
        a.street, a.city, a.state, a.postalCode, a.country)
}
```

### DateRange

```go
type DateRange struct {
    start time.Time
    end   time.Time
}

func NewDateRange(start, end time.Time) (DateRange, error) {
    if end.Before(start) {
        return DateRange{}, errors.New("end before start")
    }
    return DateRange{start: start, end: end}, nil
}

func (dr DateRange) Duration() time.Duration {
    return dr.end.Sub(dr.start)
}

func (dr DateRange) Contains(t time.Time) bool {
    return !t.Before(dr.start) && !t.After(dr.end)
}

func (dr DateRange) Overlaps(other DateRange) bool {
    return dr.start.Before(other.end) && other.start.Before(dr.end)
}
```

## 值对象不可变性模式

### 返回新对象

```go
type Temperature struct {
    celsius float64
}

// 所有操作返回新对象
func (t Temperature) Add(delta float64) Temperature {
    return Temperature{celsius: t.celsius + delta}
}

func (t Temperature) ToFahrenheit() Temperature {
    return Temperature{celsius: (t.celsius * 9 / 5) + 32}
}
```

### Builder 模式 (用于复杂值对象)

```go
type AddressBuilder struct {
    street     string
    city       string
    state      string
    postalCode string
    country    string
}

func NewAddressBuilder() *AddressBuilder {
    return &AddressBuilder{}
}

func (b *AddressBuilder) Street(s string) *AddressBuilder {
    b.street = s
    return b
}

func (b *AddressBuilder) City(c string) *AddressBuilder {
    b.city = c
    return b
}

func (b *AddressBuilder) Build() (Address, error) {
    return NewAddress(b.street, b.city, b.state, b.postalCode, b.country)
}

// 使用
addr, err := NewAddressBuilder().
    Street("123 Main St").
    City("Beijing").
    Country("China").
    Build()
```

## 值对象组合

```go
type FullName struct {
    firstName string
    lastName  string
}

type ContactInfo struct {
    email Email
    phone PhoneNumber
}

type Person struct {
    name    FullName
    contact ContactInfo
    address Address
}
```

## 值对象集合

```go
type Tags struct {
    values []string
}

func NewTags(tags ...string) (Tags, error) {
    // 去重和排序
    unique := make(map[string]bool)
    for _, tag := range tags {
        tag = strings.TrimSpace(strings.ToLower(tag))
        if tag != "" {
            unique[tag] = true
        }
    }

    var sorted []string
    for tag := range unique {
        sorted = append(sorted, tag)
    }
    sort.Strings(sorted)

    return Tags{values: sorted}, nil
}

func (t Tags) Contains(tag string) bool {
    for _, v := range t.values {
        if v == tag {
            return true
        }
    }
    return false
}

func (t Tags) Add(tag string) (Tags, error) {
    return NewTags(append(t.values, tag)...)
}
```
