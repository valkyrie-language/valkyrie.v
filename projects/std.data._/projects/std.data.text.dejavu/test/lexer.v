namespace std.data.text.dejavu;

using std.data::{DataDiagnostic, DataOutcome, DataToken, data_diagnostic_code, data_outcome_diagnostics, data_outcome_has_errors, data_outcome_value, data_source_from_bytes, data_source_from_text, new_data_settings};

# 词法段测试：正例覆盖定界/trim/注释/转义/无损覆盖；反例覆盖单独管道、
# 非法码位、未闭合注释与二进制源。

[test]
micro test_lex_interpolation_tokens() -> unit {
    let source: utf8 = "Hello <% name %>!"
    let tokens: [DataToken<TemplateTokenKind>] = data_outcome_value(template_lex(data_source_from_text(source), new_data_settings(64, 0)))
    if tokens.length() != 7 {
        panic("expected text, open, whitespace, identifier, whitespace, close, text")
    }
    if tokens⁅0⁆.unwrap().kind != Text {
        panic("leading text token expected")
    }
    if !template_kind_is_code_open(tokens⁅1⁆.unwrap().kind) {
        panic("code open expected")
    }
    if tokens⁅3⁆.unwrap().kind != Identifier {
        panic("identifier expected")
    }
    if !template_kind_is_code_close(tokens⁅5⁆.unwrap().kind) {
        panic("code close expected")
    }
    let span_start: usize = tokens⁅3⁆.unwrap().span.start
    let span_stop: usize = tokens⁅3⁆.unwrap().span.stop
    if source.slice(span_start, span_stop - span_start) != "name" {
        panic("identifier lexeme mismatch")
    }
}

[test]
micro test_lex_covers_source_losslessly() -> unit {
    let source: utf8 = "a <%_ x + 1 -%> b <# note #> <%! c"
    let tokens: [DataToken<TemplateTokenKind>] = data_outcome_value(template_lex(data_source_from_text(source), new_data_settings(64, 0)))
    let mut cursor: usize = 0
    let mut index: usize = 0
    while index < tokens.length() {
        let token: DataToken<TemplateTokenKind> = tokens⁅index⁆.unwrap()
        if token.span.start != cursor {
            panic("token stream has gap or overlap")
        }
        cursor = token.span.stop
        index = index + 1
    }
    if cursor != source.length() {
        panic("token stream does not cover full source")
    }
}

[test]
micro test_lex_trim_markers_split_text() -> unit {
    let tokens: [DataToken<TemplateTokenKind>] = data_outcome_value(template_lex(data_source_from_text("hello  <%_ x %>"), new_data_settings(64, 0)))
    # text "hello" + Trimmed "  " + CodeOpen{ws} + ...
    if tokens.length() < 4 {
        panic("expected trimmed split before code open")
    }
    if tokens⁅0⁆.unwrap().kind != Text {
        panic("text token expected")
    }
    if tokens⁅1⁆.unwrap().kind != Trimmed {
        panic("trimmed token expected")
    }
    let span: usize = tokens⁅0⁆.unwrap().span.stop
    if "hello  <%_ x %>".slice(0, span) != "hello" {
        panic("trailing horizontal whitespace must be stripped from text")
    }
}

[test]
micro test_lex_comment_and_escape() -> unit {
    let tokens: [DataToken<TemplateTokenKind>] = data_outcome_value(template_lex(data_source_from_text("a<# c #>b<%!"), new_data_settings(64, 0)))
    if tokens.length() != 4 {
        panic("expected text, comment, text, escape")
    }
    if tokens⁅1⁆.unwrap().kind != Comment {
        panic("comment token expected")
    }
    if tokens⁅3⁆.unwrap().kind != CodeEscape {
        panic("code escape token expected")
    }
}

[test]
micro test_lex_unclosed_comment_registers_diagnostic() -> unit {
    let outcome: DataOutcome<[DataToken<TemplateTokenKind>]> = template_lex(data_source_from_text("a<# open"), new_data_settings(64, 0))
    let diagnostics: [DataDiagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() != 1 {
        panic("unclosed comment must register exactly one diagnostic")
    }
    if data_diagnostic_code(diagnostics⁅0⁆.unwrap()) != "template.lex.unclosed_comment" {
        panic("diagnostic code mismatch")
    }
    if !data_outcome_has_errors(outcome) {
        panic("unclosed comment is an error")
    }
}

[test]
micro test_lex_single_pipe_is_illegal() -> unit {
    let outcome: DataOutcome<[DataToken<TemplateTokenKind>]> = template_lex(data_source_from_text("<% a | b %>"), new_data_settings(64, 0))
    let tokens: [DataToken<TemplateTokenKind>] = data_outcome_value(outcome)
    let mut found_illegal: bool = false
    let mut index: usize = 0
    while index < tokens.length() {
        if tokens⁅index⁆.unwrap().kind == Illegal {
            found_illegal = true
        }
        index = index + 1
    }
    if !found_illegal {
        panic("single pipe must produce an illegal token")
    }
    let diagnostics: [DataDiagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() != 1 {
        panic("single pipe must register exactly one diagnostic")
    }
    if data_diagnostic_code(diagnostics⁅0⁆.unwrap()) != "template.lex.single_pipe" {
        panic("diagnostic code mismatch")
    }
}

[test]
micro test_lex_binary_source_rejected() -> unit {
    let outcome: DataOutcome<[DataToken<TemplateTokenKind>]> = template_lex(data_source_from_bytes([60, 37]), new_data_settings(64, 0))
    if data_outcome_value(outcome).length() != 0 {
        panic("binary source must produce an empty token stream")
    }
    if data_diagnostic_code(data_outcome_diagnostics(outcome)⁅0⁆.unwrap()) != "template.lex.binary_source" {
        panic("diagnostic code mismatch")
    }
}
