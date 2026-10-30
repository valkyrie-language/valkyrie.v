namespace std.text;

⍝ ────────── 可变文本构造器 ──────────
⍝ 集中处理所有修改操作，最终产出不可变的 `Utf8Text`。
⍝ 内部使用 `ArrayList<u8>` 累积字节，避免频繁扩容时反复创建新数组。
class Utf8Builder {
    ⍝ 只读暴露底层字节，便于外部检查，但禁止直接赋值
    [get] bytes: ArrayList<u8>
}

imply Utf8Builder {
    ⍝ 创建一个空构造器
    micro new(capacity: usize) -> Self {
        return Utf8Builder { bytes: ArrayList::new(capacity) }
    }

    ⍝ 从已存在文本创建一个构造器, 该文本会被消耗
    micro new(text: Utf8Text) -> Self {
        let mut bytes: ArrayList<u8> = ArrayList::new(text._repr.length)
        let mut index: usize = 0
        while index < text._repr.length {
            bytes.push(text._repr⁅index⁆)
            index = index + 1
        }

        return Utf8Builder { bytes: bytes }
    }

    micro is_empty(self) -> bool {
        return self.bytes.is_empty()
    }

    micro byte_length(self) -> usize {
        return self.bytes.length()
    }

    ⍝ 追加一个字符：按 UTF-8 规则把码位编码为 1..4 个字节。
    ⍝ `char` 没有 `to_bytes` 成员；位运算一律走 `bit_and` / `bit_or` / `bit_shift_right` 具名方法。
    micro append(mut self, c: char): unit {
        let code: u32 = c as u32
        if code <= 127 {
            self.bytes.push(code as u8)
        }
        else if code <= 2047 {
            self.bytes.push((192 + code.bit_shift_right(6)) as u8)
            self.bytes.push((128 + code.bit_and(63)) as u8)
        }
        else if code <= 65535 {
            self.bytes.push((224 + code.bit_shift_right(12)) as u8)
            self.bytes.push((128 + code.bit_shift_right(6).bit_and(63)) as u8)
            self.bytes.push((128 + code.bit_and(63)) as u8)
        }
        else {
            self.bytes.push((240 + code.bit_shift_right(18)) as u8)
            self.bytes.push((128 + code.bit_shift_right(12).bit_and(63)) as u8)
            self.bytes.push((128 + code.bit_shift_right(6).bit_and(63)) as u8)
            self.bytes.push((128 + code.bit_and(63)) as u8)
        }
    }

    micro append(mut self, text: &Utf8Text): unit {
        let mut index: usize = 0
        while index < text._repr.length {
            self.bytes.push(text._repr⁅index⁆)
            index = index + 1
        }
    }

    ⍝ 追加另一个构造器的全部内容，并消耗对方
    micro concat(mut self, other: Self) -> Self {
        let mut index: usize = 0
        while index < other.bytes.length() {
            self.bytes.push(other.bytes.get(index + 1).unwrap())
            index = index + 1
        }

        return self
    }

    ⍝ 消耗构造器，生成不可变文本
    micro build(self) -> Utf8Text {
        let mut bytes: [u8] = []
        let mut index: usize = 0
        while index < self.bytes.length() {
            ⍝ `push` 是函数式追加（返回新数组），必须写回，否则 `bytes` 恒为空。
            bytes = std::collection::push(bytes, self.bytes.get(index + 1).unwrap())
            index = index + 1
        }

        return Utf8Text::from_bytes_unchecked(bytes)
    }

    infix `+=`(mut self, c: char): unit {
        self.append(c)
    }

    infix `+=`(mut self, text: &Utf8Text): unit {
        self.append(text)
    }

    ⍝ 追加有符号整数的十进制表示（不含前导零；`-2147483648` 等边界按 i64 规则处理）
    micro append_i64(mut self, value: i64): unit {
        if value == 0 {
            self.bytes.push(48)
            return
        }

        let mut v: i64 = value
        if v < 0 {
            self.bytes.push(45)
            v = -v
        }

        let mut digits: ArrayList<u8> = ArrayList::new(21)
        while v > 0 {
            let digit: u8 = (v % 10) as u8
            digits.push(48 + digit)
            v = v / 10
        }

        let mut index: usize = digits.length()
        while index > 0 {
            index = index - 1
            self.bytes.push(digits⁅index⁆.unwrap())
        }
    }
}


