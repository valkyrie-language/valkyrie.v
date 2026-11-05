namespace unicode.case;

# 文本级大小写映射：Unicode 默认全映射、locale 无关（不做土耳其语 `I→ı`）。
# 顺序：Final_Sigma 上下文 → `SpecialCasing` 1→多 → `UnicodeData` simple → 原样。
# 非 BMP（UTF-8 4 字节、超出 u16 `char`）原样拷贝，不参与映射，也不参与上下文判定。
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

# 追加 1→多记录（`special_find` 返回的记录起点）。
# 下标运算全部用 `usize`：混用 `usize` 与 `u32` 会让 `⁅ ⁆` 与 `+` 的重载解析失败。
private micro push_special(bytes: ArrayList<u8>, entries: [char], index: usize) {
    let count: u32 = entries⁅index + 1⁆ as u32
    let limit: usize = count as usize
    let mut item: usize = 0
    while item < limit {
        push_code_point(bytes, entries⁅index + 2 + item⁆ as u32)
        item = item + 1
    }
}

# 原样拷贝 4 字节序列（非 BMP，`char` 无法表达）。
private micro push_raw(value: std.text.Utf8Text, bytes: ArrayList<u8>, cursor: usize) {
    bytes.push(value.byte_at(cursor))
    bytes.push(value.byte_at(cursor + 1))
    bytes.push(value.byte_at(cursor + 2))
    bytes.push(value.byte_at(cursor + 3))
}

# 前一个码点的起始字节偏移（`cursor` 必须 > 0）。
private micro previous_code_point_start(value: std.text.Utf8Text, cursor: usize) -> usize {
    let mut start: usize = cursor - 1
    while start > 0 && (value.byte_at(start) as u32) & 0xC0 == 0x80 {
        start = start - 1
    }

    return start
}

# Final_Sigma（UAX #29 词边界下的 Unicode 3.13 规则）：
#   Σ 变成 ς 当且仅当「前面有 Cased（可跳过若干 Case_Ignorable）」且
#   「后面不是（Case_Ignorable* Cased）」。
# 判定逐码点进行：向前跳过 Case_Ignorable 后必须遇到 Cased；
# 向后跳过 Case_Ignorable 后遇到的下一个码点不得是 Cased（到串尾视为满足）。
# 非 BMP 码点按 `char` 无法表达，不参与上下文判定（记为缺口）。
private micro is_final_sigma(value: std.text.Utf8Text, cursor: usize) -> bool {
    let size: usize = value.byte_length()

    let mut start: usize = cursor
    let mut seen_cased: bool = false
    while start > 0 {
        start = previous_code_point_start(value, start)
        let code: u32 = value.character_at_byte(start) as u32
        if is_case_ignorable(code) {
            continue
        }

        seen_cased = is_cased(code)
        break
    }

    if !seen_cased {
        return false
    }

    let mut next: usize = cursor + value.char_width_at(cursor)
    while next < size {
        let code: u32 = value.character_at_byte(next) as u32
        if is_case_ignorable(code) {
            next = next + value.char_width_at(next)
            continue
        }

        return !is_cased(code)
    }

    return true
}

micro text_to_lower(value: std.text.Utf8Text) -> std.text.Utf8Text {
    let special: [char] = unicode_case_lower_special()
    let mut bytes: ArrayList<u8> = ArrayList::new(value.byte_length())
    let size: usize = value.byte_length()
    let mut cursor: usize = 0
    while cursor < size {
        let width: usize = value.char_width_at(cursor)
        if width == 4 {
            push_raw(value, bytes, cursor)
            cursor = cursor + width
            continue
        }

        let code: u32 = value.character_at_byte(cursor) as u32
        if code == 0x03A3 && is_final_sigma(value, cursor) {
            push_code_point(bytes, 0x03C2)
        }
        else {
            let index: usize = special_find(special, code)
            if index < special.length() {
                push_special(bytes, special, index)
            }
            else {
                push_code_point(bytes, lower_simple(value.character_at_byte(cursor)) as u32)
            }
        }

        cursor = cursor + width
    }

    return std.text::Utf8Text::from_bytes(bytes.to_array())
}

micro text_to_upper(value: std.text.Utf8Text) -> std.text.Utf8Text {
    let special: [char] = unicode_case_upper_special()
    let mut bytes: ArrayList<u8> = ArrayList::new(value.byte_length())
    let size: usize = value.byte_length()
    let mut cursor: usize = 0
    while cursor < size {
        let width: usize = value.char_width_at(cursor)
        if width == 4 {
            push_raw(value, bytes, cursor)
            cursor = cursor + width
            continue
        }

        let code: u32 = value.character_at_byte(cursor) as u32
        let index: usize = special_find(special, code)
        if index < special.length() {
            push_special(bytes, special, index)
        }
        else {
            push_code_point(bytes, upper_simple(value.character_at_byte(cursor)) as u32)
        }

        cursor = cursor + width
    }

    return std.text::Utf8Text::from_bytes(bytes.to_array())
}
