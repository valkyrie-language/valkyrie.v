
namespace core::text;

[primitive("core::text::char")]
structure char {

}

imply char {
    # 码位 → char 具名构造（与 `Utf8Text.char_at` 的 `code_point as u16 as char` 同规则）。
    micro from(code: u32) -> char {
        return code as u16 as char
    }

    micro is_ascii_digit(self): bool {
        let code: u32 = self as u32
        return code >= 48 && code <= 57
    }

    micro is_ascii_alpha(self): bool {
        let code: u32 = self as u32
        return (code >= 65 && code <= 90) || (code >= 97 && code <= 122)
    }

    micro is_ascii_alphanumeric(self): bool {
        return self.is_ascii_digit() || self.is_ascii_alpha()
    }

    micro is_ascii_vowel(self): bool {
        let code: u32 = self as u32
        if code == 65 || code == 69 || code == 73 || code == 79 || code == 85 {
            return true
        }
        if code == 97 || code == 101 || code == 105 || code == 111 || code == 117 {
            return true
        }
        return false
    }

    # 字母数字统一小写键：数字为码位，字母为小写 ASCII 码位。
    micro ascii_alnum_key(self) -> Option<i64> {
        if !self.is_ascii_alphanumeric() {
            let empty: Option<i64> = None
            return empty
        }
        let code: u32 = self as u32
        if code >= 65 && code <= 90 {
            return Some { value: (code + 32) as i64 }
        }
        return Some { value: code as i64 }
    }

    micro lowercase_ascii_index(self) -> Option<i64> {
        let code: u32 = self as u32
        if code < 97 {
            let empty: Option<i64> = None
            return empty
        }
        if code > 122 {
            let empty: Option<i64> = None
            return empty
        }
        return Some { value: (code - 97) as i64 }
    }
}
