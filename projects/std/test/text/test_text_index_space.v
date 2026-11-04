[test]
micro `test utf8 codepoint index read`() {
    let text: utf8 = "你好世界"

    # 索引空间是码点：0 基 `⁅ ⁆`（`Cardinal`）与 1 基 `[ ]`（`Ordinal`）同口径。
    if (text⁅0⁆) as u32 != 0x4F60 {
        panic("utf8 codepoint cardinal first failed")
    }

    if (text⁅3⁆) as u32 != 0x754C {
        panic("utf8 codepoint cardinal last failed")
    }

    let second: char = text[2]
    if second as u32 != 0x597D {
        panic("utf8 codepoint ordinal read failed")
    }
}

[test]
micro `test utf8 ordinal missing positions`() {
    let text: utf8 = "你好世界"

    # 1 基序数：0、负数、超出码点个数均为越界。裸 `[ ]` 结构化失败，
    # 可恢复判定走 `get`（越界返回 `None`）。
    if text.get(0).is_some() {
        panic("utf8 ordinal zero failed")
    }

    let negative: isize = -1
    if text.get(negative).is_some() {
        panic("utf8 ordinal negative failed")
    }

    if text.get(5).is_some() {
        panic("utf8 ordinal beyond failed")
    }
}

[test]
micro `test utf8 codepoint write readback`() {
    let mut text: utf8 = "abc"

    # 1 基写：把 `b`（1 字节）替换为 `你`（3 字节标量）；码点个数不变，字节长度改变。
    text[2] = char::from(0x4F60)

    if text.length() != 3 {
        panic("utf8 ordinal write count failed")
    }

    if text.byte_length() != 5 {
        panic("utf8 ordinal write byte length failed")
    }

    if (text⁅1⁆) as u32 != 0x4F60 {
        panic("utf8 ordinal write cardinal readback failed")
    }

    let third: char = text[3]
    if third as u32 != 99 {
        panic("utf8 ordinal write tail failed")
    }
}

[test]
micro `test utf8 byte view`() {
    let text: utf8 = "你好"

    # 码点口径与字节口径分离：2 个码点、6 个字节。
    if text.length() != 2 {
        panic("utf8 byte view codepoint count failed")
    }

    if text.byte_length() != 6 {
        panic("utf8 byte view byte length failed")
    }

    # 显式字节视图：`bytes` 给出底层存储，`byte_at` 按字节偏移读取。
    let bytes: [u8] = text.bytes()
    if bytes.length() != 6 {
        panic("utf8 bytes view length failed")
    }

    if (bytes⁅0⁆) != 0xE4 {
        panic("utf8 bytes view first byte failed")
    }

    # `byte_at` 是裸 `u8`：界内直接读，越界结构化失败（没有 `Option` 形态）。
    if text.byte_at(0) != 0xE4 {
        panic("utf8 byte_at first failed")
    }

    if text.byte_at(3) != 0xE5 {
        panic("utf8 byte_at second scalar start failed")
    }
}

[test]
micro `test utf16 code unit index space`() {
    let text: utf16 = "hello"

    # 索引空间选定为 UTF-16 码元：`length` 与两种索引都按码元计数。
    if text.length() != 5 {
        panic("utf16 code unit length failed")
    }

    if (text⁅1⁆) as u32 != 101 {
        panic("utf16 cardinal read failed")
    }

    let second: char = text[2]
    if second as u32 != 108 {
        panic("utf16 ordinal read failed")
    }

    if text.get(6).is_some() {
        panic("utf16 ordinal bounds failed")
    }
}

[test]
micro `test utf16 code unit write readback`() {
    let mut text: utf16 = "hey"

    text[2] = char::from(105)

    if text.length() != 3 {
        panic("utf16 ordinal write count failed")
    }

    if (text⁅1⁆) as u32 != 105 {
        panic("utf16 ordinal write readback failed")
    }
}
