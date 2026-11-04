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

    # 字节视图：显式按字节读取内部 UTF-8 存储，与码点索引空间（`Cardinal`/`Ordinal`）分离。
    # 码元、字素、字形各有自己的显式视图/API（本类型暂无），不把多种索引口径塞进同一个 `Index`。
    micro bytes(self): [u8] {
        return self._repr
    }

    # 按字节偏移读取单个字节，O(1)；越界结构化失败。
    # 调用方不查边界时用 `⁅ ⁆`（同源委托），需要 `Option` 语义时自行先比长度。
    micro byte_at(self, offset: usize): u8 {
        if offset >= self._repr.length() {
            std::types::panic("Utf8Text byte_at 越界：offset 超出字节长度")
        }

        return self._repr⁅offset⁆
    }

    # `start`（字节偏移）处码点的 UTF-8 宽度（1..4），O(1)；越界返回 0。
    # 低层解码原语，供 `character_at` 与迭代器共用（单一实现来源）。
    micro char_width_at(self, start: usize) -> usize {
        if start >= self._repr.length() {
            return 0
        }

        let byte: u32 = self._repr⁅start⁆ as u32
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

    # 按字节偏移解码一个码点为 `char`（`start` 必须是码点边界，由调用点保证），O(1)。
    # 解码逻辑只此一份：`character_at`、序数合同与迭代器全部经由本方法。
    micro character_at_byte(self, start: usize) -> char {
        let first: u8 = self._repr⁅start⁆
        let width: usize = self.char_width_at(start)
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

        return code_point as u16 as char
    }

    # 取第 `index` 个码点（0 基）解码为 `char`。定位需从头扫描，单次 O(n)——
    # 只用于偶发单点查询；顺序扫描一律用 `byte_indicates` / `Utf8Iterator`
    # （均摊 O(1) 前进），把 `character_at` 放进循环就是 O(n²)。
    micro character_at(self, index: usize): char {
        if index >= self.length() {
            std::types::panic("Utf8Text character_at 越界：index 超出元素个数")
        }

        return self.character_at_byte(self.byte_offset(index))
    }

    # Unicode scalar count (std). CLR host_provider must not flatten to String.get_Length.
    [host_contract]
    micro length(self) -> usize {
        let mut index: usize = 0
        let mut count: usize = 0
        while index < self._repr.length() {
            let width: usize = self.char_width_at(index)
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
        let mut result: ArrayList<utf8> = ArrayList::new(0)
        let separator_length: usize = separator.length()

        if separator_length == 0 {
            result.push(self)
            return result.to_array()
        }

        let mut remaining: utf8 = self
        while true {
            let index_option: Option<usize> = remaining.index_of(separator)
            if index_option.is_none() {
                result.push(remaining)
                return result.to_array()
            }

            let index: usize = index_option.unwrap()
            result.push(remaining.slice(0, index))

            let remaining_length: usize = remaining.length()
            let next_start: usize = index + separator_length
            if next_start >= remaining_length {
                result.push("")
                return result.to_array()
            }

            let next_length: usize = remaining_length - next_start
            remaining = remaining.slice(next_start, next_length)
        }
    }

    # 严格宿主切片：越界区间由宿主结构化失败，不做任何截断。
    # 各 lane 用自身宿主实现覆盖；默认实现按标量边界逐字节拷贝，越界显式失败。
    [host_contract]
    micro host_slice(self, start: i32, count: i32) -> utf8 {
        let scalar_length: usize = self.length()
        let begin: usize = start as usize
        let take: usize = count as usize
        if begin > scalar_length || take > scalar_length - begin {
            std::types::panic("Utf8Text host_slice 越界：start/count 超出标量范围")
        }

        let start_byte: usize = self.byte_offset(begin)
        let end_byte: usize = self.byte_offset(begin + take)
        let mut bytes: ArrayList<u8> = ArrayList::new(0)
        let mut index: usize = start_byte
        while index < end_byte {
            bytes.push(self._repr⁅index⁆)
            index = index + 1
        }

        return Utf8Text { _repr: bytes.to_array() }
    }

    # 总函数（total）：`start` / `count` 越界时静默截断，绝不向调用方暴露失败。
    # 这里显式 clamp 成有效标量区间后再调严格宿主切片——
    # 宿主对越界区间结构化失败，兜底责任在本函数，不在宿主。
    [host_contract]
    micro slice(self, start: usize, count: usize) -> utf8 {
        let scalar_length: usize = self.length()
        let mut begin: usize = start
        if begin > scalar_length {
            begin = scalar_length
        }

        let remaining: usize = scalar_length - begin
        let mut take: usize = count
        if take > remaining {
            take = remaining
        }

        return self.host_slice(begin as i32, take as i32)
    }

    # 严格路径：`start` 超过长度或 `count` 超过剩余标量数时返回 `None`，不做截断。
    # `count` 只用比较、不与 `start` 相加，因此不存在整数溢出路径。
    micro try_slice(self, start: usize, count: usize) -> Option<utf8> {
        let scalar_length: usize = self.length()
        if start > scalar_length {
            return None
        }

        if count > scalar_length - start {
            return None
        }

        return Some(self.host_slice(start as i32, count as i32))
    }

    private micro byte_offset(self, char_index: usize) -> usize {
        let mut byte_index: usize = 0
        let mut current_char: usize = 0
        while byte_index < self._repr.length() && current_char < char_index {
            let width: usize = self.char_width_at(byte_index)
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
            return None
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
                    byte_index = byte_index + self.char_width_at(byte_index)
                    char_index = char_index + 1
                }

                return Some(char_index)
            }

            offset = offset + self.char_width_at(offset)
        }

        return None
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
        let mut bytes: ArrayList<u8> = ArrayList::new(self._repr.length() + other._repr.length())
        let mut index: usize = 0
        while index < self._repr.length() {
            bytes.push(self._repr⁅index⁆)
            index = index + 1
        }

        index = 0
        while index < other._repr.length() {
            bytes.push(other._repr⁅index⁆)
            index = index + 1
        }

        return Utf8Text { _repr: bytes.to_array() }
    }
}

