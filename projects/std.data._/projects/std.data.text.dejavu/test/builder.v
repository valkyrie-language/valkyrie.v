namespace std.data.text.dejavu;

using std.data.text::{BlockNode, Call, CallNode, ExpressionMissing, ExtendsNode, Identifier, IfNode, ImportNode, IncludeNode, InterpolationNode, LiteralNumber, LiteralString, LoopNode, MacroNode, PartialNode, SuperNode, TemplateDocument, TemplateExpression, TemplateNode, TextNode};

using std.data::{DataCstNode, Diagnostic, DataOutcome, DataSettings, DataSource, DataToken, data_diagnostic_code, data_outcome_diagnostics, data_outcome_value, data_source_from_bytes, data_source_from_text, new_data_settings};

# 语义段测试：正例覆盖文本/插值/控制流映射与字面量求值准备；反例覆盖
# 重复对象键、缺席映射与二进制源。
# 注：match 分支以 `{ }` 包裹，避免分支末尾的裸 if 把 `else:` 抢绑到内层 if。

micro build_source(source: utf8) -> DataOutcome<TemplateDocument> {
    let data_source: DataSource = data_source_from_text(source)
    let settings: DataSettings = new_data_settings(64, 0)
    let tokens: [DataToken<TemplateTokenKind>] = data_outcome_value_or(template_lex(data_source, settings), [])
    let parsed: DataOutcome<DataCstNode<TemplateTokenKind>> = template_parse(tokens, settings)
    return template_build(data_outcome_value_or(parsed, data_cst_missing(new_span(0, 0), "test fallback")), data_source, settings)
}

[test]
micro test_build_text_and_interpolation() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("Hello <% name %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean template must build without diagnostics")
    }
    let document: TemplateDocument = data_outcome_value_or(outcome, TemplateDocument { body: [], expressions: [] })
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
    let document: TemplateDocument = data_outcome_value_or(outcome, TemplateDocument { body: [], expressions: [] })
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
    let loop_document: TemplateDocument = data_outcome_value_or(looped, TemplateDocument { body: [], expressions: [] })
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
    let document: TemplateDocument = data_outcome_value_or(outcome, TemplateDocument { body: [], expressions: [] })
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
    let text_document: TemplateDocument = data_outcome_value_or(text_outcome, TemplateDocument { body: [], expressions: [] })
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
    let diagnostics: [Diagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() == 0 {
        panic("duplicate key must register a diagnostic")
    }
    if diagnostic_code(diagnostics⁅0⁆.unwrap()) != "template.build.duplicate_key" {
        panic("diagnostic code mismatch")
    }
}

[test]
micro test_build_missing_maps_faithfully() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% %>")
    let document: TemplateDocument = data_outcome_value_or(outcome, TemplateDocument { body: [], expressions: [] })
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
    let outcome: DataOutcome<TemplateDocument> = template_build(data_outcome_value_or(parsed, data_cst_missing(new_span(0, 0), "test fallback")), data_source_from_bytes([60, 37]), settings)
    if diagnostic_code(data_outcome_diagnostics(outcome)⁅0⁆.unwrap()) != "template.build.binary_source" {
        panic("diagnostic code mismatch")
    }
}

[test]
micro test_build_extends_block_super() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% extends 'base' %><% block content %><% super %>x<% end block %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean template must build without diagnostics")
    }
    let document: TemplateDocument = data_outcome_value_or(outcome, TemplateDocument { body: [], expressions: [] })
    if document.body.length() != 2 {
        panic("expected extends node and block node")
    }
    let extends_node: TemplateNode = document.body⁅0⁆.unwrap()
    match extends_node {
        case ExtendsNode(payload): {
            let parent: TemplateExpression = document.expressions⁅payload.parent⁆.unwrap()
            match parent {
                case LiteralString(text): {
                    if text.value != "base" {
                        panic("extends parent mismatch")
                    }
                }
                else: {
                    panic("string parent expected")
                }
            }
        }
        else: {
            panic("extends node expected")
        }
    }
    let block_node: TemplateNode = document.body⁅1⁆.unwrap()
    match block_node {
        case BlockNode(payload): {
            if payload.name != "content" {
                panic("block name mismatch")
            }
            if payload.body.length() != 2 {
                panic("block body must hold super and text")
            }
            let super_node: TemplateNode = payload.body⁅0⁆.unwrap()
            let mut saw_super: bool = false
            match super_node {
                case SuperNode: {
                    saw_super = true
                }
                else: {
                    saw_super = false
                }
            }
            if !saw_super {
                panic("super node expected")
            }
        }
        else: {
            panic("block node expected")
        }
    }
}

