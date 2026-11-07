namespace plotter;

# L1 图结构家族语义模型：带属性的节点与边。
#
# 本模型不含坐标语义之外的东西：`x`/`y` 只有在方言自带显式位置时才有效
# （`has_position`），否则坐标由 L2 图布局产出。`attrs` 保留方言透传的非
# 几何属性（如 DOT 的 `label`、`shape`），由适配器决定写入哪些键。
#
# 本模型不认识任何方言名、任何输出格式。方言到本模型的映射只发生在
# `format/` 的导入适配器里。

# 节点形状：语义提示，不是某方言的专有形制。
enums GraphNodeShape {
    Rect
    Diamond
    Rounded
    Ellipse
    Point
}

structure GraphAttr {
    key: utf8
    value: utf8
}

structure GraphNode {
    id: utf8
    label: utf8
    shape: GraphNodeShape
    attrs: [GraphAttr]
    x: f64
    y: f64
    has_position: bool
}

structure GraphEdge {
    source: utf8
    target: utf8
    label: utf8
    directed: bool
    attrs: [GraphAttr]
}

structure GraphModel {
    nodes: [GraphNode]
    edges: [GraphEdge]
    attrs: [GraphAttr]
}

micro graph_attr_value(attrs: [GraphAttr], key: utf8) -> Option<utf8> {
    let mut index: usize = 0
    while index < attrs.length() {
        if attrs⁅index⁆.key.equals(key) {
            return Some(attrs⁅index⁆.value)
        }
        index = index + 1
    }
    return None
}

micro graph_node(id: utf8, label: utf8, shape: GraphNodeShape) -> GraphNode {
    return GraphNode {
        id: id,
        label: label,
        shape: shape,
        attrs: [],
        x: 0.0,
        y: 0.0,
        has_position: false
    }
}

micro graph_node_at(id: utf8, label: utf8, shape: GraphNodeShape, x: f64, y: f64) -> GraphNode {
    return GraphNode {
        id: id,
        label: label,
        shape: shape,
        attrs: [],
        x: x,
        y: y,
        has_position: true
    }
}

micro graph_node_with_attrs(node: GraphNode, attrs: [GraphAttr]) -> GraphNode {
    return GraphNode {
        id: node.id,
        label: node.label,
        shape: node.shape,
        attrs: attrs,
        x: node.x,
        y: node.y,
        has_position: node.has_position
    }
}

micro graph_edge(source: utf8, target: utf8, label: utf8, directed: bool) -> GraphEdge {
    return GraphEdge {
        source: source,
        target: target,
        label: label,
        directed: directed,
        attrs: []
    }
}

micro graph_model() -> GraphModel {
    return GraphModel {
        nodes: [],
        edges: [],
        attrs: []
    }
}

micro graph_add_node(model: GraphModel, node: GraphNode) -> GraphModel {
    let mut nodes: ArrayList<GraphNode> = []
    let mut index: usize = 0
    while index < model.nodes.length() {
        nodes.push(model.nodes⁅index⁆)
        index = index + 1
    }
    nodes.push(node)
    return GraphModel {
        nodes: nodes.to_array(),
        edges: model.edges,
        attrs: model.attrs
    }
}

micro graph_add_edge(model: GraphModel, edge: GraphEdge) -> GraphModel {
    let mut edges: ArrayList<GraphEdge> = []
    let mut index: usize = 0
    while index < model.edges.length() {
        edges.push(model.edges⁅index⁆)
        index = index + 1
    }
    edges.push(edge)
    return GraphModel {
        nodes: model.nodes,
        edges: edges.to_array(),
        attrs: model.attrs
    }
}

micro graph_find_node(model: GraphModel, id: utf8) -> Option<GraphNode> {
    let mut index: usize = 0
    while index < model.nodes.length() {
        if model.nodes⁅index⁆.id.equals(id) {
            return Some(model.nodes⁅index⁆)
        }
        index = index + 1
    }
    return None
}
