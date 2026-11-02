namespace std.data.text.mermaid;

using std.data::{DataCstNode, DataToken};
using std.diagnostic::{Span};
using document.plot::{PlotDecl, PlotEdge, plot_decl, plot_edge};

# 语句解释与图装配。裸节点语句以 `target.id` 空串编码（内部约定，不出本包）。

structure MermaidCursor {
    position: usize
}

micro mermaid_cur_peek(tokens: [DataToken<MermaidTokenKind>], cursor: MermaidCursor) -> Option<DataToken<MermaidTokenKind>> {
    if cursor.position >= tokens.length() {
        return None
    }
    return Some(tokens⁅cursor.position⁆)
}

micro mermaid_skip_spaces(tokens: [DataToken<MermaidTokenKind>], cursor: MermaidCursor) -> MermaidCursor {
    let mut current: MermaidCursor = cursor
    let mut running: bool = true
    while running {
        let maybe: Option<DataToken<MermaidTokenKind>> = mermaid_cur_peek(tokens, current)
        let mut is_space: bool = false
        if maybe.is_some() {
            match maybe.unwrap().kind {
                case Space:
                    is_space = true
                else:
                    is_space = false
            }
        }
        if is_space {
            current = MermaidCursor {
                position: current.position + 1
            }
        } else {
            running = false
        }
    }
    return current
}

micro mermaid_read_word(tokens: [DataToken<MermaidTokenKind>], cursor: MermaidCursor, state: MermaidBuildState) -> Option<utf8> {
    let here: MermaidCursor = mermaid_skip_spaces(tokens, cursor)
    let maybe: Option<DataToken<MermaidTokenKind>> = mermaid_cur_peek(tokens, here)
    if maybe.is_none() {
        return None
    }
    match maybe.unwrap().kind {
        case Text:
            return Some(mermaid_lexeme(state, maybe.unwrap().span))
        else:
            return None
    }
}

# 节点规格：`id`、`id[label]`、`id(label)`、`id{label}`（形状 0/2/1）；游标推进到规格之后。
micro mermaid_parse_node_spec(tokens: [DataToken<MermaidTokenKind>], cursor: MermaidCursor, state: MermaidBuildState) -> MermaidSpecOut {
    let word: Option<utf8> = mermaid_read_word(tokens, cursor, state)
    if word.is_none() {
        return MermaidSpecOut {
            cursor: cursor,
            spec: None
        }
    }
    let mut current: MermaidCursor = mermaid_skip_spaces(tokens, cursor)
    current = MermaidCursor {
        position: current.position + 1
    }
    let mut label: Option<utf8> = None
    let mut shape: i32 = 0
    let bracket_probe: MermaidCursor = mermaid_skip_spaces(tokens, current)
    let maybe_bracket: Option<DataToken<MermaidTokenKind>> = mermaid_cur_peek(tokens, bracket_probe)
    let mut open_kind: i32 = 0
    if maybe_bracket.is_some() {
        match maybe_bracket.unwrap().kind {
            case LBracket:
                open_kind = 1
            case LParen:
                open_kind = 2
            case LBrace:
                open_kind = 3
            else:
                open_kind = 0
        }
    }
    if open_kind > 0 {
        if open_kind == 2 {
            shape = 2
        }
        if open_kind == 3 {
            shape = 1
        }
        current = MermaidCursor {
            position: bracket_probe.position + 1
        }
        let mut parts: [DataToken<MermaidTokenKind>] = []
        let mut closed: bool = false
        let mut running: bool = true
        while running {
            let maybe: Option<DataToken<MermaidTokenKind>> = mermaid_cur_peek(tokens, current)
            if maybe.is_none() {
                running = false
            } else {
                let mut is_close: bool = false
                match maybe.unwrap().kind {
                    case RBracket:
                        is_close = open_kind == 1
                    case RParen:
                        is_close = open_kind == 2
                    case RBrace:
                        is_close = open_kind == 3
                    else:
                        is_close = false
                }
                if is_close {
                    closed = true
                    running = false
                } else {
                    parts = push(parts, maybe.unwrap())
                    current = MermaidCursor {
                        position: current.position + 1
                    }
                }
            }
        }
        if !closed {
            return MermaidSpecOut {
                cursor: cursor,
                spec: None
            }
        }
        current = MermaidCursor {
            position: current.position + 1
        }
        label = Some(mermaid_join_lexemes(parts, state))
    }
    return MermaidSpecOut {
        cursor: current,
        spec: Some(MermaidNodeSpec {
            id: word.unwrap(),
            label: label,
            shape: shape
        })
    }
}