# 0 基字节索引合同：`⁅ ⁆` ≡ `byte_at`（返回 `u8`），O(1)；写入同理按字节。
# 字符（码点）访问不走本合同——走序数 `[ ]` / `character_at`。
# `char` 是 u16 code unit，astral 标量无法表示（类型系统层限制）。
imply Utf8Text: std::operator::Cardinal {
    type Element = u8;
    type Index = usize;

    # 0 基字节索引自动取值，O(1)；越界结构化失败（合同语义见 `std::operator::Cardinal`）。
    # 单一实现来源：本算子只委托 `byte_at`，不内联第二份读取逻辑。
    suffix `⁅ ⁆`(self, offset: usize): u8 {
        return self.byte_at(offset)
    }

    # 0 基字节写入，只改该字节不改长度；写进多字节码点内部会破坏编码，
    # 属调用方责任（字节级合同是原始视图）。越界结构化失败。
    suffix `⁅ ⁆=`(mut self, offset: usize, value: u8): unit {
        if offset >= self._repr.length() {
            std::types::panic("Utf8Text ⁅ ⁆= 越界：offset 超出字节长度")
        }

        self._repr⁅offset⁆ = value
    }

    # 与 `⁅ ⁆` 同源：命名方法形态，互为委托。
    micro get_cardinal(self, offset: usize): u8 {
        return self.byte_at(offset)
    }

    # 与 `⁅ ⁆=` 同源：命名方法形态，互为委托。
    micro set_cardinal(mut self, offset: usize, value: u8): unit {
        self⁅offset⁆ = value
    }
}

# 1 基序数读写合同：`[ ]` / `[ ]=` 与同源的 `get` / `set`，索引空间是 Unicode
# 标量（码点）。定位第 index 个字符必须从头扫描，单次 O(n)——只用于偶发单点
# 查询；顺序扫描一律用 `byte_indicates` / `Utf8Iterator`（均摊 O(1) 前进），
# 把 `text[index]` 放进循环就是 O(n²)，热路径禁止。`Index` 取 `isize`（负数落入
# 越界判定，下标结构化失败、可恢复形态走 `get`）；实际访问委托 `character_at`，
# 本 impl 不内联解码。
imply Utf8Text: std::operator::Ordinal {
    type Index = isize;
    type Element = char;

    # 序数 1 基，裸 `char` 读取；越界结构化失败。单次 O(n)。
    suffix `[ ]`(self, ordinal: isize): char {
        if ordinal < 1 || ordinal > self.length() as isize {
            std::types::panic("Ordinal [ ] 越界：序数超出 [1, 元素个数]")
        }

        return self.character_at((ordinal - 1) as usize)
    }

    # 命名读路径：可恢复形态，越界返回 `None`。单次 O(n)。
    micro get(self, ordinal: isize): Option<char> {
        if ordinal < 1 || ordinal > self.length() as isize {
            return None
        }

        return Some(self.character_at((ordinal - 1) as usize))
    }

    # 按标量写入 `char`：新旧字符的 UTF-8 宽度可以不同，经 slice/concat 重建内部
    # 存储；替换一个标量为一个标量，元素个数不变，字节长度可变。越界结构化失败。
    suffix `[ ]=`(mut self, ordinal: isize, value: char): unit {
        if ordinal < 1 || ordinal > self.length() as isize {
            std::types::panic("Ordinal [ ]= 越界：序数超出 [1, 元素个数]")
        }

        let index: usize = (ordinal - 1) as usize
        let size: usize = self.length()
        let head: utf8 = self.slice(0, index)
        let tail: utf8 = self.slice(index + 1, size - index - 1)
        let replacement: utf8 = encode_char_as_utf8(value)
        self._repr = (head + replacement + tail)._repr
    }

    # 与 `[ ]=` 同源：命名方法形态，互为委托。
    micro set(mut self, ordinal: isize, value: char): unit {
        self[ordinal] = value
    }
}

