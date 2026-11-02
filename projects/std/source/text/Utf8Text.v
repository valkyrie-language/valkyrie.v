namespace std.text;

# Portable Utf8Text: [host_contract] surfaces bind to std.adaptor.* via Legion resolver.
# Target-specific glue (wasm env, CLR, …) lives only in adaptor packages — no arch metaprogramming here.

class Utf8Text {
    _repr: [u8]
}

imply Utf8Text {
    micro new(capacity: usize) -> Self {
        return Self { _repr: [] }
    }

    micro from_bytes(bytes: [u8]) -> Self {
        return Self { _repr: bytes }
    }

    micro from_bytes_unchecked(bytes: [u8]) -> Self {
        return Self { _repr: bytes }
    }

    micro byte_length(self) -> usize {
        return self._repr.length()
    }

    # Unicode scalar count (std). CLR host_provider must not flatten to String.get_Length.
    [host_contract]
    micro length(self) -> usize {
        let mut index: usize = 0
        let mut count: usize = 0
        while index < self._repr.length() {
            let width: usize = self.char_width(index)
            if width == 0 {
                break
            }

            index = index + width
            count = count + 1
        }

        return count
    }

    micro is_empty(self) -> bool {
        return self.byte_length() == 0
    }

    [host_contract]
    micro equals(self, other: utf8) -> bool {
        return self == other
    }

    micro not_equals(self, other: utf8) -> bool {
        return self != other
    }

    infix `+`(self, other: utf8): utf8 {
        return self.concat(other)
    }

    [host_contract]
    micro concat(self, other: utf8) -> utf8 {
        return self.concat_repr(other)
    }

    [host_contract]
    micro contains(self, value: utf8) -> bool {
        return self.index_of(value).is_some()
    }

    [host_contract]
    micro starts_with(self, prefix: utf8) -> bool {
        let prefix_length: usize = prefix.length()
        let self_length: usize = self.length()
        if prefix_length > self_length {
            return false
        }

        return self.slice(0, prefix_length).equals(prefix)
    }

    [host_contract]
    micro ends_with(self, suffix: utf8) -> bool {
        let suffix_length: usize = suffix.length()
        let self_length: usize = self.length()
        if suffix_length > self_length {
            return false
        }

        return self.slice(self_length - suffix_length, suffix_length).equals(suffix)
    }

    # Scalar index of `value` (std). CLR host_provider converts via UTF-16 walk — not String.IndexOf alone.
    [host_contract]
    micro index_of(self, value: utf8) -> Option<usize> {
        return self.index_of_repr(value)
    }

    [host_contract]
    micro trim(self) -> utf8 {
        return self
    }

    micro to_lower(self) -> utf8 {
        return self
    }

    micro to_upper(self) -> utf8 {
        return self
    }

    [host_contract]
    micro replace(self, old_value: utf8, new_value: utf8) -> utf8 {
        return self
    }

    micro split(self, separator: utf8) -> [utf8] {
        let mut result: [utf8] = []
        let separator_length: usize = separator.length()

        if separator_length == 0 {
            result = std::collection::push(result, self)
            return result
        }

        let mut remaining: utf8 = self
        while true {
            let index_option: Option<usize> = remaining.index_of(separator)
            if index_option.is_none() {
                result = std::collection::push(result, remaining)
                return result
            }

            let index: usize = index_option.unwrap()
            result = std::collection::push(result, remaining.slice(0, index))

            let remaining_length: usize = remaining.length()
            let next_start: usize = index + separator_length
            if next_start >= remaining_length {
                result = std::collection::push(result, "")
                return result
            }

            let next_length: usize = remaining_length - next_start
            remaining = remaining.slice(next_start, next_length)
        }
    }

    # Scalar slice(start, count) (std). CLR host_provider must not flatten to String.Substring without conversion.
    [host_contract]
    micro slice(self, start: usize, count: usize) -> utf8 {
        let scalar_length: usize = self.length()
        if start > scalar_length {
            return Utf8Text { _repr: [] }
        }

        let start_index: usize = start
        let count_value: usize = count
        let start_byte: usize = self.byte_offset(start_index)
        let end_byte: usize = self.byte_offset(start_index + count_value)

        if start_byte >= self._repr.length() || start_byte >= end_byte {
            return Utf8Text { _repr: [] }
        }

        let mut bytes: [u8] = []
        let mut index: usize = start_byte
        while index < end_byte && index < self._repr.length() {
            bytes = std::collection::push(bytes, self._repr⁅index⁆)
            index = index + 1
        }

        return Utf8Text { _repr: bytes }
    }

    private micro char_width(self, index: usize) -> usize {
        if index >= self._repr.length() {
            return 0
        }

        let byte: u32 = self._repr⁅index⁆ as u32
        if byte <= 0x7F {
            return 1
        }

        if byte >= 0xC2 && byte <= 0xDF {
            return 2
        }

        if byte >= 0xE0 && byte <= 0xEF {
            return 3
        }

        if byte >= 0xF0 && byte <= 0xF4 {
            return 4
        }

        return 1
    }

    private micro byte_offset(self, char_index: usize) -> usize {
        let mut byte_index: usize = 0
        let mut current_char: usize = 0
        while byte_index < self._repr.length() && current_char < char_index {
            let width: usize = self.char_width(byte_index)
            if width == 0 {
                return byte_index
            }

            byte_index = byte_index + width
            current_char = current_char + 1
        }

        return byte_index
    }

    private micro index_of_repr(self, value: utf8) -> Option<usize> {
        if value._repr.length() == 0 {
            return Some(0)
        }

        if value._repr.length() > self._repr.length() {
            return std::types::option_none::<usize>()
        }

        let mut offset: usize = 0
        while offset + value._repr.length() <= self._repr.length() {
            let mut matched: bool = true
            let mut inner: usize = 0
            while inner < value._repr.length() {
                if self._repr⁅offset + inner⁆ != value._repr⁅inner⁆ {
                    matched = false
                    break
                }

                inner = inner + 1
            }

            if matched {
                let mut char_index: usize = 0
                let mut byte_index: usize = 0
                while byte_index < offset {
                    byte_index = byte_index + self.char_width(byte_index)
                    char_index = char_index + 1
                }

                return Some(char_index)
            }

            offset = offset + self.char_width(offset)
        }

        return std::types::option_none::<usize>()
    }

    micro char_at(self, index: usize) -> Option<char> {
        if index >= self.length() {
            return std::types::option_none::<char>()
        }
        let start: usize = self.byte_offset(index)
        if start >= self._repr.length() {
            return std::types::option_none::<char>()
        }
        let first: u8 = self._repr⁅start⁆
        let width: usize = self.char_width(start)
        let mut code_point: u32 = 0
        if width == 1 {
            code_point = first as u32
        }
        else if width == 2 && start + 1 < self._repr.length() {
            code_point = ((first as u32) & 0x1F) << 6
            code_point = code_point | ((self._repr⁅start + 1⁆ as u32) & 0x3F)
        }
        else if width == 3 && start + 2 < self._repr.length() {
            code_point = ((first as u32) & 0x0F) << 12
            code_point = code_point | (((self._repr⁅start + 1⁆ as u32) & 0x3F) << 6)
            code_point = code_point | ((self._repr⁅start + 2⁆ as u32) & 0x3F)
        }
        else if width == 4 && start + 3 < self._repr.length() {
            code_point = ((first as u32) & 0x07) << 18
            code_point = code_point | (((self._repr⁅start + 1⁆ as u32) & 0x3F) << 12)
            code_point = code_point | (((self._repr⁅start + 2⁆ as u32) & 0x3F) << 6)
            code_point = code_point | ((self._repr⁅start + 3⁆ as u32) & 0x3F)
        }
        else {
            code_point = first as u32
        }
        return Some(code_point as u16 as char)
    }

    micro chars(self) -> Utf8Iterator {
        return Utf8Iterator::new(self)
    }
}

