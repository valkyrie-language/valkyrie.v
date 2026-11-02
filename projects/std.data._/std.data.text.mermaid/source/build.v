namespace std.data.text.mermaid;

using std.data::{DataCstNode, DataOutcome, DataSettings, DataSource, DataToken, data_outcome_diagnostics, data_outcome_failed, data_outcome_partial, data_outcome_value_or, data_source_from_text, new_data_settings};
using std.diagnostic::{Diagnostic, Error, Span, new_diagnostic, new_span};
using document.plot::{PlotDecl, PlotEdge, PlotSeqEvent, SeqActivate, SeqDeactivate, SeqFrameBegin, SeqFrameElse, SeqFrameEnd, SeqMessage, SeqNote, plot_decl, plot_decl_clustered, plot_edge, plot_edge_full, plot_emit_svg, plot_flowchart, plot_sequence_full, plot_sequence_spec};

# 图装配与便捷管线。header 词定图类：`graph TD/TB`、`flowchart TD/TB`、
# `sequenceDiagram`；不支持即 `Failed`（`mermaid.build.unsupported_header`）。
# sequence 语句：`participant X [as Label]` 与 `A->>B: message`。

structure MermaidDiagramOut {
    state: MermaidBuildState
    has_value: bool
    diagram: Option<MermaidDiagram>
}

micro mermaid_header_words(node: DataCstNode<MermaidTokenKind>, state: MermaidBuildState) -> [utf8] {
    return mermaid_text_words(mermaid_statement_tokens(node), state)
}

micro mermaid_build(node: DataCstNode<MermaidTokenKind>, source: DataSource, settings: DataSettings) -> DataOutcome<MermaidDiagram> {
    match source {
        case Text(payload):
            let state: MermaidBuildState = MermaidBuildState {
                text: payload.text,
                diagnostics: []
            }
            let out: MermaidDiagramOut = mermaid_build_diagram(node, state)
            if out.has_value {
                return data_outcome_partial(out.diagram.unwrap(), out.state.diagnostics)
            }
            return data_outcome_failed(out.state.diagnostics)
        case Bytes(payload):
            return data_outcome_failed([new_diagnostic("mermaid.build.binary_source", Error, "binary source is not mermaid input", new_span(0, 0))])
    }
}

micro mermaid_build_diagram(node: DataCstNode<MermaidTokenKind>, state: MermaidBuildState) -> MermaidDiagramOut {
    match node {
        case Node(payload):
            if payload.children.length() == 0 {
                let diagnosed: MermaidBuildState = mermaid_diagnose(state, "mermaid.build.empty_diagram", "no diagram header found", new_span(0, 0))
                return MermaidDiagramOut {
                    state: diagnosed,
                    has_value: false,
                    diagram: None
                }
            }
            let header: DataCstNode<MermaidTokenKind> = payload.children⁅0⁆
            let words: [utf8] = mermaid_header_words(header, state)
            if words.length() == 0 {
                let diagnosed: MermaidBuildState = mermaid_diagnose(state, "mermaid.build.unsupported_header", "diagram header is empty", new_span(0, 0))
                return MermaidDiagramOut {
                    state: diagnosed,
                    has_value: false,
                    diagram: None
                }
            }
            let first: utf8 = words⁅0⁆
            if first.equals("sequenceDiagram") {
                return mermaid_build_sequence(payload.children, state)
            }
            let mut is_flowchart: bool = false
            if first.equals("graph") || first.equals("flowchart") {
                is_flowchart = true
            }
            if is_flowchart && words.length() >= 2 && (words⁅1⁆.equals("TD") || words⁅1⁆.equals("TB")) {
                return mermaid_build_flowchart(payload.children, state)
            }
            let diagnosed: MermaidBuildState = mermaid_diagnose(state, "mermaid.build.unsupported_header", "diagram header outside the supported subset", new_span(0, 0))
            return MermaidDiagramOut {
                state: diagnosed,
                has_value: false,
                diagram: None
            }
        else:
            let diagnosed: MermaidBuildState = mermaid_diagnose(state, "mermaid.build.malformed_cst", "diagram root is not a container", new_span(0, 0))
            return MermaidDiagramOut {
                state: diagnosed,
                has_value: false,
                diagram: None
            }
    }
}

