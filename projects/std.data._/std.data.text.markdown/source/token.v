namespace std.data.text.markdown;

# Markdown 词法类标签。词素原文不重复存放，按 `span` 从源文本切回（无损）。
# 同类连续字符合并为一个 token（`###`、``` ``` ```、`**` 等 run），
# 配对/闭合与否是 parser 的判断，不属于 kind。
[tag(MarkdownTokenKindTag)]
unite MarkdownTokenKind {
    Text
    Whitespace
    Newline

    Hash
    Backtick
    Tilde
    Asterisk
    Underscore
    Equals

    BracketOpen
    BracketClose
    ParenOpen
    ParenClose
    AngleOpen
    AngleClose
    Minus
    Plus
    Pipe
    Colon

    Illegal
}

structure MarkdownToken {
    kind: MarkdownTokenKind
    span: TextSpan
}

micro new_markdown_token(kind: MarkdownTokenKind, start: usize, stop: usize) -> MarkdownToken {
    return MarkdownToken {
        kind: kind,
        span: TextSpan {
            start: start,
            stop: stop
        }
    }
}
