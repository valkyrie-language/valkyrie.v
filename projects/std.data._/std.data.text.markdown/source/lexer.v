namespace std.data.text.markdown;

# Markdown 词法分析：源文本 -> token 流（`MarkdownToken`）。
# 只认词法：同类连续字符合并为一个 token，每个字符恰好属于一个 token（无损）。
# 未闭合配对、结构语义一律留给 parser；本层不做任何语义判断。

micro is_space_code_point(code_point: u32) -> bool {
    return code_point == 32 || code_point == 9
}

micro is_run_marker_code_point(code_point: u32) -> bool {
    return code_point == 35 || code_point == 96 || code_point == 126
        || code_point == 42 || code_point == 95 || code_point == 61
}

micro run_marker_kind(code_point: u32) -> MarkdownTokenKind {
    if code_point == 35 {
        return Hash
    }
    if code_point == 96 {
        return Backtick
    }
    if code_point == 126 {
        return Tilde
    }
    if code_point == 42 {
        return Asterisk
    }
    if code_point == 95 {
        return Underscore
    }
    return Equals
}

micro is_punctuation_code_point(code_point: u32) -> bool {
    return code_point == 91 || code_point == 93 || code_point == 40 || code_point == 41
        || code_point == 60 || code_point == 62 || code_point == 45 || code_point == 43
        || code_point == 124 || code_point == 58
}

micro punctuation_kind(code_point: u32) -> MarkdownTokenKind {
    if code_point == 91 {
        return BracketOpen
    }
    if code_point == 93 {
        return BracketClose
    }
    if code_point == 40 {
        return ParenOpen
    }
    if code_point == 41 {
        return ParenClose
    }
    if code_point == 60 {
        return AngleOpen
    }
    if code_point == 62 {
        return AngleClose
    }
    if code_point == 45 {
        return Minus
    }
    if code_point == 43 {
        return Plus
    }
    if code_point == 124 {
        return Pipe
    }
    return Colon
}

micro is_text_code_point(code_point: u32) -> bool {
    if code_point < 32 {
        return false
    }
    if is_space_code_point(code_point) {
        return false
    }
    if is_run_marker_code_point(code_point) {
        return false
    }
    if is_punctuation_code_point(code_point) {
        return false
    }
    return true
}

micro code_point_at(source: utf8, index: usize) -> u32 {
    return source.char_at(index).unwrap() as u32
}

micro markdown_lex(source: utf8) -> [MarkdownToken] {
    let mut tokens: [MarkdownToken] = []
    let length: usize = source.length()
    let mut index: usize = 0
    while index < length {
        let code_point: u32 = code_point_at(source, index)
        if code_point == 13 || code_point == 10 {
            let mut stop: usize = index + 1
            if code_point == 13 && index + 1 < length {
                if code_point_at(source, index + 1) == 10 {
                    stop = index + 2
                }
            }
            tokens = push(tokens, new_markdown_token(Newline, index, stop))
            index = stop
        }
        else if is_space_code_point(code_point) {
            let mut stop: usize = index
            while stop < length {
                if !is_space_code_point(code_point_at(source, stop)) {
                    break
                }
                stop = stop + 1
            }
            tokens = push(tokens, new_markdown_token(Whitespace, index, stop))
            index = stop
        }
        else if is_run_marker_code_point(code_point) {
            let mut stop: usize = index
            while stop < length {
                if code_point_at(source, stop) != code_point {
                    break
                }
                stop = stop + 1
            }
            tokens = push(tokens, new_markdown_token(run_marker_kind(code_point), index, stop))
            index = stop
        }
        else if is_punctuation_code_point(code_point) {
            tokens = push(tokens, new_markdown_token(punctuation_kind(code_point), index, index + 1))
            index = index + 1
        }
        else if code_point < 32 {
            tokens = push(tokens, new_markdown_token(Illegal, index, index + 1))
            index = index + 1
        }
        else {
            let mut stop: usize = index
            while stop < length {
                if !is_text_code_point(code_point_at(source, stop)) {
                    break
                }
                stop = stop + 1
            }
            tokens = push(tokens, new_markdown_token(Text, index, stop))
            index = stop
        }
    }
    return tokens
}