micro mermaid_remove_text(items: [utf8], index: usize) -> [utf8] {
    let mut out: [utf8] = []
    let mut position: usize = 0
    while position < items.length() {
        if position != index {
            out = push(out, items⁅position⁆)
        }
        position = position + 1
    }
    return out
}

micro mermaid_build_flowchart(children: [DataCstNode<MermaidTokenKind>], state: MermaidBuildState) -> MermaidDiagramOut {
    let mut current: MermaidBuildState = state
    let mut decls: [PlotDecl] = []
    let mut edges: [PlotEdge] = []
    let mut cluster_stack: [utf8] = []
    let mut index: usize = 1
    while index < children.length() {
        match children⁅index⁆ {
            case Node(payload):
                match payload.kind {
                    case NodeStatement:
                        let tokens: [DataToken<MermaidTokenKind>] = mermaid_statement_tokens(children⁅index⁆)
                        let words: [utf8] = mermaid_text_words(tokens, current)
                        if words.length() > 0 && words⁅0⁆.equals("subgraph") {
                            if words.length() >= 2 {
                                cluster_stack = push(cluster_stack, words⁅1⁆)
                            } else {
                                cluster_stack = push(cluster_stack, "subgraph")
                            }
                        } else if words.length() == 1 && words⁅0⁆.equals("end") {
                            if cluster_stack.length() > 0 {
                                cluster_stack = mermaid_remove_text(cluster_stack, cluster_stack.length() - 1)
                            }
                        } else {
                            let spec: Option<MermaidEdgeSpec> = mermaid_interpret_flow_statement(tokens, current)
                            if spec.is_none() {
                                current = mermaid_diagnose(current, "mermaid.build.malformed_statement", "flowchart statement could not be interpreted", payload.span)
                            } else {
                                let edge: MermaidEdgeSpec = spec.unwrap()
                                let cluster: utf8 = if cluster_stack.length() > 0 { cluster_stack⁅cluster_stack.length() - 1⁆ } else { "" }
                                decls = mermaid_register(decls, edge.source, cluster)
                                if edge.target.id.length() > 0 {
                                    decls = mermaid_register(decls, edge.target, cluster)
                                    edges = push(edges, plot_edge_full(edge.source.id, edge.target.id, edge.label, edge.bidirectional))
                                }
                            }
                        }
                    else:
                        current = current
                }
            else:
                current = current
        }
        index = index + 1
    }
    return MermaidDiagramOut {
        state: current,
        has_value: true,
        diagram: Some(MermaidFlowchart {
            nodes: decls,
            edges: edges
        })
    }
}

