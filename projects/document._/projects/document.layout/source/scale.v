namespace document.layout;

# 缩放：整棵盒树按比例缩放（上下标等 script 尺寸消费）。
# 度量、`font_size`、glue 自然宽、shift 位移全部随因子缩放；文本内容不变。

micro box_scale(node: BoxNode, factor: f64) -> BoxNode {
    match node {
        case BoxAtom(payload):
            return BoxAtom {
                text: payload.text,
                metrics: box_metrics_of(payload.metrics.width * factor, payload.metrics.height * factor, payload.metrics.depth * factor),
                font_size: payload.font_size * factor
            }
        case BoxRule(payload):
            return BoxRule {
                metrics: box_metrics_of(payload.metrics.width * factor, payload.metrics.height * factor, payload.metrics.depth * factor)
            }
        case BoxGlue(payload):
            return BoxGlue {
                natural: payload.natural * factor
            }
        case BoxHBox(payload):
            let mut children: [BoxNode] = []
            let mut index: usize = 0
            while index < payload.children.length() {
                children = push(children, box_scale(payload.children⁅index⁆, factor))
                index = index + 1
            }
            return box_hbox(children)
        case BoxVBox(payload):
            let mut children: [BoxNode] = []
            let mut index: usize = 0
            while index < payload.children.length() {
                children = push(children, box_scale(payload.children⁅index⁆, factor))
                index = index + 1
            }
            return box_vbox(children)
        case BoxShift(payload):
            if payload.content.length() == 0 {
                return node
            }
            return box_shift(box_scale(payload.content⁅0⁆, factor), payload.offset * factor)
    }
}
