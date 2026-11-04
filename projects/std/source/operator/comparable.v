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
# 必要的类型事实（取证，写入本文件前已核对 std 现网）：
# - `enums` 是真关键字，std 现网有 `Severity`（diagnostic/diagnostic.v）与
#   `IoErrorKind`（io/error.v）两处真实声明；变体按裸名可构造
#   （`IoError { kind: EndOfStream }`），无标签、无载荷。
# - `flags` 是独立形态（带值表达式与位组合），不是 `enums` 的开关；三态序
#   不需要位组合，因此 `Ordering` 用 `enums` 而不是 `flags`。
# - `enums` 不自带 `==`：std 现网对 `enums` 值的判定全部走 `match`
#   （`severity_is_error` 的 3 支 match 是唯一现网用法），没有 `enums` 值参与
#   `==` / `!=` 的现网证据，编译器侧也没有 `enums` 的相等算子登记。
#   因此 `Ordering: Equal` 手写 4 × 4 嵌套 `match`。
# - 不实现 `Hash`：`Ordering` 只是比较结果，不进哈希容器。

# [已关闭: Q10] `Ordering.Equal` 与同命名空间 `trait Equal` 撞名，曾按阻塞记录。
#   `indexes.rs::resolve` 是 kind-agnostic、names-first：单段名先查 namespace 链
#   与 `by_name`，只有都没命中才回退 `variant_owners`。`trait Equal` 在
#   `std.operator` 里，所以裸 `Equal` 解析到 trait，变体不可达；限定写法
#   `Ordering.Equal` 也不可达（变体只登记在 `variant_owners`，不进 `members`）。
#   本文件按未改名形态写，保留撞名现场供编译器线取证。
# [阻塞: Q11] `<=>` 在编译器词法层没有 token（全仓无 `<=>` / Spaceship 匹配）。
#   声明侧因为写成反引号标识符可以解析，但表达式位置 `self <=> other` 直接
#   报 `此处需要表达式`。`<=>` 的表达式形态由 oaks 补词法 token 解决，本标准
#   不自行绕开。
# [临时形态: 等 <=> token 落地后改回] 四个派生算子当前直接调
#   `self.compare(other)`（语义等价于 `self <=> other`）。这是临时写法，不是
#   永久契约；token 落地后必须改回 `match self <=> other { ... }`。
# [阶段未覆盖: Q13] `imply Ordering {}` 与 `imply Ordering: Trait {}` 对
#   `enums` 目标在本轮前端被接受（无诊断），但 std 现网无先例；`imply_validation`
#   不在 `b_diagnostic_snapshot` 覆盖范围内，须在完整管线复验，不能记作“通过”。
# [已解: Q4] 编译器 `6d12efef` 起，trait 默认体里的 `self` 按实现类型正常派发；
#   原先 `self.compare` 的 `9 candidate(s) share the name, but none matches the
#   argument types` 已从 std 快照消失。默认体保持单一来源，不逐个实现者手写，
#   也不拆自由函数绕开 `self` 派发。

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
