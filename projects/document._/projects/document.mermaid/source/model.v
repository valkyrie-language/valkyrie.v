namespace document.mermaid;

using document.plot::{PlotDecl, PlotEdge};

# 解析产物：两种图场景的材料清单。

unite MermaidDiagram {
    [constructor]
    MermaidFlowchart {
        nodes: [PlotDecl]
        edges: [PlotEdge]
    }
    [constructor]
    MermaidSequence {
        participants: [PlotDecl]
        messages: [PlotEdge]
    }
}

# 行解析游标（1 基序数，与 `Utf8Text` 序数合同一致）。
structure MermaidCursor {
    text: utf8
    position: usize
}

structure MermaidNodeSpec {
    id: utf8
    label: Option<utf8>
}

structure MermaidSpecStep {
    cursor: MermaidCursor
    spec: Option<MermaidNodeSpec>
}

structure MermaidEdgeSpec {
    source: MermaidNodeSpec
    target: MermaidNodeSpec
    label: utf8
}

structure MermaidEdgeStep {
    cursor: MermaidCursor
    edge: Option<MermaidEdgeSpec>
}
