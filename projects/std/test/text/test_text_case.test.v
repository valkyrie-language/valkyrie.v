# `to_lower` / `to_upper`：Unicode 默认全映射、locale 无关，逐码点映射。
# 非 BMP 字符超出 u16 `char` 表示范围，原样保留。
# 注：文本统一用 `from_bytes` 构造，避免依赖字面量的隐式转换。

[test]
micro `test utf8 case ascii`() {
    # "HeLLo123" → "hello123"
    let text: utf8 = Utf8Text::from_bytes([72 as u8, 101 as u8, 76 as u8, 76 as u8, 111 as u8, 49 as u8, 50 as u8, 51 as u8])

    if !text.to_lower().equals(Utf8Text::from_bytes([104 as u8, 101 as u8, 108 as u8, 108 as u8, 111 as u8, 49 as u8, 50 as u8, 51 as u8])) {
        panic("utf8 to_lower ascii failed")
    }

    if text.to_lower().byte_length() != 8 {
        panic("utf8 to_lower ascii byte length failed")
    }

    let lower: utf8 = Utf8Text::from_bytes([104 as u8, 101 as u8, 108 as u8, 108 as u8, 111 as u8])
    if !lower.to_upper().equals(Utf8Text::from_bytes([72 as u8, 69 as u8, 76 as u8, 76 as u8, 79 as u8])) {
        panic("utf8 to_upper ascii failed")
    }
}

[test]
micro `test utf8 case all uppercase to lowercase`() {
    # "ÄÖÜ"（C3 84 / C3 96 / C3 9C）→ "äöü"（C3 A4 / C3 B6 / C3 BC）。
    let text: utf8 = Utf8Text::from_bytes([195 as u8, 132 as u8, 195 as u8, 150 as u8, 195 as u8, 156 as u8])

    if !text.to_lower().equals(Utf8Text::from_bytes([195 as u8, 164 as u8, 195 as u8, 182 as u8, 195 as u8, 188 as u8])) {
        panic("utf8 to_lower uppercase pairs failed")
    }

    if text.to_lower().length() != 3 {
        panic("utf8 to_lower uppercase pairs count failed")
    }
}

[test]
micro `test utf8 case empty string`() {
    let empty: utf8 = Utf8Text::from_bytes([])

    if empty.to_lower().byte_length() != 0 {
        panic("utf8 to_lower empty must be empty")
    }

    if empty.to_upper().byte_length() != 0 {
        panic("utf8 to_upper empty must be empty")
    }

    if empty.to_lower().length() != 0 {
        panic("utf8 to_lower empty length failed")
    }
}

[test]
micro `test utf8 case non bmp preserved`() {
    # U+1F600（F0 9F 98 80）超出 u16 `char`：原样保留，不参与映射。
    let text: utf8 = Utf8Text::from_bytes([240 as u8, 159 as u8, 152 as u8, 128 as u8])

    if !text.to_lower().equals(text) {
        panic("utf8 to_lower non bmp must stay unchanged")
    }

    if !text.to_upper().equals(text) {
        panic("utf8 to_upper non bmp must stay unchanged")
    }

    if text.to_lower().byte_length() != 4 {
        panic("utf8 to_lower non bmp byte length failed")
    }

    if text.to_lower().length() != 1 {
        panic("utf8 to_lower non bmp code point count failed")
    }
}

[test]
micro `test utf8 case sharp s expands`() {
    # "ß"（U+00DF，C3 9F）大写是 1→多："SS"（53 53），长度从 1 变 2。
    let text: utf8 = Utf8Text::from_bytes([195 as u8, 159 as u8])

    if text.to_upper().byte_length() != 2 {
        panic("utf8 to_upper sharp s byte length failed")
    }

    if text.to_upper().length() != 2 {
        panic("utf8 to_upper sharp s code point count failed")
    }

    if text.to_upper().byte_at(0) != 83 as u8 {
        panic("utf8 to_upper sharp s first byte failed")
    }

    if text.to_upper().byte_at(1) != 83 as u8 {
        panic("utf8 to_upper sharp s second byte failed")
    }
}

