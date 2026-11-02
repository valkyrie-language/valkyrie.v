namespace std.data.text.markdown;

using std.data::{DataOutcome, data_outcome_value, data_outcome_diagnostics, data_diagnostic_code, data_diagnostic_span};

[test]
micro test_markdown_lex_covers_source_losslessly() -> unit {
    let source: utf8 = "# Title\n\nHello **world** `code` [link](target)\r\n> quote\n- item"
    let tokens: [MarkdownToken] = data_outcome_value(markdown_lex(source))
    let mut cursor: usize = 0
    let mut index: usize = 0
    while index < tokens.length() {
        let token: MarkdownToken = tokens⁅index⁆
        if token.span.start != cursor {
            panic("token stream has gap or overlap")
        }
        cursor = token.span.stop
        index = index + 1
    }
    if cursor != source.length() {
        panic("token stream does not cover full source")
    }
    if tokens.length() == 0 {
        panic("empty token stream")
    }
}

[test]
micro test_markdown_lex_heading_tokens() -> unit {
    let source: utf8 = "# Title"
    let tokens: [MarkdownToken] = data_outcome_value(markdown_lex(source))
    if tokens.length() != 3 {
        panic("expected hash, whitespace and text tokens")
    }
    if tokens⁅0⁆.kind != Hash || tokens⁅0⁆.span.start != 0 || tokens⁅0⁆.span.stop != 1 {
        panic("hash token span mismatch")
    }
    if tokens⁅1⁆.kind != Whitespace {
        panic("whitespace token expected")
    }
    if tokens⁅2⁆.kind != Text || !source.slice(tokens⁅2⁆.span.start, tokens⁅2⁆.span.stop - tokens⁅2⁆.span.start).equals("Title") {
        panic("title text mismatch")
    }
}

[test]
micro test_markdown_lex_run_markers_and_unclosed_fence() -> unit {
    let source: utf8 = "```rust"
    let tokens: [MarkdownToken] = data_outcome_value(markdown_lex(source))
    if tokens.length() != 2 {
        panic("expected backtick run plus text")
    }
    if tokens⁅0⁆.kind != Backtick || tokens⁅0⁆.span.stop != 3 {
        panic("backtick run length mismatch")
    }
    if !source.slice(tokens⁅0⁆.span.start, tokens⁅0⁆.span.stop - tokens⁅0⁆.span.start).equals("```") {
        panic("backtick run text mismatch")
    }
    if tokens⁅1⁆.kind != Text {
        panic("fence language text mismatch")
    }
    # 未闭合反引号：lexer 不报错，只产出 run token；未闭合判定是 parser 的事。
    let open_tokens: [MarkdownToken] = data_outcome_value(markdown_lex("`` x"))
    if open_tokens.length() != 3 || open_tokens⁅0⁆.kind != Backtick || open_tokens⁅0⁆.span.stop != 2 {
        panic("unclosed backtick run should still lex as run token")
    }
}

[test]
micro test_markdown_lex_newline_and_illegal() -> unit {
    let tokens: [MarkdownToken] = data_outcome_value(markdown_lex("a\r\nb"))
    if tokens.length() != 3 {
        panic("expected text, newline and text tokens")
    }
    if tokens⁅1⁆.kind != Newline || tokens⁅1⁆.span.start != 1 || tokens⁅1⁆.span.stop != 3 {
        panic("crlf should be one newline token")
    }
    let bad_source: utf8 = std::text::Utf8Text::from_bytes([97, 1, 98])
    let bad_outcome: DataOutcome<[MarkdownToken]> = markdown_lex(bad_source)
    let bad_tokens: [MarkdownToken] = data_outcome_value(bad_outcome)
    if bad_tokens.length() != 3 {
        panic("expected text, illegal and text tokens")
    }
    if bad_tokens⁅1⁆.kind != Illegal || bad_tokens⁅1⁆.span.start != 1 || bad_tokens⁅1⁆.span.stop != 2 {
        panic("illegal code point token mismatch")
    }
    # 错误容许：非法码位不中断扫描（后续 text token 仍在），且登记 Warning 诊断。
    if bad_tokens⁅2⁆.kind != Text {
        panic("scanning must continue after illegal code point")
    }
    if data_outcome_diagnostics(bad_outcome).length() != 1 {
        panic("illegal code point must register exactly one diagnostic")
    }
    if !data_diagnostic_code(data_outcome_diagnostics(bad_outcome)⁅0⁆.unwrap()).equals("markdown.lex.illegal_code_point") {
        panic("diagnostic code mismatch")
    }
    if data_diagnostic_span(data_outcome_diagnostics(bad_outcome)⁅0⁆.unwrap()).start != 1 {
        panic("diagnostic span mismatch")
    }
}