[test]
micro test_build_include_modifiers() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% include 'item' with ctx only %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean include must build without diagnostics")
    }
    let document: TemplateDocument = data_outcome_value_or(outcome, TemplateDocument { body: [], expressions: [] })
    let include_node: TemplateNode = document.body⁅0⁆.unwrap()
    match include_node {
        case IncludeNode(payload): {
            if !payload.only {
                panic("only flag must be set")
            }
            let path: TemplateExpression = document.expressions⁅payload.path⁆.unwrap()
            match path {
                case LiteralString(text): {
                    if text.value != "item" {
                        panic("include path mismatch")
                    }
                }
                else: {
                    panic("string path expected")
                }
            }
            if !payload.with_expression.is_some() {
                panic("with expression must be present")
            }
            let with_expression: TemplateExpression = document.expressions⁅payload.with_expression.unwrap()⁆.unwrap()
            match with_expression {
                case Identifier(identifier): {
                    if identifier.name != "ctx" {
                        panic("with expression mismatch")
                    }
                }
                else: {
                    panic("identifier with expression expected")
                }
            }
        }
        else: {
            panic("include node expected")
        }
    }
    let bare_outcome: DataOutcome<TemplateDocument> = build_source("<% include 'item' without context %>")
    let bare_document: TemplateDocument = data_outcome_value_or(bare_outcome, TemplateDocument { body: [], expressions: [] })
    let bare_node: TemplateNode = bare_document.body⁅0⁆.unwrap()
    match bare_node {
        case IncludeNode(payload): {
            if !payload.only {
                panic("without context must map to only")
            }
            if payload.with_expression.is_some() {
                panic("without context must not carry a with expression")
            }
        }
        else: {
            panic("include node expected")
        }
    }
}

[test]
micro test_build_partial_parameters() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% partial name, count = 2 %>x<% end partial %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean partial must build without diagnostics")
    }
    let document: TemplateDocument = data_outcome_value_or(outcome, TemplateDocument { body: [], expressions: [] })
    let partial_node: TemplateNode = document.body⁅0⁆.unwrap()
    match partial_node {
        case PartialNode(payload): {
            if payload.parameters.length() != 2 {
                panic("expected two parameters")
            }
            if payload.parameters⁅0⁆.unwrap().name != "name" {
                panic("first parameter name mismatch")
            }
            if payload.parameters⁅0⁆.unwrap().default.is_some() {
                panic("first parameter must not carry a default")
            }
            if payload.parameters⁅1⁆.unwrap().name != "count" {
                panic("second parameter name mismatch")
            }
            if !payload.parameters⁅1⁆.unwrap().default.is_some() {
                panic("second parameter must carry a default")
            }
            let default_expression: TemplateExpression = document.expressions⁅payload.parameters⁅1⁆.unwrap().default.unwrap()⁆.unwrap()
            match default_expression {
                case LiteralNumber(number): {
                    if number.value != 2.0 {
                        panic("default value mismatch")
                    }
                }
                else: {
                    panic("number default expected")
                }
            }
            if payload.body.length() != 1 {
                panic("partial body must hold the text")
            }
        }
        else: {
            panic("partial node expected")
        }
    }
}

