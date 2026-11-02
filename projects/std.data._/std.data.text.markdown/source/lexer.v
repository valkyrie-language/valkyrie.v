namespace std.data.text.markdown;

using std.data::{DataOutcome, data_outcome_partial};
using std.diagnostic::{Diagnostic, Warning, new_diagnostic, new_span};
using std.text::{Utf8ByteIndicator, byte_indicates};

# Markdown 词法分析：源文本 -> token 流（`MarkdownToken`）。
# 只认词法：同类连续字符合并为一个 token，每个字符恰好属于一个 token（无损）。
# 未闭合配对、结构语义一律留给 parser；本层不做任何语义判断。
#
# 错误容许：非法码位产出 `Illegal` token（span 保留原字节）并继续扫描，
# 同时登记 `markdown.lex.illegal_code_point`（Warning）诊断；
# 不停在第一个非法单元，也不静默吞掉它。
#
# 字符比较一律使用字符字面量；数值码位不出现（范围判定以字面量拓宽到 u32 表达）。
# 扫描经 `byte_indicates` 顺序迭代器（均摊 O(1)/元素，解出字符后跳过整个码点）；
# 预读一格做 `\r\n` 合并与前看，不用 `text[index]` 随机访问（单次 O(n)，循环即 O(n²)）。
# token span 单位保持码点索引（与 `slice` 同源），迭代器产出的字节偏移不进 token span。

micro is_space_char(ch: char) -> bool {
    return ch == ' ' || ch == '\t'
}

micro is_run_marker_char(ch: char) -> bool {
    return match ch {
        '#' { true }
        '`' { true }
        '~' { true }
        '*' { true }
        '_' { true }
        '=' { true }
        _ { false }
    }
}

micro run_marker_kind(ch: char) -> MarkdownTokenKind {
    return match ch {
        '#' { Hash }
        '`' { Backtick }
        '~' { Tilde }
        '*' { Asterisk }
        '_' { Underscore }
        _ { Equals }
    }
}

micro is_punctuation_char(ch: char) -> bool {
    return match ch {
        '[' { true }
        ']' { true }
        '(' { true }
        ')' { true }
        '<' { true }
        '>' { true }
        '-' { true }
        '+' { true }
        '|' { true }
        ':' { true }
        _ { false }
    }
}

micro punctuation_kind(ch: char) -> MarkdownTokenKind {
    return match ch {
        '[' { BracketOpen }
        ']' { BracketClose }
        '(' { ParenOpen }
        ')' { ParenClose }
        '<' { AngleOpen }
        '>' { AngleClose }
        '-' { Minus }
        '+' { Plus }
        '|' { Pipe }
        _ { Colon }
    }
}

micro is_text_char(ch: char) -> bool {
    # 控制字符不是文本：范围判定以字面量拓宽到 u32 表达（数值仅作序比较媒介）。
    if (ch as u32) < (' ' as u32) {
        return false
    }
    if is_space_char(ch) {
        return false
    }
    if is_run_marker_char(ch) {
        return false
    }
    if is_punctuation_char(ch) {
        return false
    }
    return true
}

# 顺序扫描主循环：`pending` 是预读槽（每次循环消费一格、按 run 向前并吞）。
micro markdown_lex(source: utf8) -> DataOutcome<[MarkdownToken]> {
    let mut tokens: [MarkdownToken] = []
    let mut diagnostics: [Diagnostic] = []
    let mut iter: Utf8ByteIndicator = byte_indicates(source)
    let mut index: usize = 0
    let mut pending: Option<(usize, char)> = iter.next()
    while pending.is_some() {
        let pair = pending.unwrap()
        let ch: char = pair.1
        let start: usize = index
        index = index + 1
        if ch == '\r' || ch == '\n' {
            let look: Option<(usize, char)> = iter.next()
            if ch == '\r' && look.is_some() && look.unwrap().1 == '\n' {
                index = index + 1
                pending = iter.next()
            }
            else {
                pending = look
            }
            tokens = push(tokens, new_markdown_token(Newline, start, index))
        }
        else if is_space_char(ch) {
            let mut look: Option<(usize, char)> = iter.next()
            while look.is_some() && is_space_char(look.unwrap().1) {
                index = index + 1
                look = iter.next()
            }
            pending = look
            tokens = push(tokens, new_markdown_token(Whitespace, start, index))
        }
        else if is_run_marker_char(ch) {
            let marker: MarkdownTokenKind = run_marker_kind(ch)
            let mut look: Option<(usize, char)> = iter.next()
            while look.is_some() && look.unwrap().1 == ch {
                index = index + 1
                look = iter.next()
            }
            pending = look
            tokens = push(tokens, new_markdown_token(marker, start, index))
        }
        else if is_punctuation_char(ch) {
            tokens = push(tokens, new_markdown_token(punctuation_kind(ch), start, index))
            pending = iter.next()
        }
        # 小于空格码位的不可见控制字符归为非法。
        else if (ch as u32) < (' ' as u32) {
            tokens = push(tokens, new_markdown_token(Illegal, start, index))
            diagnostics = push(diagnostics, new_diagnostic("markdown.lex.illegal_code_point", Warning, "不可见控制字符", new_span(start, index)))
            pending = iter.next()
        }
        else {
            let mut look: Option<(usize, char)> = iter.next()
            while look.is_some() && is_text_char(look.unwrap().1) {
                index = index + 1
                look = iter.next()
            }
            pending = look
            tokens = push(tokens, new_markdown_token(Text, start, index))
        }
    }
    return data_outcome_partial(tokens, diagnostics)
}
