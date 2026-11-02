namespace template;

using std.data::{DataDiagnostic, DataOutcome, DataSettings, data_diagnostic_code, data_outcome_diagnostics, data_outcome_value, new_data_settings};

# 渲染段测试：正例覆盖插值/转义/if/loop/forloop/break/continue/过滤器/函数/测试；
# 反例覆盖未知过滤器、非法迭代、strict 未定义与非整数缺口。

micro render_with(source: utf8, context: TemplateValue) -> DataOutcome<utf8> {
    return template_render_text(source, context, new_data_settings(64, 0), template_default_render_settings())
}

micro render_strict(source: utf8, context: TemplateValue) -> DataOutcome<utf8> {
    return template_render_text(source, context, new_data_settings(64, 0), TemplateRenderSettings { strict_undefined: true, max_depth: 64 })
}

micro render_ok(source: utf8, context: TemplateValue) -> utf8 {
    let outcome: DataOutcome<utf8> = render_with(source, context)
    if data_outcome_diagnostics(outcome).length() != 0 {
        panic("clean render must not register diagnostics")
    }
    return data_outcome_value(outcome)
}

micro first_render_error(source: utf8, context: TemplateValue) -> utf8 {
    let outcome: DataOutcome<utf8> = render_with(source, context)
    let diagnostics: [DataDiagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() == 0 {
        return ""
    }
    return data_diagnostic_code(diagnostics⁅0⁆.unwrap())
}

[test]
micro test_render_text_and_interpolation() -> unit {
    let context: TemplateValue = template_object([template_field("name", template_text("world"))])
    if render_ok("Hello <% name %>!", context) != "Hello world!" {
        panic("interpolation output mismatch")
    }
}

[test]
micro test_render_escapes_html_by_default() -> unit {
    let context: TemplateValue = template_object([template_field("name", template_text("<b>"))])
    if render_ok("<% name %>", context) != "&lt;b&gt;" {
        panic("interpolation must escape html by default")
    }
    if render_ok("<% name |> safe %>", context) != "<b>" {
        panic("safe filter must skip escaping")
    }
    if render_ok("<% name |> escape %>", context) != "&lt;b&gt;" {
        panic("escape filter must escape once")
    }
    # safe 之后再接 pure 过滤器仍要转义（capability 只看最外层）。
    if render_ok("<% name |> safe |> uppercase %>", context) != "&lt;B&gt;" {
        panic("pure filter after safe must re-enable escaping")
    }
}

[test]
micro test_render_if_elif_else() -> unit {
    let context: TemplateValue = template_object([template_field("show", template_boolean(true))])
    if render_ok("<% if show %>yes<% else %>no<% end if %>", context) != "yes" {
        panic("if truthy branch mismatch")
    }
    let hidden: TemplateValue = template_object([template_field("show", template_boolean(false))])
    if render_ok("<% if show %>yes<% else %>no<% end if %>", hidden) != "no" {
        panic("if alternate branch mismatch")
    }
    if render_ok("<% if a %>1<% else if b %>2<% else %>3<% end if %>", hidden) != "3" {
        panic("else-if chain mismatch")
    }
}

[test]
micro test_render_loop_with_forloop() -> unit {
    let items: [TemplateValue] = [template_text("a"), template_text("b"), template_text("c")]
    let context: TemplateValue = template_object([template_field("xs", template_array(items))])
    if render_ok("<% loop item in xs %><% item %>,<% end loop %>", context) != "a,b,c," {
        panic("loop output mismatch")
    }
    if render_ok("<% loop item in xs %><% forloop.index %>:<% item %> <% end loop %>", context) != "1:a 2:b 3:c " {
        panic("forloop metadata mismatch")
    }
    if render_ok("<% loop item in xs %><% if forloop.last %>last<% end if %><% end loop %>", context) != "last" {
        panic("forloop.last mismatch")
    }
    # 空数组零次迭代。
    let empty_context: TemplateValue = template_object([template_field("xs", template_array([]))])
    if render_ok("<% loop item in xs %>x<% end loop %>", empty_context) != "" {
        panic("empty array must render zero iterations")
    }
}

[test]
micro test_render_break_and_continue() -> unit {
    let items: [TemplateValue] = [template_number(1.0), template_number(2.0), template_number(3.0)]
    let context: TemplateValue = template_object([template_field("xs", template_array(items))])
    if render_ok("<% loop item in xs %><% if item == 2 %><% break %><% end if %><% item %><% end loop %>", context) != "1" {
        panic("break must stop the loop")
    }
    if render_ok("<% loop item in xs %><% if item == 2 %><% continue %><% end if %><% item %><% end loop %>", context) != "13" {
        panic("continue must skip the current iteration")
    }
}

[test]
micro test_render_filters_functions_tests() -> unit {
    let context: TemplateValue = template_object([
        template_field("name", template_text("  deja ")),
        template_field("xs", template_array([template_number(1.0), template_number(2.0)]))
    ])
    if render_ok("<% name |> trim |> upper %>", context) != "DEJA" {
        panic("trim/upper pipeline mismatch")
    }
    if render_ok("<% missing |> default('fallback') %>", context) != "fallback" {
        panic("default filter mismatch")
    }
    if render_ok("<% xs |> length %>", context) != "2" {
        panic("length filter mismatch")
    }
    if render_ok("<% xs |> join('-') %>", context) != "1-2" {
        panic("join filter mismatch")
    }
    if render_ok("<% range(1, 4) |> join('-') %>", context) != "1-2-3" {
        panic("range function mismatch")
    }
    if render_ok("<% min(3, 7) %>-<% max(3, 7) %>", context) != "3-7" {
        panic("min/max mismatch")
    }
    if render_ok("<% if missing is null %>null<% end if %>", context) != "null" {
        panic("is null test mismatch")
    }
    if render_ok("<% if name is not empty %>full<% end if %>", context) != "full" {
        panic("is not empty test mismatch")
    }
    if render_ok("<% if 4 is even %>even<% end if %>", context) != "even" {
        panic("even test mismatch")
    }
}

[test]
micro test_render_object_literal_and_member() -> unit {
    let context: TemplateValue = template_object([])
    if render_ok("<% { greeting: 'hi' }.greeting %>", context) != "hi" {
        panic("object literal member mismatch")
    }
}

[test]
micro test_render_comment_and_escape_form() -> unit {
    let context: TemplateValue = template_object([])
    if render_ok("a<# note #>b", context) != "ab" {
        panic("comment must not render")
    }
    if render_ok("<%! if %>", context) != "<% if %>" {
        panic("escape form must render the literal open delimiter")
    }
}

[test]
micro test_render_unknown_filter_rejected() -> unit {
    if first_render_error("<% name |> shout %>", template_object([])) != "template.render.unknown_filter" {
        panic("unknown_filter diagnostic expected")
    }
}

[test]
micro test_render_invalid_iterable_rejected() -> unit {
    let context: TemplateValue = template_object([template_field("xs", template_number(1.0))])
    if first_render_error("<% loop item in xs %><% end loop %>", context) != "template.render.invalid_iterable" {
        panic("invalid_iterable diagnostic expected")
    }
}

[test]
micro test_render_strict_undefined_rejected() -> unit {
    let outcome: DataOutcome<utf8> = render_strict("<% missing %>", template_object([]))
    let diagnostics: [DataDiagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() == 0 {
        panic("strict undefined must register a diagnostic")
    }
    if data_diagnostic_code(diagnostics⁅0⁆.unwrap()) != "template.render.undefined_variable" {
        panic("undefined_variable diagnostic expected")
    }
    # 非 strict 下缺失标识符渲染为空串，不报错。
    if render_ok("<% missing %>", template_object([])) != "" {
        panic("missing identifier must render as empty string")
    }
}

[test]
micro test_render_number_fraction_gap_fails_closed() -> unit {
    if first_render_error("<% 1.5 %>", template_object([])) != "template.render.number_fraction" {
        panic("number_fraction diagnostic expected")
    }
    # 整数值不受影响。
    if render_ok("<% 42 %>", template_object([])) != "42" {
        panic("integral number must render exactly")
    }
}
