
namespace std.text;

[primitive("std::text::char")]
structure char {

}

imply char {
    # 码位 → char 具名构造（与 `Utf8Text.character_at` 的解码规则同源）。
    # 运行载体是 32 位无符号码位，构造保留完整码位，不按 16 位截断。
    micro from(code: u32) -> char {
        return code as char
    }

    # 分类判定一律以 char 字面量书写边界：ASCII 各类是连续码位区间，
    # 区间端点直接用字面量比较，不维护十进制码表。
    micro is_ascii_digit(self): bool {
        return self >= '0' && self <= '9'
    }

    micro is_ascii_uppercase(self): bool {
        return self >= 'A' && self <= 'Z'
    }

    micro is_ascii_lowercase(self): bool {
        return self >= 'a' && self <= 'z'
    }

    micro is_ascii_alpha(self): bool {
        return self.is_ascii_uppercase() || self.is_ascii_lowercase()
    }

    micro is_ascii_alphanumeric(self): bool {
        return self.is_ascii_digit() || self.is_ascii_alpha()
    }

    # 大小写转换保持 char → char 语义：只平移 ASCII 字母区间，
    # 其余码位原样返回；区间外不猜测、不折叠。
    micro to_ascii_lowercase(self): char {
        if self.is_ascii_uppercase() {
            return char::from((self as u32) + ('a' as u32) - ('A' as u32))
        }

        return self
    }

    micro to_ascii_uppercase(self): char {
        if self.is_ascii_lowercase() {
            return char::from((self as u32) - ('a' as u32) + ('A' as u32))
        }

        return self
    }
}

imply char: std::operator::Equal {
    # 相等性按码位判定：char 的运行载体是 32 位无符号码位，转成 u32 后值域完全保持，
    # 复用 u32 的既有 provider 链，不为 char 新造平台相关 host contract。
    infix `==`(self, rhs: Self): bool {
        return self as u32 == rhs as u32
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply char: std::operator::Comparable {
    # 序按码位自然序：分类与大小写平移都表达为字面量区间比较，
    # 依赖本 impl 提供的 `>` / `>=` / `<` / `<=`。
    micro compare(self, rhs: Self): std::operator::Ordering {
        let left: u32 = self as u32
        let right: u32 = rhs as u32
        if left < right {
            return std::operator::Ordering.Less
        }
        if left > right {
            return std::operator::Ordering.Greater
        }
        return std::operator::Ordering.Equal
    }
}
