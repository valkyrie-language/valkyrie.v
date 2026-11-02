namespace document.plot;

# flowchart 布局（TB 方向）：最长路分层，层内按输入序横排。
#
# v0 规则：
# - 节点几何：宽 = 标签码点数 × em + 2×8，高 = em + 2×4；网格统一列宽
#   （全体节点最大宽 + 横向间距 40），层距 = 节点高 + 40，外边距 20。
# - 分层：入度为 0 的节点为第 0 层；其余节点层 = max(前驱层) + 1，
#   按边集做 |V| 轮松弛（无 Bellman-Ford 之外的魔法）；循环依赖按输入序
#   兜底（不可达节点留 0 层）。孤立节点第 0 层。
# - 层内顺序 = 输入声明序。

structure PlotDecl {
    id: utf8
    label: utf8
}

micro plot_decl(id: utf8, label: utf8) -> PlotDecl {
    return PlotDecl {
        id: id,
        label: label
    }
}

micro plot_margin() -> f64 {
    return 20.0
}

micro plot_flowchart_layers(decls: [PlotDecl], edges: [PlotEdge]) -> [usize] {
    let mut layers: [usize] = []
    let mut index: usize = 0
    while index < decls.length() {
        layers = push(layers, 0)
        index = index + 1
    }

    let mut has_incoming: [bool] = []
    index = 0
    while index < decls.length() {
        let mut incoming: bool = false
        let mut edge_index: usize = 0
        while edge_index < edges.length() {
            if edges⁅edge_index⁆.target.equals(decls⁅index⁆.id) && !edges⁅edge_index⁆.source.equals(decls⁅index⁆.id) {
                incoming = true
            }
            edge_index = edge_index + 1
        }
        has_incoming = push(has_incoming, incoming)
        index = index + 1
    }

    let mut rounds: usize = 0
    while rounds < decls.length() {
        let mut changed: bool = false
        let mut edge_index: usize = 0
        while edge_index < edges.length() {
            let mut from_index: usize = 0
            let mut to_index: usize = 0
            let mut scan: usize = 0
            while scan < decls.length() {
                if decls⁅scan⁆.id.equals(edges⁅edge_index⁆.source) {
                    from_index = scan
                }
                if decls⁅scan⁆.id.equals(edges⁅edge_index⁆.target) {
                    to_index = scan
                }
                scan = scan + 1
            }
            if layers⁅from_index⁆ + 1 > layers⁅to_index⁆ {
                layers⁅to_index⁆ = layers⁅from_index⁆ + 1
                changed = true
            }
            edge_index = edge_index + 1
        }
        if !changed {
            rounds = decls.length()
        } else {
            rounds = rounds + 1
        }
    }
    return layers
}

micro plot_flowchart(decls: [PlotDecl], edges: [PlotEdge]) -> PlotScene {
    let font: BoxFont = plot_font()
    let margin: f64 = plot_margin()
    let h_gap: f64 = 40.0
    let v_gap: f64 = 40.0
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

    let layers: [usize] = plot_flowchart_layers(decls, edges)
    let mut layer_count: usize = 0
    let mut max_in_layer: usize = 0
    index = 0
    while index < layers.length() {
        if layers⁅index⁆ + 1 > layer_count {
            layer_count = layers⁅index⁆ + 1
        }
        index = index + 1
    }
    let mut layer_scan: usize = 0
    while layer_scan < layer_count {
        let mut count: usize = 0
        index = 0
        while index < layers.length() {
            if layers⁅index⁆ == layer_scan {
                count = count + 1
            }
            index = index + 1
        }
        if count > max_in_layer {
            max_in_layer = count
        }
        layer_scan = layer_scan + 1
    }

    let mut nodes: [PlotNode] = []
    let mut seen_in_layer: [usize] = []
    layer_scan = 0
    while layer_scan < layer_count {
        seen_in_layer = push(seen_in_layer, 0)
        layer_scan = layer_scan + 1
    }
    index = 0
    while index < decls.length() {
        let layer: usize = layers⁅index⁆
        let slot: usize = seen_in_layer⁅layer⁆
        seen_in_layer⁅layer⁆ = slot + 1
        let label_width: f64 = decls⁅index⁆.label.length() as f64 * font.em + 16.0
        nodes = push(nodes, plot_node(
            decls⁅index⁆.id,
            decls⁅index⁆.label,
            margin + slot as f64 * (max_width + h_gap) + (max_width - label_width) / 2.0,
            margin + layer as f64 * (node_height + v_gap),
            label_width,
            node_height
        ))
        index = index + 1
    }

    return PlotScene {
        width: margin * 2.0 + max_in_layer as f64 * (max_width + h_gap) - h_gap,
        height: margin * 2.0 + layer_count as f64 * (node_height + v_gap) - v_gap,
        nodes: nodes,
        edges: edges,
        lifelines: []
    }
}
