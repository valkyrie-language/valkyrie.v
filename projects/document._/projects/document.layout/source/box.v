namespace document.layout;

# 盒模型内核：水平/垂直盒、基线、度量。
#
# 坐标约定（拍平与输出共用）：y 轴向下，节点的 `baseline` 是基线的 y 坐标；
# `height` 是基线上方的extent，`depth` 是基线下方的extent。
# 盒模型只知道度量与断行，不知道页面（归 `paginate`），也不知道输出语法
# （归消费方，如 vutex / document.plot / 渲染器）。

structure BoxFont {
    em: f64
    ascent: f64
    descent: f64
}

structure BoxMetrics {
    width: f64
    height: f64
    depth: f64
}

unite BoxNode {
    [constructor]
    BoxAtom {
        text: utf8
        metrics: BoxMetrics
        font_size: f64
    }
    [constructor]
    BoxRule {
        metrics: BoxMetrics
    }
    [constructor]
    BoxGlue {
        natural: f64
    }
    [constructor]
    BoxHBox {
        children: [BoxNode]
        metrics: BoxMetrics
    }
    [constructor]
    BoxVBox {
        children: [BoxNode]
        metrics: BoxMetrics
    }
    [constructor]
    BoxShift {
        content: [BoxNode]
        offset: f64
        metrics: BoxMetrics
    }
}

# v0 字符单元字体：`unit` 即 1 码点宽；ascent/descent 按 8:2 切分。
micro box_char_cell_font(unit: f64) -> BoxFont {
    return BoxFont {
        em: unit,
        ascent: unit * 0.8,
        descent: unit * 0.2
    }
}

micro box_metrics_of(width: f64, height: f64, depth: f64) -> BoxMetrics {
    return BoxMetrics {
        width: width,
        height: height,
        depth: depth
    }
}

# 原子：文本/符号。宽度 = 码点数 × `font.em`（等宽假设）；`font_size` 随盒携带，
# 供输出层定字号（v0 字符单元下取 `font.em`，缩放经 `box_scale`）。
micro box_atom(text: utf8, font: BoxFont) -> BoxNode {
    let count: f64 = text.length() as f64
    return BoxAtom {
        text: text,
        metrics: box_metrics_of(count * font.em, font.ascent, font.descent),
        font_size: font.em
    }
}

# 实心规则：分数线、根号横线等矩形装饰。
micro box_rule(width: f64, height: f64, depth: f64) -> BoxNode {
    return BoxRule {
        metrics: box_metrics_of(width, height, depth)
    }
}

# 水平间隙：v0 不伸缩；断行只允许发生在 glue 处。
micro box_glue(natural: f64) -> BoxNode {
    return BoxGlue {
        natural: natural
    }
}

micro box_metrics(node: BoxNode) -> BoxMetrics {
    match node {
        case BoxAtom(payload):
            return payload.metrics
        case BoxRule(payload):
            return payload.metrics
        case BoxGlue(payload):
            return box_metrics_of(payload.natural, 0.0, 0.0)
        case BoxHBox(payload):
            return payload.metrics
        case BoxVBox(payload):
            return payload.metrics
        case BoxShift(payload):
            return payload.metrics
    }
}

# 水平盒：子盒共享基线。宽 = 各子盒宽之和；高/深 = 各子盒最大高/深。
micro box_hbox(children: [BoxNode]) -> BoxNode {
    let mut width: f64 = 0.0
    let mut height: f64 = 0.0
    let mut depth: f64 = 0.0
    let mut index: usize = 0
    while index < children.length() {
        let metrics: BoxMetrics = box_metrics(children⁅index⁆)
        width = width + metrics.width
        if metrics.height > height {
            height = metrics.height
        }
        if metrics.depth > depth {
            depth = metrics.depth
        }
        index = index + 1
    }
    return BoxHBox {
        children: children,
        metrics: box_metrics_of(width, height, depth)
    }
}

# 垂直盒：子盒自上而下堆叠，盒基线取末子基线。
# 宽 = 各子盒最大宽；高 = 各子盒（高+深）之和 − 末子深；深 = 末子深。空盒三量为 0。
micro box_vbox(children: [BoxNode]) -> BoxNode {
    let mut width: f64 = 0.0
    let mut total: f64 = 0.0
    let mut last_depth: f64 = 0.0
    let mut index: usize = 0
    while index < children.length() {
        let metrics: BoxMetrics = box_metrics(children⁅index⁆)
        if metrics.width > width {
            width = metrics.width
        }
        total = total + metrics.height + metrics.depth
        last_depth = metrics.depth
        index = index + 1
    }
    return BoxVBox {
        children: children,
        metrics: box_metrics_of(width, total - last_depth, last_depth)
    }
}

# 基线位移：`offset > 0` 整体上移（上标），`offset < 0` 下移（下标）。
# `content` 约定恰好一个子盒；位移后 高 += offset，深 −= offset（可为负，如实）。
micro box_shift(child: BoxNode, offset: f64) -> BoxNode {
    let metrics: BoxMetrics = box_metrics(child)
    return BoxShift {
        content: [child],
        offset: offset,
        metrics: box_metrics_of(metrics.width, metrics.height + offset, metrics.depth - offset)
    }
}
