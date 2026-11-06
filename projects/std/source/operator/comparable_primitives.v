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
# 覆盖范围：
# - 只覆盖既有 `<` 与既有 `imply X: Equal` 都具备的整数类型；`i128` / `u128`
#   还没有 `Equal`，本版不纳入，也不写「假装有 `<`」的实现。
# - `char` 的 `==` / `!=` 已由 `imply char: std::operator::Equal` 提供，
#   `Comparable: Equal` 的前置在本版已满足。
# - `i64` 的 impl 与固有 impl 同名算子并存，默认体只保留单一来源，实现者不重复声明。

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
