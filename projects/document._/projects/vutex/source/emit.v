namespace vutex;

using document.layout::{BoxFont, BoxMetrics, BoxNode, PlacedBox, box_metrics, box_place};
using document.vector::{svg_document, svg_rect, svg_text};

# 盒树 → SVG 矢量文本。画布 = 盒度量 + 四周 2/5 em 留白；
# 原子发 `<text>`（y 取基线），实心规则发 `<rect>`。

micro math_canvas_pad(font: BoxFont) -> f64 {
    return font.em * 0.4
}

micro math_emit_svg(node: BoxNode, font: BoxFont) -> utf8 {
    let metrics: BoxMetrics = box_metrics(node)
    let pad: f64 = math_canvas_pad(font)
    let width: f64 = metrics.width + pad * 2.0
    let height: f64 = metrics.height + metrics.depth + pad * 2.0
    let placed: [PlacedBox] = box_place(node, pad, pad + metrics.height)
    let mut body: utf8 = ""
    let mut index: usize = 0
    while index < placed.length() {
        let item: PlacedBox = placed⁅index⁆
        if item.is_rule {
            body = body + svg_rect(item.x, item.baseline - item.metrics.height, item.metrics.width, item.metrics.height + item.metrics.depth, "#000000")
        } else {
            body = body + svg_text(item.x, item.baseline, item.text, "#000000", item.font_size)
        }
        index = index + 1
    }
    return svg_document(width, height, body)
}