# ── 线性扫描迭代器 ─────────────────────────────────────────────
# `byte_indicates`：一次线性扫描同时产出字节偏移与字符（`(usize, char)` 二元组）。
# 总代价 O(n)、均摊 O(1)/元素（解出字符后直接跳过整个码点，不重新从头扫）；
# 产出的偏移是字节偏移，可直接用于 `slice` / `byte_at`。
structure Utf8ByteIndicator {
    text: &Utf8Text
    offset: usize
}

micro byte_indicates(text: &Utf8Text) -> Utf8ByteIndicator {
    return Utf8ByteIndicator { text: text, offset: 0 }
}

# 从指定字节偏移起步（切片/回退重扫用）：`offset` 必须落在码点边界；
# 不在边界（指向续字节）或越出字节长度即结构化失败。
micro byte_indicates_from(text: &Utf8Text, offset: usize) -> Utf8ByteIndicator {
    if offset > text.byte_length() {
        std::types::panic("byte_indicates_from 越界：offset 超出字节长度")
    }
    if offset < text.byte_length() {
        let lead: u32 = text.byte_at(offset) as u32
        if (lead & 0xC0) == 0x80 {
            std::types::panic("byte_indicates_from 的 offset 不在码点边界")
        }
    }
    return Utf8ByteIndicator { text: text, offset: offset }
}

imply Utf8ByteIndicator: std::iterator::Iterator {
    type Item = (usize, char);

    micro has_next(self) -> bool {
        return self.offset < self.text.byte_length()
    }

    micro next(mut self) -> Option<(usize, char)> {
        if !self.has_next() {
            return None
        }

        let start: usize = self.offset
        let ch: char = self.text.character_at_byte(start)
        self.offset = self.offset + self.text.char_width_at(start)
        return Some((start, ch))
    }
}

# `char`（u16 code unit）的 UTF-8 编码：1 至 3 字节。
# 限制说明：`char` 是 u16 code unit，astral 标量（> U+FFFF）无法表示，
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

# 字节序比较：按内部 UTF-8 字节逐字节无符号比较，前缀关系以长度决胜
# （短者为 `Less`）。这是编码字节的字典序，不引入区域规则、大小写折叠或
# Unicode 规范化；返回 `Equal` 当且仅当两侧字节完全相同，与 `==` 一致。
imply Utf8Text: std::operator::Comparable {
    micro compare(self, other: Self): std::operator::Ordering {
        let left: [u8] = self._repr
        let right: [u8] = other._repr
        let left_length: usize = left.length()
        let right_length: usize = right.length()
        let mut limit: usize = right_length
        if left_length < right_length {
            limit = left_length
        }

        let mut index: usize = 0
        while index < limit {
            # 字节扩宽到 `i32` 再比较：无符号字节序不变，也不依赖 `u8` 比较算子的宿主 provider。
            let left_byte: i32 = (left⁅index⁆) as i32
            let right_byte: i32 = (right⁅index⁆) as i32
            if left_byte < right_byte {
                return std::operator::Ordering.Less
            }
            if left_byte > right_byte {
                return std::operator::Ordering.Greater
            }
            index = index + 1
        }

        if left_length < right_length {
            return std::operator::Ordering.Less
        }
        if left_length > right_length {
            return std::operator::Ordering.Greater
        }
        return std::operator::Ordering.Equal
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
