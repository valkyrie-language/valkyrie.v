[test]
micro `test utf8 cardinal read`() {
    let text: utf8 = "hello"

    if text.length() != 5 {
        panic("utf8 length failed")
    }

    # `⁅ ⁆` 自动取值：`char`，不需要 unwrap。
    if (text⁅0⁆) as u32 != 104 {
        panic("utf8 cardinal first char failed")
    }

    if (text⁅4⁆) as u32 != 111 {
        panic("utf8 cardinal last char failed")
    }

    # `get_cardinal` 与 `⁅ ⁆` 同源。
    if text.get_cardinal(1) as u32 != 101 {
        panic("utf8 get_cardinal read failed")
    }
}

[test]
micro `test utf8 cardinal multibyte`() {
    let text: utf8 = "你好世界"

    # 索引按 Unicode 标量计数。
    if text.length() != 4 {
        panic("utf8 multibyte length failed")
    }

    if (text⁅1⁆) as u32 != 0x597D {
        panic("utf8 multibyte cardinal char failed")
    }
}

[test]
micro `test utf8 cardinal multibyte prefix`() {
    let text: utf8 = "aé中"

    if text.length() != 3 {
        panic("utf8 multibyte prefix length failed")
    }

    # 第 1、2 个码点：é (U+00E9) 与 中 (U+4E2D)，索引按码点而非字节。
    if (text⁅0⁆) as u32 != 0x61 {
        panic("utf8 multibyte prefix first failed")
    }

    if (text⁅1⁆) as u32 != 0xE9 {
        panic("utf8 multibyte prefix second failed")
    }

    if (text⁅2⁆) as u32 != 0x4E2D {
        panic("utf8 multibyte prefix third failed")
    }

    # 字节视图仍独立：3 个码点占 6 个字节。
    if text.byte_length() != 6 {
        panic("utf8 multibyte prefix byte length failed")
    }
}

[test]
micro `test utf8 cardinal write same width`() {
    let mut text: utf8 = "hello"

    text⁅0⁆ = char::from(72)

    if (text⁅0⁆) as u32 != 72 {
        panic("utf8 cardinal write readback failed")
    }

    if text.length() != 5 {
        panic("utf8 cardinal write count failed")
    }

    if (text⁅1⁆) as u32 != 101 {
        panic("utf8 cardinal write untouched failed")
    }
}

[test]
micro `test utf8 cardinal write width change`() {
    let mut text: utf8 = "abc"

    # ASCII（1 字节）替换为 3 字节标量：元素个数不变，字节长度改变。
    text⁅1⁆ = char::from(0x4F60)

    if text.length() != 3 {
        panic("utf8 width change count failed")
    }

    if (text⁅1⁆) as u32 != 0x4F60 {
        panic("utf8 width change readback failed")
    }

    if (text⁅0⁆) as u32 != 97 {
        panic("utf8 width change head failed")
    }

    if (text⁅2⁆) as u32 != 99 {
        panic("utf8 width change tail failed")
    }
}

[test]
micro `test utf8 cardinal named methods`() {
    let mut text: utf8 = "hey"

    text.set_cardinal(0, char::from(72))

    if text.get_cardinal(0) as u32 != 72 {
        panic("utf8 set_cardinal/get_cardinal failed")
    }

    if text.length() != 3 {
        panic("utf8 cardinal named count failed")
    }
}

[test]
micro `test utf16 cardinal read and write`() {
    let mut text: utf16 = "hello"

    if text.length() != 5 {
        panic("utf16 length failed")
    }

    if (text⁅0⁆) as u32 != 104 {
        panic("utf16 cardinal first failed")
    }

    if (text⁅4⁆) as u32 != 111 {
        panic("utf16 cardinal last failed")
    }

    text⁅4⁆ = char::from(33)

    if (text⁅4⁆) as u32 != 33 {
        panic("utf16 cardinal write readback failed")
    }

    if text.get_cardinal(4) as u32 != 33 {
        panic("utf16 get_cardinal readback failed")
    }

    if text.length() != 5 {
        panic("utf16 cardinal write count failed")
    }
}
