namespace unicode.case;

# 文本级大小写映射：Unicode 默认全映射、locale 无关（不做土耳其语 `I→ı`）。
# 本文件只做 simple 映射；1→多（`ß→SS`、`İ→i̇`）与 Final_Sigma 在后续实现。
# 非 BMP（UTF-8 4 字节、超出 u16 `char`）原样拷贝，不参与映射。
# `std` 只保留 `Utf8Text::to_lower` / `to_upper` 的签名，实现经 `[host_provider]`
# 委托到本包，因此 UCD 版本固定在 `unicode.case`，std 语义不随版本漂移。
#
# 为什么不用 `std.text.Utf8Builder`：`Utf8Builder.append` 的重载解析在跨包调用时
# 会与 `std.collection.LiteralSequence.append` 冲突，编译器报 “trait 约束未解析：
# LiteralSequence”。这里改用 `ArrayList<u8>` 逐码点编码追加，语义等价（变长输出），
# 不依赖那个跨包缺陷。`char` 是 u16，最多编码 3 个字节。

# 把一个码点按 UTF-8 规则追加到字节缓冲：`char` 上界 U+FFFF，故最多 3 字节。
private micro push_code_point(bytes: ArrayList<u8>, code: u32) {
    if code <= 0x7F {
        bytes.push(code as u8)
    }
    else if code <= 0x7FF {
        bytes.push((0xC0 + code.bit_shift_right(6)) as u8)
        bytes.push((0x80 + code.bit_and(0x3F)) as u8)
    }
    else {
        bytes.push((0xE0 + code.bit_shift_right(12)) as u8)
        bytes.push((0x80 + code.bit_shift_right(6).bit_and(0x3F)) as u8)
        bytes.push((0x80 + code.bit_and(0x3F)) as u8)
    }
}

micro text_to_lower(value: std.text.Utf8Text) -> std.text.Utf8Text {
    let mut bytes: ArrayList<u8> = ArrayList::new(value.byte_length())
    let size: usize = value.byte_length()
    let mut cursor: usize = 0
    while cursor < size {
        let width: usize = value.char_width_at(cursor)
        if width == 4 {
            bytes.push(value.byte_at(cursor))
            bytes.push(value.byte_at(cursor + 1))
            bytes.push(value.byte_at(cursor + 2))
            bytes.push(value.byte_at(cursor + 3))
            cursor = cursor + width
        }
        else {
            let mapped: char = lower_simple(value.character_at_byte(cursor))
            push_code_point(bytes, mapped as u32)
            cursor = cursor + width
        }
    }

    return std.text::Utf8Text::from_bytes(bytes.to_array())
}

micro text_to_upper(value: std.text.Utf8Text) -> std.text.Utf8Text {
    let mut bytes: ArrayList<u8> = ArrayList::new(value.byte_length())
    let size: usize = value.byte_length()
    let mut cursor: usize = 0
    while cursor < size {
        let width: usize = value.char_width_at(cursor)
        if width == 4 {
            bytes.push(value.byte_at(cursor))
            bytes.push(value.byte_at(cursor + 1))
            bytes.push(value.byte_at(cursor + 2))
            bytes.push(value.byte_at(cursor + 3))
            cursor = cursor + width
        }
        else {
            let mapped: char = upper_simple(value.character_at_byte(cursor))
            push_code_point(bytes, mapped as u32)
            cursor = cursor + width
        }
    }

    return std.text::Utf8Text::from_bytes(bytes.to_array())
}
