namespace template;

using std.data::{DataCstNode, DataDiagnostic, DataOutcome, DataToken, data_diagnostic_code, data_outcome_diagnostics, data_outcome_value, data_source_from_text, new_data_settings};

# 语法段测试：正例覆盖 if/loop/插值/表达式优先级 CST 形状；反例覆盖
# 越界控制流、未闭合语句、未支持表面、悬空 closer、空标签与 trim 违规。

micro parse_source(source: utf8) -> DataOutcome<DataCstNode<TemplateTokenKind>> {
    let tokens: [DataToken<TemplateTokenKind>] = data_outcome_value(template_lex(data_source_from_text(source), new_data_settings(64, 0)))
    return template_parse(tokens, new_data_settings(64, 0))
}

micro first_diagnostic_code(outcome: DataOutcome<DataCstNode<TemplateTokenKind>>) -> utf8 {
    let diagnostics: [DataDiagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() == 0 {
        return ""
    }
    return data_diagnostic_code(diagnostics⁅0⁆.unwrap())
}

[test]
micro test_parse_if_shape() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% if x %>a<% else %>b<% end if %>")
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean if template must parse without diagnostics")
    }
    let root: DataCstNode<TemplateTokenKind> = data_outcome_value(outcome)
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
    let root: DataCstNode<TemplateTokenKind> = data_outcome_value(outcome)
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
    let root: DataCstNode<TemplateTokenKind> = data_outcome_value(outcome)
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
micro test_parse_unsupported_surface_rejected() -> unit {
    let outcome: DataOutcome<DataCstNode<TemplateTokenKind>> = parse_source("<% extends 'base' %>")
    if first_diagnostic_code(outcome) != "template.parse.unsupported_statement" {
        panic("unsupported_statement diagnostic expected")
    }
    let root: DataCstNode<TemplateTokenKind> = data_outcome_value(outcome)
    let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(root)
    if children.length() != 1 {
        panic("root must hold the unsupported node")
    }
    if template_cst_node_kind(children⁅0⁆.unwrap()) != NodeUnsupported {
        panic("unsupported node kind expected")
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