micro mermaid_build_sequence(children: [DataCstNode<MermaidTokenKind>], state: MermaidBuildState) -> MermaidDiagramOut {
    let mut current: MermaidBuildState = state
    let mut decls: [PlotDecl] = []
    let mut events: [PlotSeqEvent] = []
    let mut index: usize = 1
    while index < children.length() {
        match children⁅index⁆ {
            case Node(payload):
                match payload.kind {
                    case NodeStatement:
                        let tokens: [DataToken<MermaidTokenKind>] = mermaid_statement_tokens(children⁅index⁆)
                        let words: [utf8] = mermaid_text_words(tokens, current)
                        if words.length() > 0 && words⁅0⁆.equals("participant") {
                            let participant: Option<MermaidNodeSpec> = mermaid_interpret_participant(tokens, current)
                            if participant.is_none() {
                                current = mermaid_diagnose(current, "mermaid.build.malformed_participant", "participant statement could not be interpreted", payload.span)
                            } else {
                                decls = mermaid_register(decls, participant.unwrap(), "")
                            }
                        } else if words.length() > 0 && words⁅0⁆.equals("activate") && words.length() >= 2 {
                            events = push(events, SeqActivate {
                                target: words⁅1⁆
                            })
                            decls = mermaid_register(decls, MermaidNodeSpec { id: words⁅1⁆, label: None, shape: 0 }, "")
                        } else if words.length() > 0 && words⁅0⁆.equals("deactivate") && words.length() >= 2 {
                            events = push(events, SeqDeactivate {
                                target: words⁅1⁆
                            })
                        } else if words.length() >= 4 && words⁅0⁆.equals("note") {
                            let event: Option<PlotSeqEvent> = mermaid_interpret_note(tokens, current)
                            if event.is_none() {
                                current = mermaid_diagnose(current, "mermaid.build.malformed_note", "note statement could not be interpreted", payload.span)
                            } else {
                                events = push(events, event.unwrap())
                            }
                        } else if words.length() > 0 && words⁅0⁆.equals("alt") {
                            let mut label: utf8 = ""
                            let mut word_index: usize = 1
                            while word_index < words.length() {
                                if word_index > 1 {
                                    label = label + " "
                                }
                                label = label + words⁅word_index⁆
                                word_index = word_index + 1
                            }
                            events = push(events, SeqFrameBegin {
                                label: "alt " + label
                            })
                        } else if words.length() > 0 && words⁅0⁆.equals("else") {
                            let mut label: utf8 = ""
                            let mut word_index: usize = 1
                            while word_index < words.length() {
                                if word_index > 1 {
                                    label = label + " "
                                }
                                label = label + words⁅word_index⁆
                                word_index = word_index + 1
                            }
                            events = push(events, SeqFrameElse {
                                label: label
                            })
                        } else if words.length() > 0 && words⁅0⁆.equals("end") {
                            events = push(events, SeqFrameEnd)
                        } else {
                            let message: Option<MermaidEdgeSpec> = mermaid_interpret_message(tokens, current)
                            if message.is_none() {
                                current = mermaid_diagnose(current, "mermaid.build.malformed_message", "sequence message could not be interpreted", payload.span)
                            } else {
                                let spec: MermaidEdgeSpec = message.unwrap()
                                decls = mermaid_register(decls, spec.source, "")
                                decls = mermaid_register(decls, spec.target, "")
                                events = push(events, SeqMessage {
                                    source: spec.source.id,
                                    target: spec.target.id,
                                    label: spec.label
                                })
                            }
                        }
                    else:
                        current = current
                }
            else:
                current = current
        }
        index = index + 1
    }
    return MermaidDiagramOut {
        state: current,
        has_value: true,
        diagram: Some(MermaidSequence {
            participants: decls,
            events: events
        })
    }
}

micro mermaid_interpret_participant(tokens: [DataToken<MermaidTokenKind>], state: MermaidBuildState) -> Option<MermaidNodeSpec> {
    let word: Option<utf8> = mermaid_read_word(tokens, MermaidCursor { position: 1 }, state)
    if word.is_none() {
        return None
    }
    let mut label: Option<utf8> = None
    let words: [utf8] = mermaid_text_words(tokens, state)
    if words.length() >= 4 && words⁅2⁆.equals("as") {
        let mut text: utf8 = ""
        let mut index: usize = 3
        while index < words.length() {
            if index > 3 {
                text = text + " "
            }
            text = text + words⁅index⁆
            index = index + 1
        }
        label = Some(text)
    }
    return Some(MermaidNodeSpec {
        id: word.unwrap(),
        label: label,
        shape: 0
    })
}

# `note left of X: text` / `note right of X: text`。
micro mermaid_interpret_note(tokens: [DataToken<MermaidTokenKind>], state: MermaidBuildState) -> Option<PlotSeqEvent> {
    let words: [utf8] = mermaid_text_words(tokens, state)
    if words.length() < 4 {
        return None
    }
    let mut side: i32 = 0
    if words⁅1⁆.equals("left") {
        side = -1
    }
    if words⁅1⁆.equals("right") {
        side = 1
    }
    if side == 0 {
        return None
    }
    if !words⁅2⁆.equals("of") {
        return None
    }
    let mut colon_index: i32 = -1
    let mut index: usize = 0
    while index < tokens.length() {
        match tokens⁅index⁆.kind {
            case Colon:
                colon_index = index as i32
            else:
                colon_index = colon_index
        }
        index = index + 1
    }
    if colon_index < 0 {
        return None
    }
    let mut parts: [DataToken<MermaidTokenKind>] = []
    index = (colon_index as usize) + 1
    while index < tokens.length() {
        parts = push(parts, tokens⁅index⁆)
        index = index + 1
    }
    return Some(SeqNote {
        target: words⁅3⁆,
        side: side,
        text: mermaid_join_lexemes(parts, state)
    })
}

