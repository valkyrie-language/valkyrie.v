# trait 系统

## 概述

trait 是 Valkyrie 的"能力宪法"——定义一组方法签名和关联类型，描述类型"能做什么"。与名义类型系统不同，Valkyrie 采用**结构子类型**（Structural Subtyping）：编译器自动判断任意 `class` 是否满足某个 trait，无需 `class` 显式声明实现。

核心设计原则：

| 原则 | 说明 |
|:---|:---|
| 结构推导 | 编译器根据方法签名自动判定 trait 满足关系，零运行时开销 |
| 零侵入 | `class` 作者无需声明 `implements`，能力从形状自动推导 |
| 无字段 | trait 不得包含字段，字段属于 `class` / `structure` 的职责 |
| 默认方法 | trait 可提供基于其他方法实现的默认行为，`class` 可按需覆盖 |

## trait 定义语法

```valkyrie
trait IntoIterator {
    type Item
    type Iter: Iterator<Item = Self::Item>

    into_iterator(self) -> Self::Iter
}
```

关联类型用 `type` 声明。冒号后可以跟边界约束——如 `Iter: Iterator<Item = Self::Item>` 要求关联类型 `Iter` 必须满足 `Iterator` trait，且其 `Item` 等于当前 trait 的 `Item`。

trait 体只包含方法签名和关联类型声明，不得包含字段。

`Self` 在 trait 定义中指向"实现该 trait 的当前类型"。

## 结构推导

编译器对每个 `class` 自动执行以下推导步骤：

| 步骤 | 动作 | 说明 |
|:---|:---|:---|
| 1 | 检查方法签名 | 逐方法比对：名称、参数类型、返回类型完全一致即匹配 |
| 2 | 推断关联类型 | 从匹配方法的返回类型和参数类型推断 trait 中 `type` 的具体类型 |
| 3 | 验证关联类型约束 | 确保推断出的关联类型满足其边界约束（如 `Iter: Iterator`） |
| 4 | 建立满足关系 | 将 `class` 注册为该 trait 的满足者 |

以 `ArrayList<T>` 满足 `IntoIterator` 为例（源码在 `ArrayList.v:291-301` 给出显式实现）：

1. **检查方法签名**：`ArrayList<T>` 中存在 `into_iterator(self) -> ArrayListIterator<T>`，与 `IntoIterator` 的 `into_iterator(self) -> Self::Iter` 形状匹配。
2. **推断关联类型**：
   - `Self::Item` 从 `ArrayListIterator<T>` 的 `Item` 关联类型推导 → `T`
   - `Self::Iter` 从返回类型推导 → `ArrayListIterator<T>`
3. **验证约束**：`ArrayListIterator<T>` 确实满足 `Iterator<Item = T>`，通过。
4. **建立关系**：`ArrayList<T>` 被注册为 `IntoIterator`，编译器在需要 `IntoIterator` 的上下文中接受 `ArrayList<T>`。

整个过程发生在编译期，零运行时开销。

## trait 默认方法

trait 可提供 `default` 方法的实现。源码中 `Iterator` 的 `enumerate`、`skip`、`take`、`map`、`filter` 等均为默认方法，依赖 `has_next` / `next`：

```valkyrie
trait Iterator {
    type Item

    has_next(self) -> bool
    next(mut self) -> Option<Self::Item>

    enumerate(self) -> EnumerateIterator<Item, Self> {
        return EnumerateIterator {
            _iter: self,
            _ordinal: 1,
        }
    }
}
```

`collect` 不是 `IntoIterator` 的默认方法，而是 `std.iterator` 下的自由函数；`collect_array_list` 与 `collect_array` 分别返回 `ArrayList<T>` 与 `[T]`：

```valkyrie
let list: ArrayList<i32> = collect_array_list(items.into_iterator())
let array: [i32] = collect_array(items.into_iterator())
```

**覆盖规则**：

| 场景 | 行为 |
|:---|:---|
| `class` 定义了同名方法 | 使用 `class` 版本（覆盖默认实现） |
| `class` 未定义同名方法 | 使用 trait 的 `default` 实现 |
| 多个 trait 提供同名默认方法 | 编译错误，必须显式覆盖消除歧义 |

