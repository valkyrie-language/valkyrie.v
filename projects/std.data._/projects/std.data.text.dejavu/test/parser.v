namespace std.data.text.dejavu;

using std.data::{DataCstNode, Diagnostic, DataOutcome, DataToken, data_diagnostic_code, data_outcome_diagnostics, data_outcome_value, data_source_from_text, new_data_settings};

# 语法段测试：正例覆盖 if/loop/插值/表达式优先级 CST 形状；反例覆盖
# 越界控制流、未闭合语句、未支持表面、悬空 closer、空标签与 trim 违规。

micro parse_source(source: utf8) -> DataOutcome<DataCstNode<TemplateTokenKind>> {
    let tokens: [DataToken<TemplateTokenKind>] = data_outcome_value_or(template_lex(data_source_from_text(source), new_data_settings(64, 0)), [])
    return template_parse(tokens, new_data_settings(64, 0))
}

micro first_diagnostic_code(outcome: DataOutcome<DataCstNode<TemplateTokenKind>>) -> utf8 {
    let diagnostics: [Diagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() == 0 {
        return ""
    }
    return diagnostic_code(diagnostics⁅0⁆.unwrap())
}

[test]
micro test_parse_if_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% if x %>a<% else %>b<% end if %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean if template must parse without diagnostics")
    }
    let root: DataCstNode<TemplateTokenKind> = data_outcome_value_or(outcome, data_cst_missing(new_span(0, 0), "test fallback"))
    let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(root)
    if children.length() != 1 {
        panic("root must hold exactly the if node")
    }
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodeIf {
        panic("if node expected")
    }
    let if_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(children⁅0⁆.unwrap())
    # [open, ws, if, ws, expr, close, text, else 容器, end-tag...]
    let mut has_elseif_or_else: bool = false
    let mut index: usize = 0
    while index < if_children.length() {
        if template_cst_node_kind(if_children⁅index⁆.unwrap()) == NodeElse {
            has_elseif_or_else = true
        }
        index = index + 1
    }
    if !has_elseif_or_else {
        panic("else clause node expected inside if")
    }
}

[test]
micro test_parse_loop_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% loop item in xs %><% item %><% end loop %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean loop template must parse without diagnostics")
    }
    let root: DataCstNode<TemplateTokenKind> = data_outcome_value_or(outcome, data_cst_missing(new_span(0, 0), "test fallback"))
    let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(root)
    if children.length() != 1 {
        panic("root must hold exactly the loop node")
    }
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodeLoop {
        panic("loop node expected")
    }
}

[test]
micro test_parse_expression_precedence() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% 1 + 2 * 3 %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean expression must parse without diagnostics")
    }
    let root: DataCstNode<TemplateTokenKind> = data_outcome_value_or(outcome, data_cst_missing(new_span(0, 0), "test fallback"))
    let interpolation: DataCstNode<TemplateTokenKind> = template_cst_children(root)⁅0⁆.unwrap()
    if template_cst_node_kind(interpolation) != NodeInterpolation {
        panic("interpolation node expected")
    }
    let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(interpolation)
    # 找到 `+` 二元节点：其右操作数应是 `*` 二元节点。
    let mut index: usize = 0
    let mut add_node_found: bool = false
    while index < children.length() {
        let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
        if template_cst_node_kind(child) == NodeExpressionBinary {
            add_node_found = true
            let add_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(child)
            let right: DataCstNode<TemplateTokenKind> = add_children⁅add_children.length() - 1⁆.unwrap()
            if template_cst_node_kind(right) != NodeExpressionBinary {
                panic("multiplication must bind tighter than addition")
            }
        }
        index = index + 1
    }
    if !add_node_found {
        panic("binary node expected")
    }
}

[test]
micro test_parse_break_outside_loop_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% break %>")
    if first_diagnostic_code(outcome) != "template.parse.control_outside_loop" {
        panic("control_outside_loop diagnostic expected")
    }
}

[test]
micro test_parse_missing_end_if_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% if x %>a")
    if first_diagnostic_code(outcome) != "template.parse.missing_end_if" {
        panic("missing_end_if diagnostic expected")
    }
}

[test]
micro test_parse_extends_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% extends 'base' %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean extends must parse without diagnostics")
    }
    let root: DataCstNode<TemplateTokenKind> = data_outcome_value_or(outcome, data_cst_missing(new_span(0, 0), "test fallback"))
    let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(root)
    if children.length() != 1 {
        panic("root must hold exactly the extends node")
    }
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodeExtends {
        panic("extends node expected")
    }
    let extends_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(children⁅0⁆.unwrap())
    if count_leaf_kind(extends_children, KeywordExtends) != 1 {
        panic("extends keyword leaf expected")
    }
    if count_leaf_kind(extends_children, String) != 1 {
        panic("extends path string leaf expected")
    }
}