[test]
micro test_build_macro_and_call() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% macro greet(who = 'world') %>hi<% end macro %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean macro must build without diagnostics")
    }
    let document: TemplateDocument = data_outcome_value_or(outcome, TemplateDocument { body: [], expressions: [] })
    let macro_node: TemplateNode = document.body⁅0⁆.unwrap()
    match macro_node {
        case MacroNode(payload): {
            if payload.name != "greet" {
                panic("macro name mismatch")
            }
            if payload.parameters.length() != 1 {
                panic("expected one macro parameter")
            }
            if payload.parameters⁅0⁆.unwrap().name != "who" {
                panic("macro parameter name mismatch")
            }
            if !payload.parameters⁅0⁆.unwrap().default.is_some() {
                panic("macro parameter must carry a default")
            }
            let default_expression: TemplateExpression = document.expressions⁅payload.parameters⁅0⁆.unwrap().default.unwrap()⁆.unwrap()
            match default_expression {
                case LiteralString(text): {
                    if text.value != "world" {
                        panic("macro default mismatch")
                    }
                }
                else: {
                    panic("string default expected")
                }
            }
        }
        else: {
            panic("macro node expected")
        }
    }
    let call_outcome: DataOutcome<TemplateDocument> = build_source("<% call (row) render(row) %>body<% end call %>")
    if data_outcome_diagnostics(call_outcome).length() != 0 {
        panic("clean call must build without diagnostics")
    }
    let call_document: TemplateDocument = data_outcome_value_or(call_outcome, TemplateDocument { body: [], expressions: [] })
    let call_node: TemplateNode = call_document.body⁅0⁆.unwrap()
    match call_node {
        case CallNode(payload): {
            if payload.caller_parameters.length() != 1 {
                panic("expected one caller parameter")
            }
            if payload.caller_parameters⁅0⁆.unwrap() != "row" {
                panic("caller parameter mismatch")
            }
            let callee: TemplateExpression = call_document.expressions⁅payload.callee⁆.unwrap()
            match callee {
                case Call(call): {
                    let callee_name: TemplateExpression = call_document.expressions⁅call.callee⁆.unwrap()
                    match callee_name {
                        case Identifier(identifier): {
                            if identifier.name != "render" {
                                panic("callee name mismatch")
                            }
                        }
                        else: {
                            panic("identifier callee expected")
                        }
                    }
                    if call.arguments.length() != 1 {
                        panic("expected one call argument")
                    }
                }
                else: {
                    panic("call expression expected")
                }
            }
            if payload.body.length() != 1 {
                panic("call body must hold the caller block")
            }
        }
        else: {
            panic("call node expected")
        }
    }
}

[test]
micro test_build_import_names() -> unit {
    let outcome: DataOutcome<TemplateDocument> = build_source("<% from 'forms' import input, button as btn %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean import must build without diagnostics")
    }
    let document: TemplateDocument = data_outcome_value_or(outcome, TemplateDocument { body: [], expressions: [] })
    let import_node: TemplateNode = document.body⁅0⁆.unwrap()
    match import_node {
        case ImportNode(payload): {
            let path: TemplateExpression = document.expressions⁅payload.path⁆.unwrap()
            match path {
                case LiteralString(text): {
                    if text.value != "forms" {
                        panic("import path mismatch")
                    }
                }
                else: {
                    panic("string path expected")
                }
            }
            if payload.names.length() != 2 {
                panic("expected two import names")
            }
            if payload.names⁅0⁆.unwrap().name != "input" {
                panic("first import name mismatch")
            }
            if payload.names⁅0⁆.unwrap().alias.is_some() {
                panic("first import must not carry an alias")
            }
            if payload.names⁅1⁆.unwrap().name != "button" {
                panic("second import name mismatch")
            }
            if !payload.names⁅1⁆.unwrap().alias.is_some() {
                panic("second import must carry an alias")
            }
            if payload.names⁅1⁆.unwrap().alias.unwrap() != "btn" {
                panic("import alias mismatch")
            }
        }
        else: {
            panic("import node expected")
        }
    }
}

[test]
micro test_build_parameter_name_rules() -> unit {
    let duplicate: DataOutcome<TemplateDocument> = build_source("<% partial a, a %>x<% end partial %>")
    let duplicate_diagnostics: [Diagnostic] = data_outcome_diagnostics(duplicate)
    if duplicate_diagnostics.length() == 0 {
        panic("duplicate parameter must register a diagnostic")
    }
    if diagnostic_code(duplicate_diagnostics⁅0⁆.unwrap()) != "template.build.duplicate_parameter" {
        panic("diagnostic code mismatch")
    }
    let reserved: DataOutcome<TemplateDocument> = build_source("<% macro m(caller) %>x<% end macro %>")
    let reserved_diagnostics: [Diagnostic] = data_outcome_diagnostics(reserved)
    if reserved_diagnostics.length() == 0 {
        panic("reserved parameter must register a diagnostic")
    }
    if diagnostic_code(reserved_diagnostics⁅0⁆.unwrap()) != "template.build.caller_reserved" {
        panic("diagnostic code mismatch")
    }
}
