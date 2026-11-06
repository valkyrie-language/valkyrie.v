namespace std.operator;

# Comparable: 三态全序合同 —— 类型自带唯一、可观察、规范的三态序。
#
# 语义基线（合同的一部分，实现必须遵守）：
#
# - 判据是「能否定义」而不是「是否已经声明 `<`」：只要类型的 API 表面能给出
#   0..length 的可观察元素序列（如 `⁅ ⁆`），其字典序就是规范的，与容量无关。
#   因此序列容器（Array / ArrayList / ArrayView / LinkedList / Deque /
#   RingBuffer / Stack / Queue）与 BitSet（位序）都可以实现本合同。
# - 不可实现的典型：HashMap / HashSet / HashMultiSet / MultiSet / SwissTable /
#   SwissSet（哈希种子与插入历史影响布局）；OrderedMap / OrderedSet（迭代序
#   = 插入历史）；BinaryHeap / PriorityQueue（数组布局是插入历史产物，且等键
#   tie-break 未定义）；f32 / f64（IEEE NaN 与 ±0 与三态序冲突）。
# - `compare` 是唯一必实现成员。实现方契约：对任意 `(a, b)` 必须返回
#   `Less` / `Equal` / `Greater` 之一，不许返回 `Unordered`。
# - `Unordered` 只保留给未来的偏序合同（PartialComparable），本合同的消费者
#   一旦消费到 `Unordered` 即结构化失败（`std::types::panic`），不许静默降级。
# - `<=>` 与四个布尔算子 `<` / `<=` / `>` / `>=` 全部是默认体，由同一个三态
#   结果派生；实现方一律不重复声明这五个成员。
# - 稳定性不属于本合同：稳定性是排序入口（`sort` / `sorted`）的属性，
#   `Comparable` 只描述序，不描述并列键的相对顺序。
# - 本合同与容器约束正交：`Comparable` 只决定「元素能不能比」，不决定
#   「容器能不能排序」。`Stack` / `Queue` / `RingBuffer` 可 `Comparable`，
#   但不满足 `Cardinal + Countable`，因此进不了 `sort`。
# - `Comparable: Equal`：`compare` 的契约要求 `a == b ⟺ compare(a, b) == Equal`，
#   所以 `==` 必须是本合同的前置能力，不是可选项。
#
# 类型事实：
# - `enums` 是真关键字，std 现网有 `Severity`（diagnostic/diagnostic.v）与
#   `IoErrorKind`（io/error.v）两处真实声明；变体按裸名可构造
#   （`IoError { kind: EndOfStream }`），无标签、无载荷。
# - `flags` 是独立形态（带值表达式与位组合），不是 `enums` 的开关；三态序
#   不需要位组合，因此 `Ordering` 用 `enums` 而不是 `flags`。
# - `enums` 不自带 `==`：std 现网对 `enums` 值的判定全部走 `match`
#   （`severity_is_error` 的 3 支 match 是唯一现网用法）。因此 `Ordering: Equal`
#   手写 4 × 4 嵌套 `match`。
# - 不实现 `Hash`：`Ordering` 只是比较结果，不进哈希容器。

# `Ordering.Equal` 与同命名空间的 `trait Equal` 同名：命名空间内的裸 `Equal`
#   解析到 trait，引用变体须写成 `Ordering.Equal`。本文件按此形态书写。
#
# 四个派生算子直接委托 `compare`，语义等价于 `<=>`；`<=>` 作为表达式糖暂未
#   开放，调用方使用 `compare` 或四个布尔算子。
#
# `imply Ordering` 对 `enums` 目标的写法与其它 impl 相同，实现方无需额外声明。

# 三态序 + 偏序占位：纯标记（无 payload），`enums` 形态。
enums Ordering {
    Less
    Equal
    Greater
    Unordered
}

imply Ordering {
    # 本方法是全库唯一产生 -1 / 0 / 1 的位置，内部一律 Ordering。
    # `Unordered` 没有数值编码：偏序状态不许被压成有序数值。
    micro to_code(self): i32 {
        match self {
            case Less:
                -1
            case Equal:
                0
            case Greater:
                1
            case Unordered:
                std::types::panic("Ordering: Unordered 没有数值编码")
        }
    }

    micro is_ordered(self): bool {
        match self {
            case Less:
                true
            case Equal:
                true
            case Greater:
                true
            case Unordered:
                false
        }
    }
}

# `Ordering` 的相等比较手写，不走 derive：
# derive 是给用户结构体生成代码的机制，钥匙是 `Eq`，与本合同 `Equal` 名字
# 不对齐；std 核心类型不依赖未完成的代码生成设施。
imply Ordering: std::operator::Equal {
    infix `==`(self, other: Self): bool {
        match self {
            case Less:
                match other {
                    case Less:
                        true
                    case Equal:
                        false
                    case Greater:
                        false
                    case Unordered:
                        false
                }
            case Equal:
                match other {
                    case Less:
                        false
                    case Equal:
                        true
                    case Greater:
                        false
                    case Unordered:
                        false
                }
            case Greater:
                match other {
                    case Less:
                        false
                    case Equal:
                        false
                    case Greater:
                        true
                    case Unordered:
                        false
                }
            case Unordered:
                match other {
                    case Less:
                        false
                    case Equal:
                        false
                    case Greater:
                        false
                    case Unordered:
                        true
                }
        }
    }

    infix `!=`(self, other: Self): bool {
        return !(self == other)
    }
}

trait Comparable: Equal {
    # 唯一必实现成员。
    micro compare(self, other: Self): Ordering

    infix `<=>`(self, other: Self): Ordering {
        return self.compare(other)
    }

    # [临时形态: 等 <=> token 落地后改回]
    # 四个派生算子当前用 `self.compare(other)`；token 落地后改回
    # `match self <=> other { ... }`，语义不变。
    infix `<`(self, other: Self): bool {
        match self.compare(other) {
            case Less:
                true
            case Equal:
                false
            case Greater:
                false
            case Unordered:
                std::types::panic("Comparable: 消费到 Unordered")
        }
    }

    infix `<=`(self, other: Self): bool {
        match self.compare(other) {
            case Less:
                true
            case Equal:
                true
            case Greater:
                false
            case Unordered:
                std::types::panic("Comparable: 消费到 Unordered")
        }
    }

    infix `>`(self, other: Self): bool {
        match self.compare(other) {
            case Less:
                false
            case Equal:
                false
            case Greater:
                true
            case Unordered:
                std::types::panic("Comparable: 消费到 Unordered")
        }
    }

    infix `>=`(self, other: Self): bool {
        match self.compare(other) {
            case Less:
                false
            case Equal:
                true
            case Greater:
                true
            case Unordered:
                std::types::panic("Comparable: 消费到 Unordered")
        }
    }
}
