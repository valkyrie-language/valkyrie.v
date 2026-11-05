namespace std.text;

⍝ UTF-16 编码的字符串
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
        return None
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

# 0 基码元索引读写合同：`⁅ ⁆` / `⁅ ⁆=` 与同源的 `get_cardinal` / `set_cardinal`。
# 索引空间选定为 UTF-16 码元（code unit，与 `length` 的计数单位一致，`char` 即 u16 码元）：
# astral 码点占两个码元（代理对）。与 `Utf8Text` 的 0 基码点合同同构——都按各自 repr 的
# 字符单位计，只是单位不同（UTF-16 码元、UTF-8 码点）；字素口径未来以显式视图 API
# 单独开，不混入本合同。元素个数由 `length` 承担，与本合同无关。
imply Utf16Text: std::operator::Cardinal {
    type Element = char;
    type Index = usize;

    # 0 基码元索引自动取值；越界结构化失败（合同语义见 `std::operator::Cardinal`）。
    # 读取只此一份：直接落在 `_repr` 的 0 基数组合同，与 `⁅ ⁆=` 的 `array::set` 对称。
    suffix `⁅ ⁆`(self, offset: usize): char {
        if offset >= self.length() {
            std::types::panic("Utf16Text ⁅ ⁆ 越界：offset 超出元素个数")
        }

        return std::collection::array::get(self._repr, offset) as char
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

# 1 基序数读写合同：`[ ]` / `[ ]=` 与同源的 `get` / `set`，索引空间同为码元。
# `Index` 取 `isize`（负数落入越界判定，读返回 `None`）；实际访问委托 `Cardinal`
# 的 0 基码元偏移，本 impl 不重复存储访问逻辑。
imply Utf16Text: std::operator::Ordinal {
    type Index = isize;
    type Element = char;

    # 序数 1 基，裸 `char` 读取；越界结构化失败。
    suffix `[ ]`(self, ordinal: isize): char {
        if ordinal < 1 || ordinal > self.length() as isize {
            std::types::panic("Ordinal [ ] 越界：序数超出 [1, 元素个数]")
        }

        return self.get_cardinal((ordinal - 1) as usize)
    }

    # 越界写结构化失败，不许静默丢弃写入。
    suffix `[ ]=`(mut self, ordinal: isize, value: char): unit {
        if ordinal < 1 || ordinal > self.length() as isize {
            std::types::panic("Ordinal [ ]= 越界：序数超出 [1, 元素个数]")
        }

        self.set_cardinal((ordinal - 1) as usize, value)
    }

    # 命名读路径：可恢复形态，越界返回 `None`。
    micro get(self, ordinal: isize): Option<char> {
        if ordinal < 1 || ordinal > self.length() as isize {
            return None
        }

        return Some(self.get_cardinal((ordinal - 1) as usize))
    }

    # 与 `[ ]=` 同源：命名方法形态，互为委托。
    micro set(mut self, ordinal: isize, value: char): unit {
        self[ordinal] = value
    }
}

