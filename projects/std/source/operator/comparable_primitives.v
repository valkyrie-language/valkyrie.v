namespace std.operator;

# Comparable 的基础类型实现（整数族 + bool + char）。
#
# 口径：
# - 整数族：只覆盖既有 `<` 与既有 `imply X: Equal` 都真实存在的类型
#   （i8 / i16 / i32 / i64 / u8 / u16 / u32 / u64）。有符号与无符号各自按
#   自身值域比较，不做跨符号拓宽。
# - `bool`：只有 `==` / `!=` / `===` / `=!=`，没有 `<`。因此 `compare`
#   按实际算子写：先判相等，再用真假二分，不写 `self < other`。
# - `char`：只有 `==` / `!=` 与 `as u32`，没有 `<`。按码位比较必须显式转换
#   `self as u32`，这是实现侧的转换，不是「复用 char 的 `<`」。
# - 故意不实现：`f32` / `f64`（IEEE NaN 与 ±0 与三态序冲突，已定案）。
#
# [阶段未覆盖: Q12] `Comparable: Equal` 的前置在这些类型上还不完整：
#   - `i128` / `u128` 没有 `<`，也没有 `imply X: Equal`（`i128.v` 只有 6 行的
#     纯 primitive 声明）。本版不写入，避免写出「假装有 `<`」的实现。
#   - `char` 的 `==` / `!=` 已迁入 `imply char: std::operator::Equal`（另一笔），
#     因此 `Comparable: Equal` 的前置在本版已满足。
#   注意：本轮 `b_diagnostic_snapshot` 只到 HIR 调用解析，超 trait 校验在
#   `imply_validation` 阶段、不在覆盖范围内。因此“无诊断”不等于通过，须在完整
#   管线复验。
# [阶段未覆盖: Q3] `imply i64: Comparable` 提供的默认成员 `<` / `<=` / `>` / `>=`
#   与 `i64` 固有 impl 里的同名算子构成「同一成员两个来源」。本轮无诊断，但
#   重复成员判定同样在 `imply_validation` 阶段、未被快照覆盖，不能记为通过。
#   该结论直接决定 C2 的迁移形态（固有 impl 与 trait impl 同名成员是否判重）。
# [未复现: Q10] 原清单写的“`Ordering.Equal` 与 `trait Equal` 重复声明”不成立：
#   `enums` 变体不进入自由声明表，`type_declaration_identity` 也不含变体。
#   本轮 `return Equal` 在 value 位置无诊断；剩余疑问是解析优先级是否正确命中
#   变体，交编译器线确认，不再是本文件的阻塞项。

imply i8: Comparable {
    micro compare(self, other: Self): Ordering {
        if self < other {
            return Less
        }
        if other < self {
            return Greater
        }
        return Equal
    }
}

imply i16: Comparable {
    micro compare(self, other: Self): Ordering {
        if self < other {
            return Less
        }
        if other < self {
            return Greater
        }
        return Equal
    }
}

imply i32: Comparable {
    micro compare(self, other: Self): Ordering {
        if self < other {
            return Less
        }
        if other < self {
            return Greater
        }
        return Equal
    }
}

imply i64: Comparable {
    micro compare(self, other: Self): Ordering {
        if self < other {
            return Less
        }
        if other < self {
            return Greater
        }
        return Equal
    }
}

imply u8: Comparable {
    micro compare(self, other: Self): Ordering {
        if self < other {
            return Less
        }
        if other < self {
            return Greater
        }
        return Equal
    }
}

imply u16: Comparable {
    micro compare(self, other: Self): Ordering {
        if self < other {
            return Less
        }
        if other < self {
            return Greater
        }
        return Equal
    }
}

imply u32: Comparable {
    micro compare(self, other: Self): Ordering {
        if self < other {
            return Less
        }
        if other < self {
            return Greater
        }
        return Equal
    }
}

imply u64: Comparable {
    micro compare(self, other: Self): Ordering {
        if self < other {
            return Less
        }
        if other < self {
            return Greater
        }
        return Equal
    }
}

# bool 没有 `<`：先判相等，再按 true > false 二分。
imply bool: Comparable {
    micro compare(self, other: Self): Ordering {
        if self == other {
            return Equal
        }
        if self {
            return Greater
        }
        return Less
    }
}

# char 没有 `<`：显式拓宽到 u32（u16 code unit，值域完全保持），
# 再比较 u32 的既有 `<`。这是转换，不是复用 char 的算子。
imply char: Comparable {
    micro compare(self, other: Self): Ordering {
        let lhs: u32 = self as u32
        let rhs: u32 = other as u32
        if lhs < rhs {
            return Less
        }
        if rhs < lhs {
            return Greater
        }
        return Equal
    }
}
