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
        let mut bytes: ArrayList<u8> = ArrayList::new(text.byte_length())
        let repr: [u8] = text.bytes()
        let mut index: usize = 0
        while index < repr.length() {
            bytes.push(repr⁅index⁆)
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
    ⍝ 编码内核收口到 `std.text.encoding`（`encode_char`）；非 Unicode 标量码位
    ⍝ 在编码边界显式失败，不产出畸形字节。
    micro append(mut self, c: char): unit {
        push_char(self.bytes, c)
    }

    ⍝ 在开头插入一个字符，与 `append` 共用同一码位编码点。
    micro prepend(mut self, c: char): unit {
        let mut merged: ArrayList<u8> = ArrayList::new(self.bytes.length() + 4)
        push_char(merged, c)
        let mut index: usize = 0
        while index < self.bytes.length() {
            merged.push(self.bytes.get((index + 1) as isize).unwrap())
            index = index + 1
        }

        self.bytes = merged
    }

    micro append(mut self, text: &Utf8Text): unit {
        let repr: [u8] = text.bytes()
        let mut index: usize = 0
        while index < repr.length() {
            self.bytes.push(repr⁅index⁆)
            index = index + 1
        }
    }

    ⍝ 追加另一个构造器的全部内容，并消耗对方
    micro concat(mut self, other: Self) -> Self {
        let mut index: usize = 0
        while index < other.bytes.length() {
            self.bytes.push(other.bytes.get((index + 1) as isize).unwrap())
            index = index + 1
        }

        return self
    }

    ⍝ 消耗构造器，生成不可变文本。
    ⍝ 类型不变量：字节只经三条通道进入——编码内核（`push_char`，标量已验证）、
    ⍝ 已验证文本（`append(&Utf8Text)`）与十进制内核（ASCII 数字），
    ⍝ 故产物良构，直接走 unchecked 重建。
    micro build(self) -> Utf8Text {
        return Utf8Text::from_bytes_unchecked(self.bytes.to_array())
    }

    infix `+=`(mut self, c: char): unit {
        self.append(c)
    }

    infix `+=`(mut self, text: &Utf8Text): unit {
        self.append(text)
    }

    ⍝ 追加有符号整数的十进制表示（不含前导零）：与 `Display` 共用唯一整数
    ⍝ 格式化内核（`format.v` 的 `write_decimal_i64`）；最小负数（`i64::MIN`）
    ⍝ 走无符号幅值路径，不先取负、不回绕。
    micro append_i64(mut self, value: i64): unit {
        write_decimal_i64(self.bytes, value)
    }
}


⍝ `append` 与 `prepend` 共用的 UTF-8 码位编码点：直接消费 `std.text.encoding`
⍝ 的 `encode_char`（唯一编码内核），本文件不再内联第二份位运算编码。
⍝ 非 Unicode 标量码位（代理项、> U+10FFFF）在 `encode_char` 处显式失败。
private micro push_char(mut bytes: ArrayList<u8>, c: char): unit {
    let encoded: [u8] = encode_char(c)
    let mut index: usize = 0
    while index < encoded.length() {
        bytes.push(encoded⁅index⁆)
        index = index + 1
    }
}


