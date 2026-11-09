namespace plotter;

# L2 图结构布局：调用方给出布局模式，本层负责参数映射与结果收集。
#
# 分层、力导向、树、正交布局算法属于 `std.collection.graph` 与
# `std.math.graph_theory`。本层不实现这些算法：能力缺席时返回结构化
# `GraphLayoutUnavailable`，由导入适配器转换成带方言/构造/行号的诊断。
#
# 唯一在本层成立的模式是 `Explicit`：方言自带显式坐标，本层只做画布适配
# （包围盒归一），不推导任何拓扑关系。

enums GraphLayoutMode {
    Explicit
    Layered
    ForceDirected
    Tree
    Orthogonal
}

structure GraphLayoutRequest {
    mode: GraphLayoutMode
    width: f64
    height: f64
    padding: f64
}

structure PlacedNode {
    id: utf8
    x: f64
    y: f64
}

unite GraphLayoutOutcome {
    [constructor]
    LaidOut {
        placements: [PlacedNode]
    }
    [constructor]
    Unavailable {
        capability: utf8
    }
}

# 能力坐标：缺席能力指向的标准库模块入口，供调用方转发与复现。
micro graph_layout_capability(mode: GraphLayoutMode) -> utf8 {
    match mode {
        case Explicit: {
            return "plotter.layout.explicit"
        }
        case Layered: {
            return "std.collection.graph.layered_layout"
        }
        case ForceDirected: {
            return "std.math.graph_theory.force_directed_layout"
        }
        case Tree: {
            return "std.collection.graph.tree_layout"
        }
        case Orthogonal: {
            return "std.collection.graph.orthogonal_routing"
        }
    }
}

micro layout_graph(model: GraphModel, request: GraphLayoutRequest) -> GraphLayoutOutcome {
    match request.mode {
        case Explicit: {
            return graph_layout_explicit(model, request)
        }
        case Layered: {
            return GraphLayoutUnavailable {
                capability: graph_layout_capability(request.mode)
            }
        }
        case ForceDirected: {
            return GraphLayoutUnavailable {
                capability: graph_layout_capability(request.mode)
            }
        }
        case Tree: {
            return GraphLayoutUnavailable {
                capability: graph_layout_capability(request.mode)
            }
        }
        case Orthogonal: {
            return GraphLayoutUnavailable {
                capability: graph_layout_capability(request.mode)
            }
        }
    }
}

# 显式坐标模式：所有节点必须自带位置；否则结构化失败。
# 坐标约定是场景空间（y 向下），本层只按包围盒缩放到给定画布内。
micro graph_layout_explicit(model: GraphModel, request: GraphLayoutRequest) -> GraphLayoutOutcome {
    if model.nodes.length() == 0 {
        return GraphLayoutLaidOut {
            placements: []
        }
    }

    let mut index: usize = 0
    while index < model.nodes.length() {
        if !model.nodes⁅index⁆.has_position {
            return GraphLayoutUnavailable {
                capability: "graph_layout.explicit_position_missing"
            }
        }
        index = index + 1
    }

    let mut min_x: f64 = model.nodes⁅0⁆.x
    let mut max_x: f64 = model.nodes⁅0⁆.x
    let mut min_y: f64 = model.nodes⁅0⁆.y
    let mut max_y: f64 = model.nodes⁅0⁆.y
    index = 1
    while index < model.nodes.length() {
        let node: GraphNode = model.nodes⁅index⁆
        if node.x < min_x { min_x = node.x }
        if node.x > max_x { max_x = node.x }
        if node.y < min_y { min_y = node.y }
        if node.y > max_y { max_y = node.y }
        index = index + 1
    }

    let pad: f64 = if request.padding < 0.0 { 0.0 } else { request.padding }
    let inner_width: f64 = if request.width - pad * 2.0 > 0.0 { request.width - pad * 2.0 } else { 0.0 }
    let inner_height: f64 = if request.height - pad * 2.0 > 0.0 { request.height - pad * 2.0 } else { 0.0 }
    let span_x: f64 = max_x - min_x
    let span_y: f64 = max_y - min_y

    let mut placements: std.collection.ArrayList<PlacedNode> = std.collection.ArrayList::new(model.nodes.length())
    index = 0
    while index < model.nodes.length() {
        let node: GraphNode = model.nodes⁅index⁆
        let x: f64 = if span_x <= 0.0 { pad } else { pad + ((node.x - min_x) / span_x) * inner_width }
        let y: f64 = if span_y <= 0.0 { pad } else { pad + ((node.y - min_y) / span_y) * inner_height }
        placements.push(PlacedNode { id: node.id, x: x, y: y })
        index = index + 1
    }

    return GraphLayoutLaidOut {
        placements: placements.to_array()
    }
}
