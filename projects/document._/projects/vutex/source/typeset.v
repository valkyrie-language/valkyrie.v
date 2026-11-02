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
                # 上下标碰撞：sup 底与 sub 顶间距不足 0.2em 时对称拉开。
                let sup_box: BoxNode = box_scale(math_typeset(payload.superscript⁅0⁆, font), math_script_scale())
                let sub_box: BoxNode = box_scale(math_typeset(payload.subscript⁅0⁆, font), math_script_scale())
                let mut raise: f64 = math_sup_raise(font)
                let mut drop: f64 = math_sub_drop(font)
                let sup_metrics: BoxMetrics = box_metrics(sup_box)
                let sub_metrics: BoxMetrics = box_metrics(sub_box)
                let min_gap: f64 = font.em * 0.2
                let gap: f64 = raise + drop - sub_metrics.height - sup_box_depth(sup_metrics)
                if gap < min_gap {
                    let extra: f64 = (min_gap - gap) / 2.0
                    raise = raise + extra
                    drop = drop + extra
                }
                let sup: BoxNode = box_shift(sup_box, raise)
                let sub: BoxNode = box_shift(sub_box, 0.0 - drop)
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
        case MathMatrix(payload):
            return math_typeset_matrix(payload.rows, font)
        case MathBigOp(payload):
            return math_typeset_big_op(payload.symbol, payload.under, payload.over, font)
        case MathDelimited(payload):
            return math_typeset_delimited(payload.left, payload.right, payload.content, font)
        case MathAligned(payload):
            return math_typeset_aligned(payload.rows, font)
    }
}

micro sup_box_depth(metrics: BoxMetrics) -> f64 {
    return metrics.depth
}

# 矩阵：列宽取列内最大，单元左对齐；行距 4、单元水平间距 8。
micro math_typeset_matrix(rows: [[MathNode]], font: BoxFont) -> BoxNode {
    let mut column_count: usize = 0
    let mut index: usize = 0
    while index < rows.length() {
        if rows⁅index⁆.length() > column_count {
            column_count = rows⁅index⁆.length()
        }
        index = index + 1
    }
    let mut widths: [f64] = []
    let mut column: usize = 0
    while column < column_count {
        widths = push(widths, 0.0)
        column = column + 1
    }
    index = 0
    while index < rows.length() {
        let mut cell_index: usize = 0
        while cell_index < rows⁅index⁆.length() {
            let cell_width: f64 = box_metrics(math_typeset(rows⁅index⁆⁅cell_index⁆, font)).width
            if cell_width > widths⁅cell_index⁆ {
                widths⁅cell_index⁆ = cell_width
            }
            cell_index = cell_index + 1
        }
        index = index + 1
    }
    let gap: f64 = font.em * 0.8
    let mut row_boxes: [BoxNode] = []
    index = 0
    while index < rows.length() {
        let mut row_children: [BoxNode] = []
        let mut cell_index: usize = 0
        while cell_index < rows⁅index⁆.length() {
            if cell_index > 0 {
                row_children = push(row_children, box_glue(gap))
            }
            row_children = push(row_children, math_typeset(rows⁅index⁆⁅cell_index⁆, font))
            row_children = push(row_children, box_glue(widths⁅cell_index⁆ - box_metrics(row_children⁅row_children.length() - 1⁆).width))
            cell_index = cell_index + 1
        }
        row_boxes = push(row_boxes, box_hbox(row_children))
        if index + 1 < rows.length() {
            row_boxes = push(row_boxes, box_rule(0.0, font.em * 0.4, 0.0))
        }
        index = index + 1
    }
    return box_vbox(row_boxes)
}

# 大算子：符号放大 1.4 倍；上下限按 script 尺寸置于上下，整体按最大宽居中。
micro math_typeset_big_op(symbol: utf8, under: [MathNode], over: [MathNode], font: BoxFont) -> BoxNode {
    let symbol_box: BoxNode = box_scale(box_atom(symbol, font), 1.4)
    let symbol_metrics: BoxMetrics = box_metrics(symbol_box)
    let mut width: f64 = symbol_metrics.width
    let mut under_box: BoxNode = box_hbox([])
    let mut over_box: BoxNode = box_hbox([])
    if under.length() > 0 {
        under_box = box_scale(math_typeset(under⁅0⁆, font), math_script_scale())
        if box_metrics(under_box).width > width {
            width = box_metrics(under_box).width
        }
    }
    if over.length() > 0 {
        over_box = box_scale(math_typeset(over⁅0⁆, font), math_script_scale())
        if box_metrics(over_box).width > width {
            width = box_metrics(over_box).width
        }
    }
    return box_vbox([math_center_in(over_box, width), math_center_in(symbol_box, width), math_center_in(under_box, width)])
}

# 伸缩括号：定界符按内容总高（高+深）缩放（v0 近似：宽度随缩放同步放大）。
micro math_typeset_delimited(left: utf8, right: utf8, content: [MathNode], font: BoxFont) -> BoxNode {
    let inner: BoxNode = math_typeset(math_row(content), font)
    let inner_metrics: BoxMetrics = box_metrics(inner)
    let total: f64 = inner_metrics.height + inner_metrics.depth
    let natural: f64 = font.ascent + font.descent
    let mut scale: f64 = 1.0
    if total > natural {
        scale = total / natural
    }
    let left_box: BoxNode = box_shift(box_scale(box_atom(left, font), scale), inner_metrics.height - font.ascent * scale)
    let right_box: BoxNode = box_shift(box_scale(box_atom(right, font), scale), inner_metrics.height - font.ascent * scale)
    return box_hbox([left_box, inner, right_box])
}

# 多行对齐：奇数单元（对齐点左）右对齐到列宽，偶数单元左对齐；行距 4。
micro math_typeset_aligned(rows: [[MathNode]], font: BoxFont) -> BoxNode {
    let mut column_count: usize = 0
    let mut index: usize = 0
    while index < rows.length() {
        if rows⁅index⁆.length() > column_count {
            column_count = rows⁅index⁆.length()
        }
        index = index + 1
    }
    let mut widths: [f64] = []
    let mut column: usize = 0
    while column < column_count {
        widths = push(widths, 0.0)
        column = column + 1
    }
    index = 0
    while index < rows.length() {
        let mut cell_index: usize = 0
        while cell_index < rows⁅index⁆.length() {
            let cell_width: f64 = box_metrics(math_typeset(rows⁅index⁆⁅cell_index⁆, font)).width
            if cell_width > widths⁅cell_index⁆ {
                widths⁅cell_index⁆ = cell_width
            }
            cell_index = cell_index + 1
        }
        index = index + 1
    }
    let mut row_boxes: [BoxNode] = []
    index = 0
    while index < rows.length() {
        let mut row_children: [BoxNode] = []
        let mut cell_index: usize = 0
        while cell_index < rows⁅index⁆.length() {
            let cell: BoxNode = math_typeset(rows⁅index⁆⁅cell_index⁆, font)
            let pad: f64 = widths⁅cell_index⁆ - box_metrics(cell).width
            if cell_index % 2 == 0 && pad > 0.0 {
                row_children = push(row_children, box_glue(pad))
                row_children = push(row_children, cell)
            } else {
                row_children = push(row_children, cell)
                row_children = push(row_children, box_glue(pad))
            }
            cell_index = cell_index + 1
        }
        row_boxes = push(row_boxes, box_hbox(row_children))
        if index + 1 < rows.length() {
            row_boxes = push(row_boxes, box_rule(0.0, font.em * 0.4, 0.0))
        }
        index = index + 1
    }
    return box_vbox(row_boxes)
}
