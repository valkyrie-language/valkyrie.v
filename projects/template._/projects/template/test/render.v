namespace template;

using std.diagnostic::{Diagnostic, diagnostic_code};
using std.data::{DataOutcome, data_outcome_diagnostics, data_outcome_value_or};
using std.data.text::{Binary, BreakNode, Call, CommentNode, ContinueNode, Identifier, IfNode, InterpolationNode, LiteralNumber, LiteralString, LoopNode, Member, ObjectLiteral, OpEqual, Pipe, Test, TemplateDocument, TemplateExpression, TemplateIfBranch, TemplateImportName, TemplateNode, TemplateObjectEntry, TemplateParameter, TextNode};

# 渲染段测试：正例覆盖插值/转义/if/loop/forloop/break/continue/过滤器/函数/测试；
# 反例覆盖未知过滤器、非法迭代、strict 未定义与非整数边界。
# 本包不含解析：文档一律直接构造公共模板 AST，不经手源码文本。

micro render_doc(body: [TemplateNode], expressions: [TemplateExpression], context: TemplateValue) -> DataOutcome<utf8> {
    let document: TemplateDocument = TemplateDocument { body: body, expressions: expressions }
    return template_render(document, context, template_default_render_settings())
}

micro render_doc_strict(body: [TemplateNode], expressions: [TemplateExpression], context: TemplateValue) -> DataOutcome<utf8> {
    let document: TemplateDocument = TemplateDocument { body: body, expressions: expressions }
    return template_render(document, context, TemplateRenderSettings { strict_undefined: true, max_depth: 64 })
}

micro render_ok(body: [TemplateNode], expressions: [TemplateExpression], context: TemplateValue) -> utf8 {
    let outcome: DataOutcome<utf8> = render_doc(body, expressions, context)
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean render must not register diagnostics")
    }
    return data_outcome_value_or(outcome, "")
}

