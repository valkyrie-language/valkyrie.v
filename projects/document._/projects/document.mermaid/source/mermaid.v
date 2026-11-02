namespace document.mermaid;

using document.plot::{PlotDecl, PlotEdge, PlotScene, plot_decl, plot_edge, plot_emit_svg, plot_flowchart, plot_sequence};

# 图头判定与装配。节点登记：首次出现定身份；带标签的规格在首次出现时定标签，
# 后出现带标签规格覆盖标签（mermaid 语义：标签以后写为准的直觉形态）。
# 裸节点语句以 `target.id` 空串编码（内部约定，不出本包）。

micro mermaid_register(decls: [PlotDecl], spec: MermaidNodeSpec) -> [PlotDecl] {
    let mut index: usize = 0
    while index < decls.length() {
        if decls⁅index⁆.id.equals(spec.id) {
            if spec.label.is_some() {
                let mut updated: [PlotDecl] = decls
                updated⁅index⁆ = plot_decl(spec.id, spec.label.unwrap())
                return updated
            }
            return decls
        }
        index = index + 1
    }
    if spec.label.is_some() {
        return push(decls, plot_decl(spec.id, spec.label.unwrap()))
    }
    return push(decls, plot_decl(spec.id, spec.id))
}

micro mermaid_parse(source: utf8) -> Option<MermaidDiagram> {
    let lines: [utf8] = mermaid_split_lines(source)
    let mut header: utf8 = ""
    let mut start: usize = 0
    let mut found: bool = false
    let mut scan: usize = 0
    while scan < lines.length() && !found {
        let trimmed: utf8 = mermaid_trim(lines⁅scan⁆)
        if trimmed.length() > 0 && !trimmed.slice(0, if trimmed.length() >= 2 { 2 } else { trimmed.length() }).equals("%%") {
            header = trimmed
            start = scan + 1
            found = true
        }
        scan = scan + 1
    }
    if !found {
        return None
    }
    if header.equals("graph TD") || header.equals("graph TB") || header.equals("flowchart TD") || header.equals("flowchart TB") {
        return mermaid_parse_flowchart(lines, start)
    }
    if header.equals("sequenceDiagram") {
        return mermaid_parse_sequence(lines, start)
    }
    return None
}

micro mermaid_parse_flowchart(lines: [utf8], start: usize) -> Option<MermaidDiagram> {
    let mut decls: [PlotDecl] = []
    let mut edges: [PlotEdge] = []
    let mut index: usize = start
    while index < lines.length() {
        let line: utf8 = mermaid_trim(lines⁅index⁆)
        let mut skip: bool = false
        if line.length() == 0 {
            skip = true
        }
        if !skip && line.length() >= 2 && line.slice(0, 2).equals("%%") {
            skip = true
        }
        if !skip {
            let step: MermaidEdgeStep = mermaid_parse_flowchart_statement(line)
            if step.edge.is_none() {
                return None
            }
            let spec: MermaidEdgeSpec = step.edge.unwrap()
            decls = mermaid_register(decls, spec.source)
            if spec.target.id.length() > 0 {
                decls = mermaid_register(decls, spec.target)
                edges = push(edges, plot_edge(spec.source.id, spec.target.id, spec.label))
            }
        }
        index = index + 1
    }
    return Some(MermaidFlowchart {
        nodes: decls,
        edges: edges
    })
}

micro mermaid_parse_sequence(lines: [utf8], start: usize) -> Option<MermaidDiagram> {
    let mut decls: [PlotDecl] = []
    let mut messages: [PlotEdge] = []
    let mut index: usize = start
    while index < lines.length() {
        let line: utf8 = mermaid_trim(lines⁅index⁆)
        let mut skip: bool = false
        if line.length() == 0 {
            skip = true
        }
        if !skip && line.length() >= 2 && line.slice(0, 2).equals("%%") {
            skip = true
        }
        if !skip {
            if line.length() > 11 && line.slice(0, 11).equals("participant") && mermaid_is_blank(line[12]) {
                let rest: utf8 = mermaid_trim(line.slice(11, line.length() - 11))
                let id_step: MermaidSpecStep = mermaid_read_identifier(mermaid_cursor(rest))
                if id_step.spec.is_none() {
                    return None
                }
                let mut spec: MermaidNodeSpec = id_step.spec.unwrap()
                let alias_probe: Option<MermaidCursor> = mermaid_expect(mermaid_skip_spaces(id_step.cursor), "as")
                if alias_probe.is_some() {
                    let label_start: MermaidCursor = mermaid_skip_spaces(alias_probe.unwrap())
                    let label: utf8 = mermaid_trim(label_start.text.slice(label_start.position - 1, label_start.text.length() - label_start.position + 1))
                    if label.length() == 0 {
                        return None
                    }
                    spec = MermaidNodeSpec {
                        id: spec.id,
                        label: Some(label)
                    }
                }
                decls = mermaid_register(decls, spec)
            } else {
                let step: MermaidEdgeStep = mermaid_parse_sequence_statement(line)
                if step.edge.is_none() {
                    return None
                }
                let spec: MermaidEdgeSpec = step.edge.unwrap()
                decls = mermaid_register(decls, spec.source)
                decls = mermaid_register(decls, spec.target)
                messages = push(messages, plot_edge(spec.source.id, spec.target.id, spec.label))
            }
        }
        index = index + 1
    }
    return Some(MermaidSequence {
        participants: decls,
        messages: messages
    })
}

# 管线入口：解析 → 布局 → SVG；任何一步失败返回 `None`。
micro mermaid_render_svg(source: utf8) -> Option<utf8> {
    let parsed: Option<MermaidDiagram> = mermaid_parse(source)
    if parsed.is_none() {
        return None
    }
    match parsed.unwrap() {
        case MermaidFlowchart(payload):
            return Some(plot_emit_svg(plot_flowchart(payload.nodes, payload.edges)))
        case MermaidSequence(payload):
            return Some(plot_emit_svg(plot_sequence(payload.participants, payload.messages)))
    }
}