[test]
micro `test utf8 case dotted capital i expands`() {
    # "İ"（U+0130，C4 B0）小写是 1→多："i" + U+0307（69 CC 87）。
    let text: utf8 = Utf8Text::from_bytes([196 as u8, 176 as u8])
    let lowered: utf8 = text.to_lower()

    if lowered.byte_length() != 3 {
        panic("utf8 to_lower dotted i byte length failed")
    }

    if lowered.length() != 2 {
        panic("utf8 to_lower dotted i code point count failed")
    }

    if lowered.byte_at(0) != 105 as u8 {
        panic("utf8 to_lower dotted i first byte failed")
    }

    if lowered.byte_at(1) != 204 as u8 {
        panic("utf8 to_lower dotted i combining mark first byte failed")
    }

    if lowered.byte_at(2) != 135 as u8 {
        panic("utf8 to_lower dotted i combining mark second byte failed")
    }
}

[test]
micro `test utf8 case n apostrophe and j caron expand`() {
    # "ŉ"（U+0149，C5 89）大写是 "ʼN"（U+02BC + N）。
    let napostrophe: utf8 = Utf8Text::from_bytes([197 as u8, 137 as u8])
    if napostrophe.to_upper().byte_length() != 3 {
        panic("utf8 to_upper napostrophe byte length failed")
    }

    if napostrophe.to_upper().length() != 2 {
        panic("utf8 to_upper napostrophe code point count failed")
    }

    if napostrophe.to_upper().byte_at(2) != 78 as u8 {
        panic("utf8 to_upper napostrophe trailing N failed")
    }

    # "ǰ"（U+01F0，C7 B0）大写是 "J" + U+030C（4A CC 8C）。
    let jcaron: utf8 = Utf8Text::from_bytes([199 as u8, 176 as u8])
    if jcaron.to_upper().byte_length() != 3 {
        panic("utf8 to_upper j caron byte length failed")
    }

    if jcaron.to_upper().byte_at(0) != 74 as u8 {
        panic("utf8 to_upper j caron leading J failed")
    }

    if jcaron.to_upper().byte_at(1) != 204 as u8 {
        panic("utf8 to_upper j caron combining mark first byte failed")
    }
}

[test]
micro `test utf8 case final sigma at word end`() {
    # "ΑΣ" 小写是 "ας"：词尾 Σ 变成 ς（U+03C2，CE C2）。
    let text: utf8 = Utf8Text::from_bytes([206 as u8, 145 as u8, 206 as u8, 163 as u8])
    let lowered: utf8 = text.to_lower()

    if lowered.byte_length() != 4 {
        panic("utf8 to_lower final sigma byte length failed")
    }

    if lowered.byte_at(2) != 206 as u8 {
        panic("utf8 to_lower final sigma lead byte failed")
    }

    if lowered.byte_at(3) != 194 as u8 {
        panic("utf8 to_lower final sigma must be U+03C2")
    }
}

[test]
micro `test utf8 case sigma not final`() {
    # "ΣΑ" 小写是 "σα"：Σ 后面还有字母，不是词尾。
    let text: utf8 = Utf8Text::from_bytes([206 as u8, 163 as u8, 206 as u8, 145 as u8])
    let lowered: utf8 = text.to_lower()

    if lowered.byte_at(1) != 195 as u8 {
        panic("utf8 to_lower non final sigma must be U+03C3")
    }

    # 单独的 "Σ" 前面没有 Cased，也不构成词尾 Sigma，保持 σ。
    let lone: utf8 = Utf8Text::from_bytes([206 as u8, 163 as u8])
    if lone.to_lower().byte_at(1) != 195 as u8 {
        panic("utf8 to_lower lone sigma must be U+03C3")
    }
}