[test]
micro test_parse_unmatched_closer_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% end if %>")
    if first_diagnostic_code(outcome) != "template.parse.unmatched_closer" {
        panic("unmatched_closer diagnostic expected")
    }
}

[test]
micro test_parse_empty_tag_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% %>")
    if first_diagnostic_code(outcome) != "template.parse.empty_code_tag" {
        panic("empty_code_tag diagnostic expected")
    }
}

[test]
micro test_parse_closer_trim_marker_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% if x %>a<% end if -%>")
    if first_diagnostic_code(outcome) != "template.parse.closer_trim_marker" {
        panic("closer_trim_marker diagnostic expected")
    }
}

# ── 继承 / 包含 / partial / 宏 / 导入：CST 形状 ──

micro count_leaf_kind(children: [DataCstNode<TemplateTokenKind>], kind: TemplateTokenKind) -> usize {
    let mut count: usize = 0
    let mut index: usize = 0
    while index < children.length() {
        let leaf: TemplateTokenKind? = template_cst_token_kind(children⁅index⁆.unwrap())
        if leaf.is_some() && leaf.unwrap() == kind {
            count = count + 1
        }
        index = index + 1
    }
    return count
}

micro count_container_kind(children: [DataCstNode<TemplateTokenKind>], kind: TemplateTokenKind) -> usize {
    let mut count: usize = 0
    let mut index: usize = 0
    while index < children.length() {
        if template_cst_is_node(children⁅index⁆.unwrap()) && template_cst_node_kind(children⁅index⁆.unwrap()) == kind {
            count = count + 1
        }
        index = index + 1
    }
    return count
}

# 容器首个 CodeOpen 叶子的 trim 级别（无则 TrimNone）。
micro open_trim_of(children: [DataCstNode<TemplateTokenKind>]) -> TemplateTrim {
    let mut index: usize = 0
    while index < children.length() {
        let leaf: TemplateTokenKind? = template_cst_token_kind(children⁅index⁆.unwrap())
        if leaf.is_some() {
            let kind: TemplateTokenKind = leaf.unwrap()
            if template_kind_is_code_open(kind) {
                match kind {
                    case CodeOpen(payload):
                        return payload.trim
                    else:
                        return TrimNone
                }
            }
        }
        index = index + 1
    }
    return TrimNone
}

# 容器末个 CodeClose 叶子的 trim 级别（无则 TrimNone）。
micro close_trim_of(children: [DataCstNode<TemplateTokenKind>]) -> TemplateTrim {
    let mut index: usize = children.length()
    while index > 0 {
        index = index - 1
        let leaf: TemplateTokenKind? = template_cst_token_kind(children⁅index⁆.unwrap())
        if leaf.is_some() {
            let kind: TemplateTokenKind = leaf.unwrap()
            if template_kind_is_code_close(kind) {
                match kind {
                    case CodeClose(payload):
                        return payload.trim
                    else:
                        return TrimNone
                }
            }
        }
    }
    return TrimNone
}

micro root_children(source: utf8) -> [DataCstNode<TemplateTokenKind>] {
    let root: DataCstNode<TemplateTokenKind> = data_outcome_value_or(parse_source(source), data_cst_missing(new_span(0, 0), "test fallback"))
    return template_cst_children(root)
}

[test]
micro test_parse_block_super_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% block content %>x<% super %><% end block %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean block must parse without diagnostics")
    }
    let children: [DataCstNode<TemplateTokenKind>] = root_children("<% block content %>x<% super %><% end block %>")
    if children.length() != 1 {
        panic("root must hold exactly the block node")
    }
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodeBlock {
        panic("block node expected")
    }
    let block_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(children⁅0⁆.unwrap())
    if count_leaf_kind(block_children, KeywordBlock) != 2 {
        panic("block keyword must appear in open and end tags")
    }
    if count_leaf_kind(block_children, Identifier) != 2 {
        panic("block name must appear in open and end tags")
    }
    if count_container_kind(block_children, NodeSuper) != 1 {
        panic("super node expected inside block")
    }
    if count_leaf_kind(block_children, Text) != 1 {
        panic("block body text leaf expected")
    }
}

