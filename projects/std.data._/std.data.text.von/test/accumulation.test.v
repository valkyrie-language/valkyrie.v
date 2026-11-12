namespace std.data.text.von;

# 累积合同回归：词法/解析器曾以裸 `push` 丢弃累积更新，产出仅含 EOF 的
# token 流与空对象/空数组。本套件钉死 token 数量与字段/元素保真。

[test]
micro test_von_lex_emits_all_tokens() -> unit {
    match lex_von("{a:1}") {
        case Fine(tokens):
            if tokens.length() != 6 {
                panic("词法必须产出全部标记与 EOF，不得只剩 EOF")
            }
            if tokens[0].kind != LeftBrace {
                panic("首 token 必须是左大括号")
            }
            if tokens[5].kind != EndOfFile {
                panic("末 token 必须是 EOF")
            }
        case Fail(error):
            panic("合法 VON 词法不应失败")
    }
}

[test]
micro test_von_parse_object_keeps_fields() -> unit {
    match parse_von("{a:1}") {
        case Fine(value):
            match value {
                case Object(fields):
                    if fields.length() != 1 {
                        panic("对象字段必须完整保留")
                    }
                    if fields[0].name != "a" {
                        panic("字段名不符")
                    }
                else:
                    panic("必须以对象解析")
            }
        case Fail(error):
            panic("合法 VON 对象不应失败")
    }
}

[test]
micro test_von_parse_array_keeps_items() -> unit {
    match parse_von("[1, 2, 3]") {
        case Fine(value):
            match value {
                case Array(items):
                    if items.length() != 3 {
                        panic("数组元素必须完整保留")
                    }
                else:
                    panic("必须以数组解析")
            }
        case Fail(error):
            panic("合法 VON 数组不应失败")
    }
}
