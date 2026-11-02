namespace document.plotter;

# flowchart 布局（TB 方向）：最长路分层，层内按输入序横排。
#
# v0 规则：
# - 节点几何：矩形 宽 = 标签码点数 × em + 2×8、高 = em + 2×4；菱形 宽 = 标签宽
#   ×2 + 24、高 = em + 18；圆角矩形同矩形。网格统一列宽（全体节点最大宽 + 40），
#   层距 = 全体节点最大高 + 40，外边距 20。
# - 分层：入度为 0 的节点为第 0 层；其余节点层 = max(前驱层) + 1，按边集做
#   |V| 轮松弛；循环依赖按输入序兜底（不可达节点留 0 层）。孤立节点第 0 层。
# - 聚类（`PlotDecl.cluster` 非空）：布局不参与分组，发射时按成员包围盒 + 12
#   内缩距画底色框，标签居中置顶。同名聚类共享一个框。
# - 层内顺序 = 输入声明序。

structure PlotDecl {
    id: utf8
    label: utf8
    shape: i32
    cluster: utf8
}

micro plot_decl(id: utf8, label: utf8) -> PlotDecl {
    return PlotDecl {
        id: id,
        label: label,
        shape: 0,
        cluster: ""
    }
}

micro plot_decl_shaped(id: utf8, label: utf8, shape: i32) -> PlotDecl {
    return PlotDecl {
        id: id,
        label: label,
        shape: shape,
        cluster: ""
    }
}

micro plot_decl_clustered(id: utf8, label: utf8, shape: i32, cluster: utf8) -> PlotDecl {
    return PlotDecl {
        id: id,
        label: label,
        shape: shape,
        cluster: cluster
    }
}

micro plot_margin() -> f64 {
    return 20.0
}

micro plot_node_width(decl: PlotDecl, font: BoxFont) -> f64 {
    let label_width: f64 = decl.label.length() as f64 * font.em
    if decl.shape == 1 {
        return label_width * 2.0 + 24.0
    }
    return label_width + 16.0
}

micro plot_node_height(decl: PlotDecl, font: BoxFont) -> f64 {
    if decl.shape == 1 {
        return font.em + 18.0
    }
    return font.em + 8.0
}

micro plot_flowchart_layers(decls: [PlotDecl], edges: [PlotEdge]) -> [usize] {
    let mut layers: [usize] = []
    let mut index: usize = 0
    while index < decls.length() {
        layers = push(layers, 0)
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

    let mut max_width: f64 = 0.0
    let mut max_height: f64 = 0.0
    let mut index: usize = 0
    while index < decls.length() {
        let width: f64 = plot_node_width(decls⁅index⁆, font)
        let height: f64 = plot_node_height(decls⁅index⁆, font)
        if width > max_width {
            max_width = width
        }
        if height > max_height {
            max_height = height
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
        let node_width: f64 = plot_node_width(decls⁅index⁆, font)
        let node_height: f64 = plot_node_height(decls⁅index⁆, font)
        nodes = push(nodes, plot_node_shaped(
            decls⁅index⁆.id,
            decls⁅index⁆.label,
            margin + slot as f64 * (max_width + h_gap) + (max_width - node_width) / 2.0,
            margin + layer as f64 * (max_height + v_gap),
            node_width,
            node_height,
            decls⁅index⁆.shape
        ))
        index = index + 1
    }

    return PlotScene {
        width: margin * 2.0 + max_in_layer as f64 * (max_width + h_gap) - h_gap,
        height: margin * 2.0 + layer_count as f64 * (max_height + v_gap) - v_gap,
        nodes: nodes,
        edges: edges,
        lifelines: [],
        clusters: plot_clusters_of(decls, nodes),
        activations: [],
        notes: [],
        frames: []
    }
}

# 聚类包围盒：成员节点包围盒 + 12 内缩距；同名聚类共享一个框，标签置顶居中。
micro plot_clusters_of(decls: [PlotDecl], nodes: [PlotNode]) -> [PlotCluster] {
    let mut out: [PlotCluster] = []
    let mut index: usize = 0
    while index < decls.length() {
        if decls⁅index⁆.cluster.length() > 0 {
            let mut found: bool = false
            let mut scan: usize = 0
            while scan < out.length() {
                if out⁅scan⁆.label.equals(decls⁅index⁆.cluster) {
                    found = true
                }
                scan = scan + 1
            }
            if !found {
                out = push(out, PlotCluster {
                    label: decls⁅index⁆.cluster,
                    x: 0.0,
                    y: 0.0,
                    width: 0.0,
                    height: 0.0
                })
            }
        }
        index = index + 1
    }
    let mut cluster_index: usize = 0
    while cluster_index < out.length() {
        let mut min_x: f64 = 0.0
        let mut min_y: f64 = 0.0
        let mut max_x: f64 = 0.0
        let mut max_y: f64 = 0.0
        let mut any: bool = false
        index = 0
        while index < decls.length() {
            if decls⁅index⁆.cluster.equals(out⁅cluster_index⁆.label) {
                let mut node_index: usize = 0
                while node_index < nodes.length() {
                    if nodes⁅node_index⁆.id.equals(decls⁅index⁆.id) {
                        let node: PlotNode = nodes⁅node_index⁆
                        if !any {
                            min_x = node.x
                            min_y = node.y
                            max_x = node.x + node.width
                            max_y = node.y + node.height
                            any = true
                        } else {
                            if node.x < min_x {
                                min_x = node.x
                            }
                            if node.y < min_y {
                                min_y = node.y
                            }
                            if node.x + node.width > max_x {
                                max_x = node.x + node.width
                            }
                            if node.y + node.height > max_y {
                                max_y = node.y + node.height
                            }
                        }
                    }
                    node_index = node_index + 1
                }
            }
            index = index + 1
        }
        if any {
            out⁅cluster_index⁆ = PlotCluster {
                label: out⁅cluster_index⁆.label,
                x: min_x - 12.0,
                y: min_y - 12.0,
                width: max_x - min_x + 24.0,
                height: max_y - min_y + 24.0
            }
        }
        cluster_index = cluster_index + 1
    }
    return out
}