覆盖是"特化仅在 `class` 内部"原则的体现——trait 提供的只是"最通用"的实现，`class` 知道自己内部的存储布局，可以提供更高效的版本。

## trait 别名

trait 别名是纯语法糖：

| 特性 | 说明 |
|:---|:---|
| 能力 | 不引入新的能力实体，仅为已有 trait 组合起名 |
| 分派 | 不参与方法分派，方法调用追溯到组合中的原始 trait |
| 推导 | 结构推导检查组合中的每个 trait 是否被满足 |
| 约束 | `where T: 别名<...>` 等价于 `where T: 组合中的各个原始 trait` |

`&` 是 trait 组合运算符，表示"同时满足"。

## 标准库核心 trait 谱系

### 迭代与遍历

| trait | 方法 | 说明 |
|:---|:---|:---|
| `IntoIterator` | `into_iterator(self) -> Self::Iter` | 转换为迭代器，消耗自身所有权。关联类型 `Item` 和 `Iter: Iterator<Item = Self::Item>` |
| `Iterator` | `has_next(self) -> bool`、`next(mut self) -> Option<Self::Item>` | 推进迭代器到下一项，返回 `Some(item)` 或 `None`。关联类型 `Item`；默认方法含 `enumerate` / `skip` / `take` / `map` / `filter` 等 |

### 长度信息

| trait | 方法 | 说明 |
|:---|:---|:---|
| `Countable` | `length(self) -> usize` | 精确元素计数。`length` 是承载的元素个数，不是容量、也不是索引空间上界 |

### 索引

| trait | 方法 | 说明 |
|:---|:---|:---|
| `Cardinal` | `⁅ ⁆` / `⁅ ⁆=`、`get_cardinal` / `set_cardinal`（`offset: Self::Index`） | 0 基索引读写。关联类型 `Element` 与 `Index`；常见序列实现取 `Index = usize`。合同允许元组索引，但目前无实现（现有五个实现均为 `Index = usize`），多维形状尚未落地 |

### 有序比较

| trait | 方法 | 说明 |
|:---|:---|:---|
| `Comparable` | `compare(self, other: Self) -> Ordering` | 全序比较。继承 `Equal`；`Ordering` 是 enums，另含 `<=>`、`<`、`<=`、`>` 等派生算子 |

## 尚未实现的合同

以下能力形状在文档中曾以统一 trait 描述，但源码目前只有具体类型上的同名成员，没有统一 trait。

- `Contains`：文档原描述为带 `Item` 关联类型的包含判断 trait；源码现状是 `contains(self, value: T): bool` 仅作为具体类型的成员存在（`Array.v:32`、`ArrayList.v:137`、`set.v:8`、`LinkedList.v:146`），没有统一 trait。
- `PushFront` / `PushBack` / `PopFront` / `PopBack`：文档原描述为头尾增删 trait；源码现状是 `deque.v:16-35` 与 `LinkedList.v:35-93` 上的同名成员，没有统一 trait。
- `Insertable`：文档原描述为 `insert(ref self, index: i32, value: Self::Item)`；源码现状是 `ArrayList.v:67` 的 `insert(mut self, ordinal: usize, value: T): unit`，没有统一 trait。
- `RemovableAt`：文档原描述为 `remove_at(ref self, index: i32)`；源码现状只有 `ArrayList.v:90` 的 `remove(mut self, ordinal: usize): Option<T>`，`remove_at` 零命中，没有统一 trait。
- `Clearable`：文档原描述为 `clear(ref self)`；源码现状是 `ArrayList.v:49` 等具体类型上的 `clear(mut self): unit`，没有统一 trait。
- `Lookup`：文档原描述为带 `Key` / `Value` 关联类型的 `lookup` trait；源码现状是映射类型用 `get` / `insert` / `remove`（`map.v:7-8`），`lookup` 零命中，没有统一 trait。
- `Extendable`：文档原描述为 `extend(ref self, other: Self::Item)`；源码现状是 `extend` 零命中，没有统一 trait。
- `ImmPushBack`：文档原描述为不可变式尾部追加；源码现状是 `imm_push_back` 零命中，没有统一 trait。
- `Priority`：文档原描述为 `extract_priority(self) -> i32`；源码现状只有 `PriorityQueue.v:4` 的 `class PriorityQueue<T>`，没有该 trait 与成员。
- `ParallelIterable` / `ParallelIterator`：文档原描述为并行迭代转换与分批拉取；源码现状是两者及 `into_parallel_iterator` / `next_chunk` 均零命中，没有统一 trait。
- `DoubleEndedIterator`：文档原描述为 `next_back(ref self)` 双向迭代；源码现状是 `next_back` 零命中，没有统一 trait。
- `RandomAccessContainer`：文档原描述为 `trait RandomAccessContainer<T> = Indexable<Item = T> & ExtractLength` 的别名示例；源码现状是该别名与 `Indexable` / `ExtractLength` 均零命中。

