# 星平面（astral）码点全链路：`char` 的运行载体是 32 位无符号码位，
# UTF-8 解码、具名构造与写回都必须保留完整码位，不得截到 16 位。

[test]
micro `test char from preserves astral code point`() {
    let ch: char = char::from(0x1F642)
    if ch as u32 != 0x1F642 {
        panic("char from astral code point failed")
    }
}

[test]
micro `test utf8 decode preserves astral code point`() {
    let text: utf8 = "🙂"

    if text.length() != 1 {
        panic("utf8 astral codepoint count failed")
    }

    if (text⁅0⁆) as u32 != 0x1F642 {
        panic("utf8 astral decode failed")
    }

    let single: char = text.character_at(0)
    if single as u32 != 0x1F642 {
        panic("utf8 astral character_at failed")
    }
}

[test]
micro `test utf8 write astral code point round trip`() {
    let mut text: utf8 = "A"

    # 1 基写：1 字节标量替换为 4 字节 astral 标量，码点个数不变、字节长度变为 4。
    text[1] = char::from(0x1F642)

    if text.length() != 1 {
        panic("utf8 astral write count failed")
    }

    if text.byte_length() != 4 {
        panic("utf8 astral write byte length failed")
    }

    if (text⁅0⁆) as u32 != 0x1F642 {
        panic("utf8 astral write round trip failed")
    }
}
