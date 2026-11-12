[test]
micro `test utf8 builder append and build`() {
    let mut builder: Utf8Builder = Utf8Builder::new(8)
    builder.append("he")
    builder.append("llo")

    if builder.is_empty() {
        panic("utf8 builder is_empty test failed")
    }

    if builder.byte_length() != 5 {
        panic("utf8 builder byte_length test failed")
    }

    let value: utf8 = builder.build()
    if !value.equals("hello") {
        panic("utf8 builder build test failed")
    }
}

[test]
micro `test utf8 builder concat`() {
    let mut left: Utf8Builder = Utf8Builder::new(4)
    left.append("he")

    let mut right: Utf8Builder = Utf8Builder::new(4)
    right.append("llo")

    let value: utf8 = left.concat(right).build()
    if !value.equals("hello") {
        panic("utf8 builder concat test failed")
    }
}

[test]
micro `test utf8 builder append i64`() {
    let mut zero: Utf8Builder = Utf8Builder::new(4)
    zero.append_i64(0)
    if !zero.build().equals("0") {
        panic("utf8 builder append_i64 zero test failed")
    }

    let mut positive: Utf8Builder = Utf8Builder::new(8)
    positive.append_i64(42)
    if !positive.build().equals("42") {
        panic("utf8 builder append_i64 positive test failed")
    }

    let mut negative: Utf8Builder = Utf8Builder::new(16)
    negative.append_i64(-2147483648)
    if !negative.build().equals("-2147483648") {
        panic("utf8 builder append_i64 negative test failed")
    }
}

[test]
micro `test utf8 builder append u64`() {
    let mut builder: Utf8Builder = Utf8Builder::new(20)
    builder.append_u64(18446744073709551615)
    if !builder.build().equals("18446744073709551615") {
        panic("utf8 builder append_u64 max test failed")
    }
}

[test]
micro `test utf8 builder from text`() {
    let builder: Utf8Builder = Utf8Builder::new("abc")
    if builder.byte_length() != 3 {
        panic("utf8 builder from text length test failed")
    }

    if !builder.build().equals("abc") {
        panic("utf8 builder from text build test failed")
    }
}

[test]
micro `test utf8 builder prepend`() {
    let mut builder: Utf8Builder = Utf8Builder::new(8)
    builder.append("bc")
    builder.prepend('a')

    if builder.byte_length() != 3 {
        panic("utf8 builder prepend length test failed")
    }

    if !builder.build().equals("abc") {
        panic("utf8 builder prepend build test failed")
    }

    let mut astral: Utf8Builder = Utf8Builder::new(8)
    astral.prepend('😀')
    if astral.byte_length() != 4 {
        panic("utf8 builder prepend astral test failed")
    }
}