structure MermaidSpecOut {
    cursor: MermaidCursor
    spec: Option<MermaidNodeSpec>
}

# flowchart 语句：裸节点或 `A --> B` / `A <--> B`（可带 `|label|`）。
micro mermaid_interpret_flow_statement(tokens: [DataToken<MermaidTokenKind>], state: MermaidBuildState) -> Option<MermaidEdgeSpec> {
    let source_out: MermaidSpecOut = mermaid_parse_node_spec(tokens, MermaidCursor { position: 0 }, state)
    if source_out.spec.is_none() {
        return None
    }
    let source: MermaidNodeSpec = source_out.spec.unwrap()
    let after_source: MermaidCursor = mermaid_skip_spaces(tokens, source_out.cursor)
    if mermaid_cur_peek(tokens, after_source).is_none() {
        return Some(MermaidEdgeSpec {
            source: source,
            target: MermaidNodeSpec {
                id: "",
                label: None,
                shape: 0
            },
            label: "",
            bidirectional: false
        })
    }
    let maybe_arrow: Option<DataToken<MermaidTokenKind>> = mermaid_cur_peek(tokens, after_source)
    let mut is_arrow: bool = false
    let mut bidirectional: bool = false
    if maybe_arrow.is_some() {
        match maybe_arrow.unwrap().kind {
            case Arrow:
                is_arrow = true
            case BiArrow:
                is_arrow = true
                bidirectional = true
            else:
                is_arrow = false
        }
    }
    if !is_arrow {
        return None
    }
    let mut current: MermaidCursor = mermaid_skip_spaces(tokens, MermaidCursor {
        position: after_source.position + 1
    })
    let mut label: utf8 = ""
    let maybe_pipe: Option<DataToken<MermaidTokenKind>> = mermaid_cur_peek(tokens, current)
    let mut has_pipe: bool = false
    if maybe_pipe.is_some() {
        match maybe_pipe.unwrap().kind {
            case Pipe:
                has_pipe = true
            else:
                has_pipe = false
        }
    }
    if has_pipe {
        current = MermaidCursor {
            position: current.position + 1
        }
        let mut parts: [DataToken<MermaidTokenKind>] = []
        let mut closed: bool = false
        let mut running: bool = true
        while running {
            let maybe: Option<DataToken<MermaidTokenKind>> = mermaid_cur_peek(tokens, current)
            if maybe.is_none() {
                running = false
            } else {
                match maybe.unwrap().kind {
                    case Pipe:
                        closed = true
                        running = false
                    else:
                        parts = push(parts, maybe.unwrap())
                        current = MermaidCursor {
                            position: current.position + 1
                        }
                }
            }
        }
        if !closed {
            return None
        }
        current = mermaid_skip_spaces(tokens, MermaidCursor {
            position: current.position + 1
        })
        label = mermaid_join_lexemes(parts, state)
    }
    let target_out: MermaidSpecOut = mermaid_parse_node_spec(tokens, current, state)
    if target_out.spec.is_none() {
        return None
    }
    return Some(MermaidEdgeSpec {
        source: source,
        target: target_out.spec.unwrap(),
        label: label,
        bidirectional: bidirectional
    })
}

# 节点登记：首次出现定身份；带标签规格后写覆盖标签与非默认形状；
# `cluster` 非空时写入聚类归属（外部 subgraph 上下文传入）。
micro mermaid_register(decls: [PlotDecl], spec: MermaidNodeSpec, cluster: utf8) -> [PlotDecl] {
    let mut index: usize = 0
    while index < decls.length() {
        if decls⁅index⁆.id.equals(spec.id) {
            if spec.label.is_some() || spec.shape != 0 {
                let mut updated: [PlotDecl] = decls
                let label: utf8 = if spec.label.is_some() { spec.label.unwrap() } else { decls⁅index⁆.label }
                let shape: i32 = if spec.shape != 0 { spec.shape } else { decls⁅index⁆.shape }
                let keep_cluster: utf8 = if decls⁅index⁆.cluster.length() > 0 { decls⁅index⁆.cluster } else { cluster }
                updated⁅index⁆ = plot_decl_clustered(spec.id, label, shape, keep_cluster)
                return updated
            }
            return decls
        }
        index = index + 1
    }
    if spec.label.is_some() {
        return push(decls, plot_decl_clustered(spec.id, spec.label.unwrap(), spec.shape, cluster))
    }
    return push(decls, plot_decl_clustered(spec.id, spec.id, spec.shape, cluster))
}
