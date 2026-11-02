namespace std.text;

⍝ UTF-16 编码的字符串
[clr("System.Runtime", "System.String")]
[jvm("java.lang.String")]
class Utf16Text {
    _repr: [u16]
}

imply Utf16Text {
    [host_contract]
    micro length(self) -> usize {
        return self._repr.length()
    }

    micro is_empty(self) -> bool {
        if self.length() == 0 {
            return true
        }

        return false
    }

    [host_contract]
    micro slice(self, start: usize, count: usize) -> utf16 {
        return self
    }

    [host_contract]
    micro concat(self, other: utf16) -> utf16 {
        return self
    }

    [host_contract]
    micro contains(self, value: utf16) -> bool {
        return false
    }

    [host_contract]
    micro starts_with(self, prefix: utf16) -> bool {
        return false
    }

    [host_contract]
    micro ends_with(self, suffix: utf16) -> bool {
        return false
    }

    [host_contract]
    micro index_of(self, value: utf16) -> Option<usize> {
        return std::types::option_none::<usize>()
    }

    [host_contract]
    micro trim(self) -> utf16 {
        return self
    }

    [host_contract]
    micro to_lower(self) -> utf16 {
        return self
    }

    [host_contract]
    micro to_upper(self) -> utf16 {
        return self
    }

    [host_contract]
    micro replace(self, old_value: utf16, new_value: utf16) -> utf16 {
        return self
    }

    [host_contract]
    micro equals(self, other: utf16) -> bool {
        return false
    }

    [host_contract]
    private micro char_at(self, offset: usize) -> u16 {
        return self._repr::[offset]
    }

    micro chars(self) -> Utf16Iterator {
        return Utf16Iterator::new(self)
    }
}

imply Utf16Text: std::iterator::IntoIterator {
    type Item = char;
    type Iter = Utf16Iterator;

    micro into_iterator(self): Utf16Iterator {
        return self.chars()
    }
}

# 0 基 code unit 索引读写合同：`⁅ ⁆` / `⁅ ⁆=` 与同源的 `get_cardinal` / `set_cardinal`。
# 索引按 UTF-16 code unit 计数（与 `length` 的计数单位一致，`char` 即 u16 code unit）；
# 对含 astral 字符（代理对）的文本，本索引口径与 `Utf8Text` 的标量口径不等——
# 这是各自 repr 的忠实口径，显式记录。元素个数由 `length` 承担，与本合同无关。
imply Utf16Text: std::primitive::Cardinal {
    type Element = char;

    # 0 基 code unit 索引自动取值；越界结构化失败（合同语义见 `std::primitive::Cardinal`）。
    suffix `⁅ ⁆`(self, offset: usize): char {
        if offset >= self.length() {
            std::types::panic("Utf16Text ⁅ ⁆ 越界：offset 超出元素个数")
        }

        return self.char_at(offset) as char
    }

    # 0 基 code unit 索引写入，只改元素不改元素个数；越界结构化失败，不许静默丢弃写入。
    suffix `⁅ ⁆=`(mut self, offset: usize, value: char): unit {
        if offset >= self.length() {
            std::types::panic("Utf16Text ⁅ ⁆= 越界：offset 超出元素个数")
        }

        std::collection::array::set(self._repr, offset, value as u16)
    }

    # 与 `⁅ ⁆` 同源：命名方法形态，互为委托，不维护第二套索引访问逻辑。
    micro get_cardinal(self, offset: usize): char {
        return self⁅offset⁆
    }

    # 与 `⁅ ⁆=` 同源：命名方法形态，互为委托。
    micro set_cardinal(mut self, offset: usize, value: char): unit {
        self⁅offset⁆ = value
    }
}

