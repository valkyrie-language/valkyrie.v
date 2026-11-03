namespace document.layout;

# 拍平：把盒树展开为带绝对位置的原子序列，供矢量文本输出消费。
#
# 坐标约定：y 轴向下；`baseline` 是基线 y 坐标。`PlacedBox` 只保留可画材料
# （原子与实心规则），glue 只影响位置不产出。

structure PlacedBox {
    text: utf8
    x: f64
    baseline: f64
    metrics: BoxMetrics
    font_size: f64
    is_rule: bool
}

micro box_place(node: BoxNode, x: f64, baseline: f64) -> [PlacedBox] {
    match node {
        case BoxAtom(payload):
            return [PlacedBox {
                text: payload.text,
                x: x,
                baseline: baseline,
                metrics: payload.metrics,
                font_size: payload.font_size,
                is_rule: false
            }]
        case BoxRule(payload):
            # 零面积规则是占位支撑（行距等），不是可画材料，拍平时丢弃。
            if payload.metrics.width <= 0.0 || payload.metrics.height + payload.metrics.depth <= 0.0 {
                return []
            }
            return [PlacedBox {
                text: "",
                x: x,
                baseline: baseline,
                metrics: payload.metrics,
                font_size: 0.0,
                is_rule: true
            }]
        case BoxGlue(payload):
            return []
        case BoxHBox(payload):
            return box_place_hbox_children(payload.children, x, baseline)
        case BoxVBox(payload):
            return box_place_vbox_children(payload.children, x, baseline, payload.metrics)
        case BoxShift(payload):
            if payload.content.length() == 0 {
                return []
            }
            return box_place(payload.content⁅0⁆, x, baseline - payload.offset)
    }
}

micro box_place_hbox_children(children: [BoxNode], x: f64, baseline: f64) -> [PlacedBox] {
    let mut out: [PlacedBox] = []
    let mut cursor: f64 = x
    let mut index: usize = 0
    while index < children.length() {
        let child: BoxNode = children⁅index⁆
        let placed: [PlacedBox] = box_place(child, cursor, baseline)
        let mut inner: usize = 0
        while inner < placed.length() {
            out = push(out, placed⁅inner⁆)
            inner = inner + 1
        }
        cursor = cursor + box_metrics(child).width
        index = index + 1
    }
    return out
}

# 垂直堆叠：顶 = `baseline` − vbox.height；逐子盒下移，子盒基线 = 游标 + 子盒高。
micro box_place_vbox_children(children: [BoxNode], x: f64, baseline: f64, vbox_metrics: BoxMetrics) -> [PlacedBox] {
    let mut out: [PlacedBox] = []
    let mut cursor: f64 = baseline - vbox_metrics.height
    let mut index: usize = 0
    while index < children.length() {
        let child: BoxNode = children⁅index⁆
        let metrics: BoxMetrics = box_metrics(child)
        let child_baseline: f64 = cursor + metrics.height
        let placed: [PlacedBox] = box_place(child, x, child_baseline)
        let mut inner: usize = 0
        while inner < placed.length() {
            out = push(out, placed⁅inner⁆)
            inner = inner + 1
        }
        cursor = cursor + metrics.height + metrics.depth
        index = index + 1
    }
    return out
}