imply Utf8Text: std::iterator::IntoIterator {
    type Item = char;
    type Iter = Utf8Iterator;

    micro into_iterator(self): Utf8Iterator {
        return self.chars()
    }
}

imply Utf8Text {
    private micro equals_repr(self, other_repr: [u8]) -> bool {
        if self._repr.length() != other_repr.length() {
            return false
        }
        let mut index: usize = 0
        while index < self._repr.length() {
            if self._repr⁅index⁆ != other_repr⁅index⁆ {
                return false
            }
            index = index + 1
        }
        return true
    }

    private micro concat_repr(self, other: utf8) -> utf8 {
        let mut bytes: [u8] = []
        let mut index: usize = 0
        while index < self._repr.length() {
            bytes = std::collection::push(bytes, self._repr⁅index⁆)
            index = index + 1
        }

        index = 0
        while index < other._repr.length() {
            bytes = std::collection::push(bytes, other._repr⁅index⁆)
            index = index + 1
        }

        return Utf8Text { _repr: bytes }
    }
}

# 0 基标量索引读写合同：`⁅ ⁆` / `⁅ ⁆=` 与同源的 `get_cardinal` / `set_cardinal`。
# 索引按 Unicode 标量计数（与 `length` 的计数单位一致）；`char` 是 u16 code unit，
# astral 标量无法表示（类型系统层缺口，已记录）。元素个数由 `length` 承担，与本合同无关。
imply Utf8Text: std::operator::Cardinal {
    type Element = char;

    # 0 基标量索引自动取值（UTF-8 解码为 `char`）；越界结构化失败（合同语义见 `std::operator::Cardinal`）。
    suffix `⁅ ⁆`(self, offset: usize): char {
        let found: Option<char> = self.char_at(offset)
        if found.is_none() {
            std::types::panic("Utf8Text ⁅ ⁆ 越界：offset 超出元素个数")
        }

        return found.unwrap()
    }

    # 按标量写入 `char`：新旧字符的 UTF-8 宽度可以不同，经 slice/concat 重建内部存储；
    # 替换一个标量为一个标量，元素个数不变，字节长度可变。越界结构化失败。
    suffix `⁅ ⁆=`(mut self, offset: usize, value: char): unit {
        let size: usize = self.length()
        if offset >= size {
            std::types::panic("Utf8Text ⁅ ⁆= 越界：offset 超出元素个数")
        }

        let head: utf8 = self.slice(0, offset)
        let tail: utf8 = self.slice(offset + 1, size - offset - 1)
        let replacement: utf8 = encode_char_as_utf8(value)
        self._repr = (head + replacement + tail)._repr
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

# `char`（u16 code unit）的 UTF-8 编码：1 至 3 字节。
# 已知缺口（类型系统层）：`char` 是 u16 code unit，astral 标量（> U+FFFF）无法表示，
# 本函数只需覆盖 u16 值域，不做代理对合成。
micro encode_char_as_utf8(code: char): utf8 {
    let value: u32 = code as u32
    if value <= 0x7F {
        return Utf8Text::from_bytes([value as u8])
    }

    if value <= 0x7FF {
        return Utf8Text::from_bytes([(0xC0 + (value >> 6)) as u8, (0x80 + (value & 0x3F)) as u8])
    }

    return Utf8Text::from_bytes([(0xE0 + (value >> 12)) as u8, (0x80 + ((value >> 6) & 0x3F)) as u8, (0x80 + (value & 0x3F)) as u8])
}

imply Utf8Text: std::operator::Equal {
    infix `==`(self, other: utf8): bool {
        return self.equals_repr(other._repr)
    }

    infix `!=`(self, other: utf8): bool {
        return !(self == other)
    }
}

imply Utf8Text: std::operator::Identical {
    infix `===`(self, other: utf8): bool {
        return self == other
    }

    infix `=!=`(self, other: utf8): bool {
        return self != other
    }
}
