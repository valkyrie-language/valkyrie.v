# `trim` 按 Unicode White_Space（25 个码点）裁首尾，U+200B / U+FEFF 不算空白。
# `replace` 从左到右非重叠全部替换；空模式返回原串，空替换即删除。

[test]
micro `test utf8 trim unicode whitespace`() {
    # 空格、制表符、U+3000 表意空格 + "abc" + U+0085(NEL)、空格
    let text: utf8 = " \t\u3000abc\u0085 "

    if !text.trim().equals("abc") {
        panic("utf8 trim unicode whitespace failed")
    }

    if text.trim().byte_length() != 3 {
        panic("utf8 trim unicode whitespace byte length failed")
    }

    # 内部空白保留：U+0085 只在首尾被裁，中间不动。
    let middle: utf8 = " a\tb "
    if !middle.trim().equals("a\tb") {
        panic("utf8 trim inner whitespace failed")
    }
}

[test]
micro `test utf8 trim keeps zero width and bom`() {
    # U+200B（E2 80 8B）+ "ab" + U+FEFF（EF BB BF）：两者都不是 White_Space。
    let text: utf8 = "\u200Bab\uFEFF"

    if text.trim().byte_length() != 8 {
        panic("utf8 trim must keep U+200B and U+FEFF")
    }

    if text.trim().length() != 4 {
        panic("utf8 trim zero width codepoint count failed")
    }
}

[test]
micro `test utf8 trim all whitespace becomes empty`() {
    let text: utf8 = " \t\u0085"

    if text.trim().byte_length() != 0 {
        panic("utf8 trim all whitespace must be empty")
    }

    if text.trim().length() != 0 {
        panic("utf8 trim all whitespace length failed")
    }

    let empty: utf8 = ""
    if empty.trim().length() != 0 {
        panic("utf8 trim empty string failed")
    }
}

[test]
micro `test utf8 replace non overlapping`() {
    let text: utf8 = "aaa"

    if !text.replace("aa", "b").equals("ba") {
        panic("utf8 replace non overlapping failed")
    }

    let four: utf8 = "aaaa"
    if !four.replace("aa", "b").equals("bb") {
        panic("utf8 replace adjacent pairs failed")
    }
}

[test]
micro `test utf8 replace empty pattern returns self`() {
    let text: utf8 = "abc"

    # 空模式不做插值：返回原串，不变成 "XaXbXcX"。
    if !text.replace("", "X").equals("abc") {
        panic("utf8 replace empty pattern must return self")
    }

    if text.replace("", "X").byte_length() != 3 {
        panic("utf8 replace empty pattern byte length failed")
    }
}

[test]
micro `test utf8 replace empty replacement deletes`() {
    let text: utf8 = "a-b-c"

    if !text.replace("-", "").equals("abc") {
        panic("utf8 replace empty replacement failed")
    }
}

[test]
micro `test utf8 replace multibyte boundaries`() {
    # "aé中a"：a / é(C3 A9) / 中(E4 B8 AD) / a
    let text: utf8 = "aé中a"

    if !text.replace("a", "Z").equals("Zé中Z") {
        panic("utf8 replace multibyte ascii failed")
    }

    if text.replace("a", "Z").byte_length() != 7 {
        panic("utf8 replace multibyte byte length failed")
    }

    # 多字节模式只在码点边界命中。
    if !text.replace("é", "E").equals("aE中a") {
        panic("utf8 replace multibyte pattern failed")
    }
}