micro first_render_error(body: [TemplateNode], expressions: [TemplateExpression], context: TemplateValue) -> utf8 {
    let outcome: DataOutcome<utf8> = render_doc(body, expressions, context)
    let diagnostics: [Diagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() == 0 {
        return ""
    }
    return diagnostic_code(diagnostics⁅0⁆.unwrap())
}

micro interpolation(expression: usize) -> TemplateNode {
    return InterpolationNode { expression: expression }
}

micro identifier(name: utf8) -> TemplateExpression {
    return Identifier { name: name }
}

micro literal_number(value: f64) -> TemplateExpression {
    return LiteralNumber { value: value }
}

micro literal_string(value: utf8) -> TemplateExpression {
    return LiteralString { value: value }
}

micro literal_text_node(text: utf8) -> TemplateNode {
    return TextNode { text: text }
}

[test]
micro test_render_text_and_interpolation() -> unit {
    # "Hello <% name %>!"
    let body: [TemplateNode] = [literal_text_node("Hello "), interpolation(0), literal_text_node("!")]
    let expressions: [TemplateExpression] = [identifier("name")]
    let context: TemplateValue = template_object([template_field("name", template_text("world"))])
    if render_ok(body, expressions, context) != "Hello world!" {
        panic("interpolation output mismatch")
    }
}

[test]
micro test_render_escapes_html_by_default() -> unit {
    let context: TemplateValue = template_object([template_field("name", template_text("<b>"))])
    let expressions: [TemplateExpression] = [identifier("name")]
    if render_ok([interpolation(0)], expressions, context) != "&lt;b&gt;" {
        panic("interpolation must escape html by default")
    }
    # name |> safe
    let safe_expressions: [TemplateExpression] = [identifier("name"), Pipe { expression: 0, filter: "safe", arguments: [] }]
    if render_ok([interpolation(1)], safe_expressions, context) != "<b>" {
        panic("safe filter must skip escaping")
    }
    # name |> escape
    let escape_expressions: [TemplateExpression] = [identifier("name"), Pipe { expression: 0, filter: "escape", arguments: [] }]
    if render_ok([interpolation(1)], escape_expressions, context) != "&lt;b&gt;" {
        panic("escape filter must escape once")
    }
    # name |> safe |> uppercase（capability 只看最外层，仍要转义）
    let chained: [TemplateExpression] = [
        identifier("name"),
        Pipe { expression: 0, filter: "safe", arguments: [] },
        Pipe { expression: 1, filter: "uppercase", arguments: [] }
    ]
    if render_ok([interpolation(2)], chained, context) != "&lt;B&gt;" {
        panic("pure filter after safe must re-enable escaping")
    }
}

[test]
micro test_render_if_elif_else() -> unit {
    # if show -> "yes" else "no"
    let expressions: [TemplateExpression] = [identifier("show")]
    let body: [TemplateNode] = [
        IfNode {
            branches: [TemplateIfBranch { test: 0, body: [literal_text_node("yes")] }],
            alternate: [literal_text_node("no")]
        }
    ]
    let shown: TemplateValue = template_object([template_field("show", template_boolean(true))])
    if render_ok(body, expressions, shown) != "yes" {
        panic("if truthy branch mismatch")
    }
    let hidden: TemplateValue = template_object([template_field("show", template_boolean(false))])
    if render_ok(body, expressions, hidden) != "no" {
        panic("if alternate branch mismatch")
    }
    # if a -> 1, else if b -> 2, else -> 3（a、b 缺失， falsy）
    let chain_expressions: [TemplateExpression] = [identifier("a"), identifier("b")]
    let chain_body: [TemplateNode] = [
        IfNode {
            branches: [
                TemplateIfBranch { test: 0, body: [literal_text_node("1")] },
                TemplateIfBranch { test: 1, body: [literal_text_node("2")] }
            ],
            alternate: [literal_text_node("3")]
        }
    ]
    if render_ok(chain_body, chain_expressions, hidden) != "3" {
        panic("else-if chain mismatch")
    }
}

[test]
micro test_render_loop_with_forloop() -> unit {
    let items: [TemplateValue] = [template_text("a"), template_text("b"), template_text("c")]
    let context: TemplateValue = template_object([template_field("xs", template_array(items))])
    # loop item in xs -> item ","
    let expressions: [TemplateExpression] = [identifier("xs"), identifier("item")]
    let body: [TemplateNode] = [
        LoopNode { item: "item", iterable: 0, body: [interpolation(1), literal_text_node(",")] }
    ]
    if render_ok(body, expressions, context) != "a,b,c," {
        panic("loop output mismatch")
    }
    # forloop.index ":" item " "
    let index_expressions: [TemplateExpression] = [
        identifier("xs"),
        identifier("forloop"),
        Member { object: 1, property: "index" },
        identifier("item")
    ]
    let index_body: [TemplateNode] = [
        LoopNode {
            item: "item",
            iterable: 0,
            body: [interpolation(2), literal_text_node(":"), interpolation(3), literal_text_node(" ")]
        }
    ]
    if render_ok(index_body, index_expressions, context) != "1:a 2:b 3:c " {
        panic("forloop metadata mismatch")
    }
    # if forloop.last -> "last"
    let last_expressions: [TemplateExpression] = [
        identifier("xs"),
        identifier("forloop"),
        Member { object: 1, property: "last" }
    ]
    let last_body: [TemplateNode] = [
        LoopNode {
            item: "item",
            iterable: 0,
            body: [
                IfNode {
                    branches: [TemplateIfBranch { test: 2, body: [literal_text_node("last")] }],
                    alternate: []
                }
            ]
        }
    ]
    if render_ok(last_body, last_expressions, context) != "last" {
        panic("forloop.last mismatch")
    }
    # 空数组零次迭代。
    let empty_context: TemplateValue = template_object([template_field("xs", template_array([]))])
    if render_ok(body, expressions, empty_context) != "" {
        panic("empty array must render zero iterations")
    }
}

[test]
micro test_render_break_and_continue() -> unit {
    let items: [TemplateValue] = [template_number(1.0), template_number(2.0), template_number(3.0)]
    let context: TemplateValue = template_object([template_field("xs", template_array(items))])
    # loop item in xs: if item == 2 break; item
    let expressions: [TemplateExpression] = [
        identifier("xs"),
        identifier("item"),
        literal_number(2.0),
        Binary { operator: OpEqual, left: 1, right: 2 }
    ]
    let break_body: [TemplateNode] = [
        LoopNode {
            item: "item",
            iterable: 0,
            body: [
                IfNode {
                    branches: [TemplateIfBranch { test: 3, body: [BreakNode] }],
                    alternate: []
                },
                interpolation(1)
            ]
        }
    ]
    if render_ok(break_body, expressions, context) != "1" {
        panic("break must stop the loop")
    }
    let continue_body: [TemplateNode] = [
        LoopNode {
            item: "item",
            iterable: 0,
            body: [
                IfNode {
                    branches: [TemplateIfBranch { test: 3, body: [ContinueNode] }],
                    alternate: []
                },
                interpolation(1)
            ]
        }
    ]
    if render_ok(continue_body, expressions, context) != "13" {
        panic("continue must skip the current iteration")
    }
}

[test]
micro test_render_filters_functions_tests() -> unit {
    let context: TemplateValue = template_object([
        template_field("name", template_text("  deja ")),
        template_field("xs", template_array([template_number(1.0), template_number(2.0)]))
    ])
    # name |> trim |> upper
    let trim_upper: [TemplateExpression] = [
        identifier("name"),
        Pipe { expression: 0, filter: "trim", arguments: [] },
        Pipe { expression: 1, filter: "upper", arguments: [] }
    ]
    if render_ok([interpolation(2)], trim_upper, context) != "DEJA" {
        panic("trim/upper pipeline mismatch")
    }
    # missing |> default('fallback')
    let defaulted: [TemplateExpression] = [
        identifier("missing"),
        literal_string("fallback"),
        Pipe { expression: 0, filter: "default", arguments: [1] }
    ]
    if render_ok([interpolation(2)], defaulted, context) != "fallback" {
        panic("default filter mismatch")
    }
    # xs |> length
    let length_pipe: [TemplateExpression] = [identifier("xs"), Pipe { expression: 0, filter: "length", arguments: [] }]
    if render_ok([interpolation(1)], length_pipe, context) != "2" {
        panic("length filter mismatch")
    }
    # xs |> join('-')
    let join_pipe: [TemplateExpression] = [
        identifier("xs"),
        literal_string("-"),
        Pipe { expression: 0, filter: "join", arguments: [1] }
    ]
    if render_ok([interpolation(2)], join_pipe, context) != "1-2" {
        panic("join filter mismatch")
    }
    # range(1, 4) |> join('-')
    let range_join: [TemplateExpression] = [
        identifier("range"),
        literal_number(1.0),
        literal_number(4.0),
        Call { callee: 0, arguments: [1, 2] },
        literal_string("-"),
        Pipe { expression: 3, filter: "join", arguments: [4] }
    ]
    if render_ok([interpolation(5)], range_join, context) != "1-2-3" {
        panic("range function mismatch")
    }
    # min(3, 7) "-" max(3, 7)
    let min_max: [TemplateExpression] = [
        identifier("min"),
        identifier("max"),
        literal_number(3.0),
        literal_number(7.0),
        Call { callee: 0, arguments: [2, 3] },
        Call { callee: 1, arguments: [2, 3] }
    ]
    if render_ok([interpolation(4), literal_text_node("-"), interpolation(5)], min_max, context) != "3-7" {
        panic("min/max mismatch")
    }
    # missing is null
    let is_null: [TemplateExpression] = [identifier("missing"), Test { expression: 0, name: "null", arguments: [], negated: false }]
    let is_null_body: [TemplateNode] = [
        IfNode {
            branches: [TemplateIfBranch { test: 1, body: [literal_text_node("null")] }],
            alternate: []
        }
    ]
    if render_ok(is_null_body, is_null, context) != "null" {
        panic("is null test mismatch")
    }
    # name is not empty
    let not_empty: [TemplateExpression] = [identifier("name"), Test { expression: 0, name: "empty", arguments: [], negated: true }]
    let not_empty_body: [TemplateNode] = [
        IfNode {
            branches: [TemplateIfBranch { test: 1, body: [literal_text_node("full")] }],
            alternate: []
        }
    ]
    if render_ok(not_empty_body, not_empty, context) != "full" {
        panic("is not empty test mismatch")
    }
    # 4 is even
    let is_even: [TemplateExpression] = [literal_number(4.0), Test { expression: 0, name: "even", arguments: [], negated: false }]
    let is_even_body: [TemplateNode] = [
        IfNode {
            branches: [TemplateIfBranch { test: 1, body: [literal_text_node("even")] }],
            alternate: []
        }
    ]
    if render_ok(is_even_body, is_even, context) != "even" {
        panic("even test mismatch")
    }
}

[test]
micro test_render_object_literal_and_member() -> unit {
    # { greeting: 'hi' }.greeting
    let expressions: [TemplateExpression] = [
        literal_string("hi"),
        ObjectLiteral { entries: [TemplateObjectEntry { key: "greeting", value: 0 }] },
        Member { object: 1, property: "greeting" }
    ]
    if render_ok([interpolation(2)], expressions, template_object([])) != "hi" {
        panic("object literal member mismatch")
    }
}

[test]
micro test_render_comment_skipped() -> unit {
    # "a" 注释 "b"
    let body: [TemplateNode] = [
        literal_text_node("a"),
        CommentNode { text: "<# note #>" },
        literal_text_node("b")
    ]
    let expressions: [TemplateExpression] = []
    if render_ok(body, expressions, template_object([])) != "ab" {
        panic("comment must not render")
    }
}

[test]
micro test_render_unknown_filter_rejected() -> unit {
    let expressions: [TemplateExpression] = [identifier("name"), Pipe { expression: 0, filter: "shout", arguments: [] }]
    if first_render_error([interpolation(1)], expressions, template_object([])) != "template.render.unknown_filter" {
        panic("unknown_filter diagnostic expected")
    }
}

[test]
micro test_render_invalid_iterable_rejected() -> unit {
    let context: TemplateValue = template_object([template_field("xs", template_number(1.0))])
    let expressions: [TemplateExpression] = [identifier("xs")]
    let body: [TemplateNode] = [LoopNode { item: "item", iterable: 0, body: [] }]
    if first_render_error(body, expressions, context) != "template.render.invalid_iterable" {
        panic("invalid_iterable diagnostic expected")
    }
}

[test]
micro test_render_strict_undefined_rejected() -> unit {
    let expressions: [TemplateExpression] = [identifier("missing")]
    let outcome: DataOutcome<utf8> = render_doc_strict([interpolation(0)], expressions, template_object([]))
    let diagnostics: [Diagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() == 0 {
        panic("strict undefined must register a diagnostic")
    }
    if diagnostic_code(diagnostics⁅0⁆.unwrap()) != "template.render.undefined_variable" {
        panic("undefined_variable diagnostic expected")
    }
    # 非 strict 下缺失标识符渲染为空串，不报错。
    if render_ok([interpolation(0)], expressions, template_object([])) != "" {
        panic("missing identifier must render as empty string")
    }
}

[test]
micro test_render_number_fraction_gap_fails_closed() -> unit {
    let fraction: [TemplateExpression] = [literal_number(1.5)]
    if first_render_error([interpolation(0)], fraction, template_object([])) != "template.render.number_fraction" {
        panic("number_fraction diagnostic expected")
    }
    # 整数值不受影响。
    let integral: [TemplateExpression] = [literal_number(42.0)]
    if render_ok([interpolation(0)], integral, template_object([])) != "42" {
        panic("integral number must render exactly")
    }
}
