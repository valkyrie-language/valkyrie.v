namespace document.plot;

# sequence 布局：参与者按输入序横排，消息自上而下。
#
# v0 规则：参与者盒在顶部（几何同 flowchart 节点），生命线自盒底垂到
# 画布底；消息 i 位于 `盒底 + (i+1) × 40`；普通消息为生命线间水平箭头，
# 自消息为右侧 stub 回环（发射侧按 `from == to` 处理）。标签放中点上方。

micro plot_sequence(decls: [PlotDecl], messages: [PlotEdge]) -> PlotScene {
    let font: BoxFont = plot_font()
    let margin: f64 = plot_margin()
    let h_gap: f64 = 60.0
    let message_gap: f64 = 40.0
    let node_height: f64 = font.em + 8.0

    let mut max_width: f64 = 0.0
    let mut index: usize = 0
    while index < decls.length() {
        let width: f64 = decls⁅index⁆.label.length() as f64 * font.em + 16.0
        if width > max_width {
            max_width = width
        }
        index = index + 1
    }

    let mut nodes: [PlotNode] = []
    index = 0
    while index < decls.length() {
        let label_width: f64 = decls⁅index⁆.label.length() as f64 * font.em + 16.0
        nodes = push(nodes, plot_node(
            decls⁅index⁆.id,
            decls⁅index⁆.label,
            margin + index as f64 * (max_width + h_gap) + (max_width - label_width) / 2.0,
            margin,
            label_width,
            node_height
        ))
        index = index + 1
    }

    let height: f64 = margin * 2.0 + node_height + (messages.length() as f64 + 1.0) * message_gap

    let mut edges: [PlotEdge] = []
    let mut message_index: usize = 0
    while message_index < messages.length() {
        let message: PlotEdge = messages⁅message_index⁆
        let y: f64 = margin + node_height + (message_index as f64 + 1.0) * message_gap
        let from_x: f64 = plot_sequence_center_of(nodes, message.source)
        let to_x: f64 = plot_sequence_center_of(nodes, message.target)
        edges = push(edges, plot_edge_direct(message.source, message.target, message.label, from_x, y, to_x, y))
        message_index = message_index + 1
    }

    let mut lifelines: [utf8] = []
    index = 0
    while index < decls.length() {
        lifelines = push(lifelines, decls⁅index⁆.id)
        index = index + 1
    }

    return PlotScene {
        width: margin * 2.0 + decls.length() as f64 * (max_width + h_gap) - h_gap,
        height: height,
        nodes: nodes,
        edges: edges,
        lifelines: lifelines
    }
}

micro plot_sequence_center_of(nodes: [PlotNode], id: utf8) -> f64 {
    let mut index: usize = 0
    while index < nodes.length() {
        if nodes⁅index⁆.id.equals(id) {
            return nodes⁅index⁆.x + nodes⁅index⁆.width / 2.0
        }
        index = index + 1
    }
    return 0.0
}