[test]
micro test_parse_include_modifiers_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% include 'a' with ctx only %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean include must parse without diagnostics")
    }
    let children: [DataCstNode<TemplateTokenKind>] = root_children("<% include 'a' with ctx only %>")
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodeInclude {
        panic("include node expected")
    }
    let include_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(children⁅0⁆.unwrap())
    if count_leaf_kind(include_children, KeywordWith) != 1 {
        panic("with keyword leaf expected")
    }
    if count_leaf_kind(include_children, KeywordOnly) != 1 {
        panic("only keyword leaf expected")
    }
    if count_leaf_kind(include_children, String) != 1 {
        panic("include path string leaf expected")
    }
    if count_leaf_kind(include_children, Identifier) != 1 {
        panic("with expression identifier leaf expected")
    }
    let bare: [DataCstNode<TemplateTokenKind>] = template_cst_children(root_children("<% include 'a' without context %>")⁅0⁆.unwrap())
    if count_leaf_kind(bare, KeywordWithout) != 1 {
        panic("without keyword leaf expected")
    }
    if count_leaf_kind(bare, KeywordContext) != 1 {
        panic("context keyword leaf expected")
    }
}

[test]
micro test_parse_partial_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% partial name, count = 2 %>x<% end partial %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean partial must parse without diagnostics")
    }
    let children: [DataCstNode<TemplateTokenKind>] = root_children("<% partial name, count = 2 %>x<% end partial %>")
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodePartial {
        panic("partial node expected")
    }
    let partial_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(children⁅0⁆.unwrap())
    if count_leaf_kind(partial_children, Identifier) != 2 {
        panic("two parameter name leaves expected")
    }
    if count_leaf_kind(partial_children, Assign) != 1 {
        panic("default assign leaf expected")
    }
    if count_leaf_kind(partial_children, Number) != 1 {
        panic("default number leaf expected")
    }
    if count_leaf_kind(partial_children, Text) != 1 {
        panic("partial body text leaf expected")
    }
}

[test]
micro test_parse_macro_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% macro greet(who) %>hi<% end macro %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean macro must parse without diagnostics")
    }
    let children: [DataCstNode<TemplateTokenKind>] = root_children("<% macro greet(who) %>hi<% end macro %>")
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodeMacro {
        panic("macro node expected")
    }
    let macro_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(children⁅0⁆.unwrap())
    if count_leaf_kind(macro_children, ParenOpen) != 1 {
        panic("macro parameter paren open expected")
    }
    if count_leaf_kind(macro_children, ParenClose) != 1 {
        panic("macro parameter paren close expected")
    }
    if count_leaf_kind(macro_children, Identifier) != 2 {
        panic("macro name and parameter name leaves expected")
    }
}

[test]
micro test_parse_call_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% call (row) render(row) %>x<% end call %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean call must parse without diagnostics")
    }
    let children: [DataCstNode<TemplateTokenKind>] = root_children("<% call (row) render(row) %>x<% end call %>")
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodeCall {
        panic("call node expected")
    }
    let call_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(children⁅0⁆.unwrap())
    if count_container_kind(call_children, NodeExpressionCall) != 1 {
        panic("callee must be a call expression container")
    }
    if count_leaf_kind(call_children, KeywordCall) != 2 {
        panic("call keyword must appear in open and end tags")
    }
}

[test]
micro test_parse_from_import_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% from 'forms' import input, button as btn %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean import must parse without diagnostics")
    }
    let children: [DataCstNode<TemplateTokenKind>] = root_children("<% from 'forms' import input, button as btn %>")
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodeImport {
        panic("import node expected")
    }
    let import_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(children⁅0⁆.unwrap())
    if count_leaf_kind(import_children, String) != 1 {
        panic("from path string leaf expected")
    }
    if count_leaf_kind(import_children, KeywordImport) != 1 {
        panic("import keyword leaf expected")
    }
    if count_leaf_kind(import_children, KeywordAs) != 1 {
        panic("as keyword leaf expected")
    }
    if count_leaf_kind(import_children, Identifier) != 3 {
        panic("three import name leaves expected")
    }
}

# ── 错误恢复 ──

[test]
micro test_parse_missing_end_block_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% block a %>x")
    if first_diagnostic_code(outcome) != "template.parse.missing_end_block" {
        panic("missing_end_block diagnostic expected")
    }
    let children: [DataCstNode<TemplateTokenKind>] = root_children("<% block a %>x")
    let block_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(children⁅0⁆.unwrap())
    let last: DataCstNode<TemplateTokenKind> = block_children⁅block_children.length() - 1⁆.unwrap()
    if !template_cst_is_missing_node(last) {
        panic("missing end block must map to a Missing placeholder")
    }
}