structure MermaidWordOut {
    cursor: MermaidCursor
    word: Option<utf8>
}

micro mermaid_take_word(tokens: [DataToken<MermaidTokenKind>], cursor: MermaidCursor, state: MermaidBuildState) -> MermaidWordOut {
    let here: MermaidCursor = mermaid_skip_spaces(tokens, cursor)
    let maybe: Option<DataToken<MermaidTokenKind>> = mermaid_cur_peek(tokens, here)
    if maybe.is_none() {
        return MermaidWordOut {
            cursor: cursor,
            word: None
        }
    }
    match maybe.unwrap().kind {
        case Text:
            return MermaidWordOut {
                cursor: MermaidCursor {
                    position: here.position + 1
                },
                word: Some(mermaid_lexeme(state, maybe.unwrap().span))
            }
        else:
            return MermaidWordOut {
                cursor: cursor,
                word: None
            }
    }
}

micro mermaid_expect_kind(tokens: [DataToken<MermaidTokenKind>], cursor: MermaidCursor, kind: MermaidTokenKind) -> Option<MermaidCursor> {
    let here: MermaidCursor = mermaid_skip_spaces(tokens, cursor)
    let maybe: Option<DataToken<MermaidTokenKind>> = mermaid_cur_peek(tokens, here)
    if maybe.is_none() {
        return None
    }
    let mut matched: bool = false
    match maybe.unwrap().kind {
        case Arrow:
            matched = kind_matches(kind, "arrow")
        case SeqArrow:
            matched = kind_matches(kind, "seqarrow")
        case Colon:
            matched = kind_matches(kind, "colon")
        else:
            matched = false
    }
    if !matched {
        return None
    }
    return Some(MermaidCursor {
        position: here.position + 1
    })
}

micro kind_matches(kind: MermaidTokenKind, name: utf8) -> bool {
    match kind {
        case Arrow:
            return name.equals("arrow")
        case SeqArrow:
            return name.equals("seqarrow")
        case Colon:
            return name.equals("colon")
        else:
            return false
    }
}

micro mermaid_interpret_message(tokens: [DataToken<MermaidTokenKind>], state: MermaidBuildState) -> Option<MermaidEdgeSpec> {
    let source_out: MermaidWordOut = mermaid_take_word(tokens, MermaidCursor { position: 0 }, state)
    if source_out.word.is_none() {
        return None
    }
    let arrow: Option<MermaidCursor> = mermaid_expect_kind(tokens, source_out.cursor, SeqArrow)
    if arrow.is_none() {
        return None
    }
    let target_out: MermaidWordOut = mermaid_take_word(tokens, arrow.unwrap(), state)
    if target_out.word.is_none() {
        return None
    }
    let colon: Option<MermaidCursor> = mermaid_expect_kind(tokens, target_out.cursor, Colon)
    if colon.is_none() {
        return None
    }
    let mut parts: [DataToken<MermaidTokenKind>] = []
    let mut index: usize = colon.unwrap().position
    while index < tokens.length() {
        parts = push(parts, tokens⁅index⁆)
        index = index + 1
    }
    return Some(MermaidEdgeSpec {
        source: MermaidNodeSpec {
            id: source_out.word.unwrap(),
            label: None,
            shape: 0
        },
        target: MermaidNodeSpec {
            id: target_out.word.unwrap(),
            label: None,
            shape: 0
        },
        label: mermaid_join_lexemes(parts, state),
        bidirectional: false
    })
}