## 与其他关键字的关系

### trait 与 class

| 方面 | trait | class |
|:---|:---|:---|
| 职责 | 定义能力形状（方法签名 + 关联类型） | 定义具体类型（字段 + 方法实现） |
| 实例化 | 不可实例化 | 可实例化 |
| 包含字段 | 否 | 是 |
| 实现关系 | 被结构推导判定满足 | 被编译器检查是否满足 trait |
| 默认实现 | 可提供 `default` 方法 | 方法实现为最终行为 |

### trait 与 micro

`micro` 函数通过 `where` 约束引用 trait，实现泛型约束：

```valkyrie
micro sum_up<T>(items: T) -> i32
    where T: IntoIterator, T::Item: Addable
{
    let mut total = 0
    loop item in items.into_iterator() {
        total = total + item
    }
    total
}
```

`where` 子句中的 `T: IntoIterator` 表示类型 `T` 必须满足 `IntoIterator` trait，`T::Item: Addable` 进一步约束关联类型。

### trait 与 union / unite

`union` 和 `unite` 的变体可作为 trait 方法的返回类型：

```valkyrie
union IntOrString {
    Int(i32)
    Str(string)
}

trait FallibleParser {
    parse(self, input: string) -> Fine<Self::Output> | Fail<ParseError>
}
```

trait 方法返回联合类型时，调用方使用 `catch` 处理各变体分支。详见 [Effect 系统](../effect-system/)。

## 边界原则

### 显式 trait

部分 trait 涉及语义层面的保证（如内存安全、线程安全），无法仅凭方法签名判定——其满足关系**不能**仅凭形状推导，必须由类型作者显式声明。

| trait 类别 | 推导方式 | 示例 |
|:---|:---|:---|
| 普通 trait | 编译器自动从形状推导 | `IntoIterator`、`Countable`、`Cardinal` |
| 显式 trait | 类型作者显式声明 | `Serializable`、`Sendable`、`Syncable`、`Cloneable` |

例如 `Serializable` 要求类型的所有字段都可序列化——这是递归的语义保证，不是签名级信息。

### 外部类型与包裹类

外部代码（来自其他包或运行时的类型）**绝不**通过形状自动获得显式 trait。外部类型必须通过**包裹类**（Wrapper Class）显式封装后才能参与 trait 推导：

```valkyrie
# 外部类型 ExternVec 有 length 方法，但不会自动满足 Countable
# 必须创建包裹类：

class MyVec
    inner: ExternVec

    length(self) -> usize {
        return self.inner.length()
    }
end
```

包裹类通过在 `class` 内部手动实现对应方法来"认领" trait 满足关系。编译器对包裹类同样执行结构推导——只要方法签名匹配，就会建立 trait 满足关系。

对于涉及 FFI 的外部类型，显式 trait 的约束同样适用。详见 [特性标注](../attributes.md)。

### 推导边界总结

| 类型来源 | 普通 trait | 显式 trait |
|:---|:---|:---|
| 当前包定义的 `class` | 自动形状推导 | 需显式声明 |
| 外部包的类型 | 自动形状推导 | **永不**自动获得，必须通过包裹类 |
| FFI 类型 | 自动形状推导 | **永不**自动获得，必须通过包裹类 |