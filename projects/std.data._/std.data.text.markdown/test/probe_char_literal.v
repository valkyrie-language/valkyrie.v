namespace std.data.text.markdown;

# 字符/字节字面量的失败探针：等待 `'c'` / `b'c'`（含转义与类型提升）落地。
# 落地后 `source/lexer.v` 里全部十进制码位机械改回字面量形式；
# 在那之前不引入查表、十六进制常量、预计算布尔或 `as` 强转等替代写法。

[test]
micro test_probe_char_literal_space() -> unit {
    let space: char = ' '
    let code: u32 = space as u32
    if code != 32 {
        panic("char literal space mismatch")
    }
}

[test]
micro test_probe_char_literal_escape() -> unit {
    let tab: char = '\t'
    let newline: char = '\n'
    let carriage: char = '\r'
    if tab as u32 != 9 {
        panic("char literal tab mismatch")
    }
    if newline as u32 != 10 {
        panic("char literal newline mismatch")
    }
    if carriage as u32 != 13 {
        panic("char literal carriage return mismatch")
    }
}

[test]
micro test_probe_char_literal_markers() -> unit {
    let hash: char = '#'
    let backtick: char = '`'
    if hash as u32 != 35 {
        panic("char literal hash mismatch")
    }
    if backtick as u32 != 96 {
        panic("char literal backtick mismatch")
    }
}

[test]
micro test_probe_byte_literal() -> unit {
    let zero: u8 = b'0'
    if zero != 48 {
        panic("byte literal mismatch")
    }
}
