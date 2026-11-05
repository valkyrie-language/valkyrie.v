# `trim` 按 Unicode White_Space（25 个码点）裁首尾，U+200B / U+FEFF 不算空白。
# `replace` 从左到右非重叠全部替换；空模式返回原串，空替换即删除。
# 注：`let text: utf8 = "…"` 在 OVM 下受别名缺陷影响，这里统一用 `from_bytes` 构造。

[test]
micro `test utf8 trim unicode whitespace`() {
    # 空格、制表符、U+3000 表意空格 + "abc" + U+0085(NEL)、空格
    let text: utf8 = Utf8Text::from_bytes([32 as u8, 9 as u8, 227 as u8, 128 as u8, 128 as u8, 97 as u8, 98 as u8, 99 as u8, 194 as u8, 133 as u8, 32 as u8])

    if !text.trim().equals(Utf8Text::from_bytes([97 as u8, 98 as u8, 99 as u8])) {
        panic("utf8 trim unicode whitespace failed")
    }

    if text.trim().byte_length() != 3 {
        panic("utf8 trim unicode whitespace byte length failed")
    }

    # 内部空白保留：U+0085 只在首尾被裁，中间不动。
    let middle: utf8 = Utf8Text::from_bytes([32 as u8, 97 as u8, 9 as u8, 98 as u8, 32 as u8])
    if !middle.trim().equals(Utf8Text::from_bytes([97 as u8, 9 as u8, 98 as u8])) {
        panic("utf8 trim inner whitespace failed")
    }
}

[test]
micro `test utf8 trim keeps zero width and bom`() {
    # U+200B（E2 80 8B）+ "ab" + U+FEFF（EF BB BF）：两者都不是 White_Space。
    let text: utf8 = Utf8Text::from_bytes([226 as u8, 128 as u8, 139 as u8, 97 as u8, 98 as u8, 239 as u8, 187 as u8, 191 as u8])

    if text.trim().byte_length() != 8 {
        panic("utf8 trim must keep U+200B and U+FEFF")
    }

    if text.trim().length() != 4 {
        panic("utf8 trim zero width codepoint count failed")
    }
}

[test]
micro `test utf8 trim all whitespace becomes empty`() {
    let text: utf8 = Utf8Text::from_bytes([32 as u8, 9 as u8, 194 as u8, 133 as u8])

    if text.trim().byte_length() != 0 {
        panic("utf8 trim all whitespace must be empty")
    }

    if text.trim().length() != 0 {
        panic("utf8 trim all whitespace length failed")
    }

    if Utf8Text::from_bytes([]).trim().length() != 0 {
        panic("utf8 trim empty string failed")
    }
}

[test]
micro `test utf8 replace non overlapping`() {
    let text: utf8 = Utf8Text::from_bytes([97 as u8, 97 as u8, 97 as u8])

    if !text.replace(Utf8Text::from_bytes([97 as u8, 97 as u8]), Utf8Text::from_bytes([98 as u8])).equals(Utf8Text::from_bytes([98 as u8, 97 as u8])) {
        panic("utf8 replace non overlapping failed")
    }

    let four: utf8 = Utf8Text::from_bytes([97 as u8, 97 as u8, 97 as u8, 97 as u8])
    if !four.replace(Utf8Text::from_bytes([97 as u8, 97 as u8]), Utf8Text::from_bytes([98 as u8])).equals(Utf8Text::from_bytes([98 as u8, 98 as u8])) {
        panic("utf8 replace adjacent pairs failed")
    }
}

[test]
micro `test utf8 replace empty pattern returns self`() {
    let text: utf8 = Utf8Text::from_bytes([97 as u8, 98 as u8, 99 as u8])

    # 空模式不做插值：返回原串，不变成 "XaXbXcX"。
    if !text.replace(Utf8Text::from_bytes([]), Utf8Text::from_bytes([88 as u8])).equals(Utf8Text::from_bytes([97 as u8, 98 as u8, 99 as u8])) {
        panic("utf8 replace empty pattern must return self")
    }

    if text.replace(Utf8Text::from_bytes([]), Utf8Text::from_bytes([88 as u8])).byte_length() != 3 {
        panic("utf8 replace empty pattern byte length failed")
    }
}

[test]
micro `test utf8 replace empty replacement deletes`() {
    let text: utf8 = Utf8Text::from_bytes([97 as u8, 45 as u8, 98 as u8, 45 as u8, 99 as u8])

    if !text.replace(Utf8Text::from_bytes([45 as u8]), Utf8Text::from_bytes([])).equals(Utf8Text::from_bytes([97 as u8, 98 as u8, 99 as u8])) {
        panic("utf8 replace empty replacement failed")
    }
}

[test]
micro `test utf8 replace multibyte boundaries`() {
    # "aé中a"：a / é(C3 A9) / 中(E4 B8 AD) / a
    let text: utf8 = Utf8Text::from_bytes([97 as u8, 195 as u8, 169 as u8, 228 as u8, 184 as u8, 173 as u8, 97 as u8])

    if !text.replace(Utf8Text::from_bytes([97 as u8]), Utf8Text::from_bytes([90 as u8])).equals(Utf8Text::from_bytes([90 as u8, 195 as u8, 169 as u8, 228 as u8, 184 as u8, 173 as u8, 90 as u8])) {
        panic("utf8 replace multibyte ascii failed")
    }

    if text.replace(Utf8Text::from_bytes([97 as u8]), Utf8Text::from_bytes([90 as u8])).byte_length() != 7 {
        panic("utf8 replace multibyte byte length failed")
    }

    # 多字节模式只在码点边界命中。
    if !text.replace(Utf8Text::from_bytes([195 as u8, 169 as u8]), Utf8Text::from_bytes([69 as u8])).equals(Utf8Text::from_bytes([97 as u8, 69 as u8, 228 as u8, 184 as u8, 173 as u8, 97 as u8])) {
        panic("utf8 replace multibyte pattern failed")
    }
}
