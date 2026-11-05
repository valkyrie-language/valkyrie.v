# `to_lower` / `to_upper`：Unicode 默认全映射、locale 无关，逐码点映射。
# 非 BMP 字符超出 u16 `char` 表示范围，原样保留。
# 注：`let text: utf8 = "…"` 在 OVM 下受别名缺陷影响，这里统一用 `from_bytes` 构造。

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