[test]
micro test_parse_unclosed_block_tag_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% block a")
    if first_diagnostic_code(outcome) != "template.parse.unclosed_code_tag" {
        panic("unclosed_code_tag diagnostic expected")
    }
}

[test]
micro test_parse_dangling_end_block_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% end block %>")
    if first_diagnostic_code(outcome) != "template.parse.unmatched_closer" {
        panic("unmatched_closer diagnostic expected")
    }
    let children: [DataCstNode<TemplateTokenKind>] = root_children("<% end block %>")
    if children.length() != 1 {
        panic("root must hold the poison placeholder")
    }
    if !template_cst_is_poison_node(children⁅0⁆.unwrap()) {
        panic("dangling closer must map to a Poison placeholder")
    }
}

[test]
micro test_parse_partial_nested_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% if x %><% partial a %>y<% end partial %><% end if %>")
    if first_diagnostic_code(outcome) != "template.parse.partial_nested" {
        panic("partial_nested diagnostic expected")
    }
}

[test]
micro test_parse_macro_requires_parentheses_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% macro m %>x<% end macro %>")
    if first_diagnostic_code(outcome) != "template.parse.macro_requires_parentheses" {
        panic("macro_requires_parentheses diagnostic expected")
    }
}

[test]
micro test_parse_call_requires_macro_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% call %>x<% end call %>")
    if first_diagnostic_code(outcome) != "template.parse.call_requires_macro" {
        panic("call_requires_macro diagnostic expected")
    }
}

[test]
micro test_parse_super_outside_block_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% super %>")
    if first_diagnostic_code(outcome) != "template.parse.super_outside_block" {
        panic("super_outside_block diagnostic expected")
    }
}

[test]
micro test_parse_caller_param_default_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% call (a = 1) m() %>x<% end call %>")
    if first_diagnostic_code(outcome) != "template.parse.caller_param_default" {
        panic("caller_param_default diagnostic expected")
    }
}

[test]
micro test_parse_from_requires_import_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% from 'a' %>")
    if first_diagnostic_code(outcome) != "template.parse.from_requires_import" {
        panic("from_requires_import diagnostic expected")
    }
}

[test]
micro test_parse_extends_trim_marker_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% extends 'a' -%>")
    if first_diagnostic_code(outcome) != "template.parse.extends_trim_marker" {
        panic("extends_trim_marker diagnostic expected")
    }
}

# ── trim 标记落点 ──

[test]
micro test_parse_trim_markers_land_on_delimiters() -> unit {
    # `_` ↔ ws：开闭两侧均落在定界 token 负载上。
    let ws_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(root_children("<%_ x _%>")⁅0⁆.unwrap())
    if open_trim_of(ws_children) != TrimWhitespace {
        panic("left ws marker must land on CodeOpen")
    }
    if close_trim_of(ws_children) != TrimWhitespace {
        panic("right ws marker must land on CodeClose")
    }
    # `-` ↔ nl。
    let nl_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(root_children("<%- x -%>")⁅0⁆.unwrap())
    if open_trim_of(nl_children) != TrimNewline {
        panic("left nl marker must land on CodeOpen")
    }
    if close_trim_of(nl_children) != TrimNewline {
        panic("right nl marker must land on CodeClose")
    }
    # `~` ↔ ws_nl。
    let ws_nl_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(root_children("<%~ x ~%>")⁅0⁆.unwrap())
    if open_trim_of(ws_nl_children) != TrimWhitespaceNewline {
        panic("left ws_nl marker must land on CodeOpen")
    }
    if close_trim_of(ws_nl_children) != TrimWhitespaceNewline {
        panic("right ws_nl marker must land on CodeClose")
    }
    # `=` ↔ all。
    let all_children: [DataCstNode<TemplateTokenKind>] = template_cst_children(root_children("<%= x =%>")⁅0⁆.unwrap())
    if open_trim_of(all_children) != TrimAll {
        panic("left all marker must land on CodeOpen")
    }
    if close_trim_of(all_children) != TrimAll {
        panic("right all marker must land on CodeClose")
    }
}

[test]
micro test_parse_trimmed_whitespace_splits_body() -> unit {
    let children: [DataCstNode<TemplateTokenKind>] = root_children("a  <%_ x _%>  b")
    if children.length() != 5 {
        panic("trimmed whitespace must split body into five nodes")
    }
    if count_leaf_kind(children, Trimmed) != 2 {
        panic("two trimmed whitespace leaves expected")
    }
    if count_leaf_kind(children, Text) != 2 {
        panic("two text leaves expected")
    }
    if count_container_kind(children, NodeInterpolation) != 1 {
        panic("interpolation node expected between trimmed leaves")
    }
}
