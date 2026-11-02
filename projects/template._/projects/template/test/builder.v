namespace template;

using std.data::{DataCstNode, DataDiagnostic, DataOutcome, DataSettings, DataSource, DataToken, data_diagnostic_code, data_outcome_diagnostics, data_outcome_value, data_source_from_bytes, data_source_from_text, new_data_settings};

# 语义段测试：正例覆盖文本/插值/控制流映射与字面量求值准备；反例覆盖
# 重复对象键、缺席映射与二进制源。
# 注：match 分支以 `{ }` 包裹，避免分支末尾的裸 if 把 `else:` 抢绑到内层 if。

micro build_source(source: utf8) -> DataOutcome<TemplateDocument> {
    let data_source: DataSource = data_source_from_text(source)
    let settings: DataSettings = new_data_settings(64, 0)
    let tokens: [DataToken<TemplateTokenKind>] = data_outcome_value(template_lex(data_source, settings))
    let parsed: DataOutcome<DataCstNode<TemplateTokenKind>> = template_parse(tokens, settings)
    return template_build(data_outcome_value(parsed), data_source, settings)
}

[test]
micro test_build_text_and_interpolation() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("Hello <% name %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean template must build without diagnostics")
    }
    let document: TemplateDocument = data_outcome_value(outcome)
    if document.body.length() != 2 {
        panic("expected text node and interpolation node")
    }
    let first_node: TemplateNode = document.body⁅0⁆.unwrap()
    match first_node {
        case TextNode(payload): {
            if payload.text != "Hello " {
                panic("text content mismatch")
            }
        }
        else: {
            panic("text node expected")
        }
    }
    let second_node: TemplateNode = document.body⁅1⁆.unwrap()
    match second_node {
        case InterpolationNode(payload): {
            let expression: TemplateExpression = document.expressions⁅payload.expression⁆.unwrap()
            match expression {
                case Identifier(identifier): {
                    if identifier.name != "name" {
                        panic("identifier name mismatch")
                    }
                }
                else: {
                    panic("identifier expression expected")
                }
            }
        }
        else: {
            panic("interpolation node expected")
        }
    }
}

[test]
micro test_build_if_loop_structure() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% if x %>a<% else %>b<% end if %>")
    let document: TemplateDocument = data_outcome_value(outcome)
    if document.body.length() != 1 {
        panic("expected single if node")
    }
    let first_node: TemplateNode = document.body⁅0⁆.unwrap()
    match first_node {
        case IfNode(payload): {
            if payload.branches.length() != 1 {
                panic("expected one branch")
            }
            if payload.alternate.length() != 1 {
                panic("expected alternate body")
            }
        }
        else: {
            panic("if node expected")
        }
    }
    let looped: DataOutcome<TemplateDocument> = build_source("<% loop item in xs %><% item %><% end loop %>")
    let loop_document: TemplateDocument = data_outcome_value(looped)
    let loop_node: TemplateNode = loop_document.body⁅0⁆.unwrap()
    match loop_node {
        case LoopNode(payload): {
            if payload.item != "item" {
                panic("loop item name mismatch")
            }
            if payload.body.length() != 1 {
                panic("loop body must hold the interpolation")
            }
        }
        else: {
            panic("loop node expected")
        }
    }
}

[test]
micro test_build_literals() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% 42 %>")
    let document: TemplateDocument = data_outcome_value(outcome)
    let first_node: TemplateNode = document.body⁅0⁆.unwrap()
    match first_node {
        case InterpolationNode(payload): {
            let expression: TemplateExpression = document.expressions⁅payload.expression⁆.unwrap()
            match expression {
                case LiteralNumber(number): {
                    if number.value != 42.0 {
                        panic("number literal mismatch")
                    }
                }
                else: {
                    panic("number literal expected")
                }
            }
        }
        else: {
            panic("interpolation expected")
        }
    }
    let text_outcome: DataOutcome<TemplateDocument> = build_source("<% 'hi' %>")
    let text_document: TemplateDocument = data_outcome_value(text_outcome)
    let text_node: TemplateNode = text_document.body⁅0⁆.unwrap()
    match text_node {
        case InterpolationNode(payload): {
            let text_expression: TemplateExpression = text_document.expressions⁅payload.expression⁆.unwrap()
            match text_expression {
                case LiteralString(string): {
                    if string.value != "hi" {
                        panic("string literal mismatch")
                    }
                }
                else: {
                    panic("string literal expected")
                }
            }
        }
        else: {
            panic("interpolation expected")
        }
    }
}

[test]
micro test_build_duplicate_key_rejected() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% { a: 1, a: 2 } %>")
    let diagnostics: [DataDiagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() == 0 {
        panic("duplicate key must register a diagnostic")
    }
    if data_diagnostic_code(diagnostics⁅0⁆.unwrap()) != "template.build.duplicate_key" {
        panic("diagnostic code mismatch")
    }
}

[test]
micro test_build_missing_maps_faithfully() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% %>")
    let document: TemplateDocument = data_outcome_value(outcome)
    let first_node: TemplateNode = document.body⁅0⁆.unwrap()
    match first_node {
        case InterpolationNode(payload): {
            let expression: TemplateExpression = document.expressions⁅payload.expression⁆.unwrap()
            match expression {
                case ExpressionMissing(missing): {
                    if missing.reason.length() == 0 {
                        panic("missing expression must carry a reason")
                    }
                }
                else: {
                    panic("missing expression placeholder expected")
                }
            }
        }
        else: {
            panic("interpolation expected")
        }
    }
}

[test]
micro test_build_binary_source_rejected() -> unit {
    let settings: DataSettings = new_data_settings(64, 0)
    let tokens: [DataToken<TemplateTokenKind>] = []
    let parsed: DataOutcome<DataCstNode<TemplateTokenKind>> = template_parse(tokens, settings)
    let outcome: DataOutcome<TemplateDocument> = template_build(data_outcome_value(parsed), data_source_from_bytes([60, 37]), settings)
    if data_diagnostic_code(data_outcome_diagnostics(outcome)⁅0⁆.unwrap()) != "template.build.binary_source" {
        panic("diagnostic code mismatch")
    }
}
