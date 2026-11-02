namespace std.data.text.mermaid;

using document.plot::{PlotDecl, PlotEdge, PlotSeqEvent};

# 解析产物：两种图场景的材料清单（元素用 `document.plot` 的类型；
# 布局与发射归 `document.plotter`）。

unite MermaidDiagram {
    [constructor]
    MermaidFlowchart {
        nodes: [PlotDecl]
        edges: [PlotEdge]
    }
    [constructor]
    MermaidSequence {
        participants: [PlotDecl]
        events: [PlotSeqEvent]
    }
}

# 语句解释的中间形态（`label` 缺席 = 未写标签；`shape` 0 矩形/1 菱形/2 圆角）。
structure MermaidNodeSpec {
    id: utf8
    label: Option<utf8>
    shape: i32
}

structure MermaidEdgeSpec {
    source: MermaidNodeSpec
    target: MermaidNodeSpec
    label: utf8
    bidirectional: bool
}
