[test]
micro `test utf8 split whitespace`() {
    let text: utf8 = "  the   sky is blue "
    let words: [utf8] = text.split_whitespace()

    if words.length() != 4 {
        panic("split_whitespace count test failed")
    }

    if !words⁅0⁆.equals("the") || !words⁅1⁆.equals("sky") {
        panic("split_whitespace first words test failed")
    }

    if !words⁅2⁆.equals("is") || !words⁅3⁆.equals("blue") {
        panic("split_whitespace last words test failed")
    }
}

# 多字节前缀：切分与取段都必须落在码点边界上。
[test]
micro `test utf8 split whitespace multibyte`() {
    let text: utf8 = "aé中  b"
    let words: [utf8] = text.split_whitespace()

    if words.length() != 2 {
        panic("split_whitespace multibyte count test failed")
    }

    if !words⁅0⁆.equals("aé中") {
        panic("split_whitespace multibyte first word test failed")
    }

    if !words⁅1⁆.equals("b") {
        panic("split_whitespace multibyte second word test failed")
    }
}

# 反例：空串与纯空白都返回空数组，不产生空词。
[test]
micro `test utf8 split whitespace empty`() {
    let empty_text: utf8 = ""
    if empty_text.split_whitespace().length() != 0 {
        panic("split_whitespace empty test failed")
    }

    let blank_text: utf8 = " \t\n　"
    if blank_text.split_whitespace().length() != 0 {
        panic("split_whitespace blank test failed")
    }
}

[test]
micro `test utf8 split once`() {
    let text: utf8 = "a=b=c"
    let parts_option = text.split_once("=")

    if parts_option.is_none() {
        panic("split_once presence test failed")
    }

    let parts = parts_option.unwrap()
    if !parts.head.equals("a") {
        panic("split_once head test failed")
    }

    if !parts.tail.equals("b=c") {
        panic("split_once tail test failed")
    }
}

# 反例：分隔符未出现或为空串时返回 None，不伪造切分。
[test]
micro `test utf8 split once missing`() {
    let text: utf8 = "abc"

    if text.split_once("=").is_some() {
        panic("split_once missing separator test failed")
    }

    if text.split_once("").is_some() {
        panic("split_once empty separator test failed")
    }
}
