namespace vutex;

using document.layout::{BoxFont, BoxMetrics, BoxNode, box_atom, box_char_cell_font, box_glue, box_hbox, box_metrics, box_rule, box_scale, box_shift, box_vbox};

# 数学 AST → 盒树。
#
# 常数（v0，相对 `font.em` 的比例，取二进制可精确表示的值保证确定性）：
# - script 缩放 3/4；上标位移 1/2；下标位移 1/4
# - 行内薄间隙 1/4（`MathRow` 相邻项之间）
# - 分式线/根号线厚度 1/20；根号与内容间隔 1/10

micro math_script_scale() -> f64 {
    return 0.75
}

micro math_sup_raise(font: BoxFont) -> f64 {
    return font.em * 0.5
}

micro math_sub_drop(font: BoxFont) -> f64 {
    return font.em * 0.25
}

micro math_thin_glue(font: BoxFont) -> f64 {
    return font.em * 0.25
}

micro math_rule_thickness(font: BoxFont) -> f64 {
    return font.em * 0.05
}

micro math_default_font() -> BoxFont {
    return box_char_cell_font(10.0)
}

# 把子盒在给定宽度内居中（glue 填充两侧）；`width` 不小于子盒宽。
micro math_center_in(child: BoxNode, width: f64) -> BoxNode {
    let pad: f64 = (width - box_metrics(child).width) / 2.0
    return box_hbox([box_glue(pad), child, box_glue(pad)])
}

micro math_typeset(node: MathNode, font: BoxFont) -> BoxNode {
    match node {
        case MathSymbol(payload):
            return box_atom(payload.text, font)
        case MathRow(payload):
            let mut children: [BoxNode] = []
            let mut index: usize = 0
            while index < payload.children.length() {
                if index > 0 {
                    children = push(children, box_glue(math_thin_glue(font)))
                }
                children = push(children, math_typeset(payload.children⁅index⁆, font))
                index = index + 1
            }
            return box_hbox(children)
        case MathFrac(payload):
            let numerator: BoxNode = math_typeset(payload.numerator⁅0⁆, font)
            let denominator: BoxNode = math_typeset(payload.denominator⁅0⁆, font)
            let num_width: f64 = box_metrics(numerator).width
            let den_width: f64 = box_metrics(denominator).width
            let mut width: f64 = num_width
            if den_width > num_width {
                width = den_width
            }
            let rule: BoxNode = box_rule(width, math_rule_thickness(font), 0.0)
            return box_vbox([math_center_in(numerator, width), rule, math_center_in(denominator, width)])
        case MathSqrt(payload):
            let inner: BoxNode = math_typeset(payload.radicand⁅0⁆, font)
            let bar: BoxNode = box_rule(box_metrics(inner).width, math_rule_thickness(font), 0.0)
            return box_hbox([box_atom("√", font), box_glue(font.em * 0.1), box_vbox([bar, inner])])
        case MathScripts(payload):
            let base: BoxNode = math_typeset(payload.base⁅0⁆, font)
            let has_sup: bool = payload.superscript.length() > 0
            let has_sub: bool = payload.subscript.length() > 0
            if has_sup && has_sub {
                let sup: BoxNode = box_shift(box_scale(math_typeset(payload.superscript⁅0⁆, font), math_script_scale()), math_sup_raise(font))
                let sub: BoxNode = box_shift(box_scale(math_typeset(payload.subscript⁅0⁆, font), math_script_scale()), 0.0 - math_sub_drop(font))
                return box_hbox([base, box_vbox([sup, sub])])
            }
            if has_sup {
                let sup_only: BoxNode = box_shift(box_scale(math_typeset(payload.superscript⁅0⁆, font), math_script_scale()), math_sup_raise(font))
                return box_hbox([base, sup_only])
            }
            if has_sub {
                let sub_only: BoxNode = box_shift(box_scale(math_typeset(payload.subscript⁅0⁆, font), math_script_scale()), 0.0 - math_sub_drop(font))
                return box_hbox([base, sub_only])
            }
            return base
    }
}
