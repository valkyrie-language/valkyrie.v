namespace std.data.text.tex;

using std.data::{DataCstNode, DataOutcome, DataSettings, DataToken, data_cst_missing, data_cst_node, data_cst_poison, data_cst_span, data_cst_token, data_outcome_partial};
using std.diagnostic::{Diagnostic, Error, Span, new_diagnostic, new_span};

# 语法段：token 流 -> 无损 CST。`Space`/`Illegal` 原样挂入（trivia 不丢）。
# 恢复语义：未闭合编组以 `Missing` 占位闭合并登记 `tex.parse.unclosed_group`；
# 游离 `}` 原样挂 Token 并登记 `tex.parse.stray_close`；悬空脚本标记登记
# `tex.parse.script_without_base`；脚本后缺原子以 `Missing` 占位并登记
# `tex.parse.missing_atom`；同槽脚本重复登记 `tex.parse.duplicate_script`
# 并把后者挂 `Poison`；编组深度超限挂 `Poison` 并登记 `tex.parse.depth_exceeded`。

structure TexParseState {
    position: usize
    diagnostics: [Diagnostic]
}

structure TexOut {
    node: DataCstNode<TexTokenKind>
    state: TexParseState
}

micro tex_out(node: DataCstNode<TexTokenKind>, state: TexParseState) -> TexOut {
    return TexOut {
        node: node,
        state: state
    }
}

micro tex_peek(tokens: [DataToken<TexTokenKind>], state: TexParseState) -> Option<DataToken<TexTokenKind>> {
    if state.position >= tokens.length() {
        return None
    }
    return Some(tokens⁅state.position⁆)
}

micro tex_advance(state: TexParseState) -> TexParseState {
    return TexParseState {
        position: state.position + 1,
        diagnostics: state.diagnostics
    }
}

micro tex_diagnose(state: TexParseState, code: utf8, message: utf8, span: Span) -> TexParseState {
    return TexParseState {
        position: state.position,
        diagnostics: push(state.diagnostics, new_diagnostic(code, Error, message, span))
    }
}

micro tex_kind_is_space_or_illegal(kind: TexTokenKind) -> bool {
    match kind {
        case Space:
            return true
        case Illegal:
            return true
        else:
            return false
    }
}

micro tex_kind_is_atom(kind: TexTokenKind) -> bool {
    match kind {
        case Command:
            return true
        case Symbol:
            return true
        else:
            return false
    }
}

# 单原子：编组 / 结构命令 / 普通原子；无法构成原子时产 `Missing`。
micro tex_parse_atom(tokens: [DataToken<TexTokenKind>], state: TexParseState, depth: usize, settings: DataSettings) -> TexOut {
    let maybe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, state)
    if maybe.is_none() {
        let position: usize = tex_end_position(tokens)
        return tex_out(data_cst_missing(new_span(position, position), "atom expected at end of input"), tex_diagnose(state, "tex.parse.missing_atom", "script or command expects an atom", new_span(position, position)))
    }
    let token: DataToken<TexTokenKind> = maybe.unwrap()
    if tex_kind_is_atom(token.kind) {
        return tex_out(data_cst_node(NodeAtom, token.span, [data_cst_token(token)]), tex_advance(state))
    }
    match token.kind {
        case OpenBrace:
            return tex_parse_group(tokens, state, depth, settings)
        case FracCommand:
            return tex_parse_frac(tokens, state, depth, settings)
        case SqrtCommand:
            return tex_parse_sqrt(tokens, state, depth, settings)
        else:
            return tex_out(data_cst_missing(token.span, "atom expected"), tex_diagnose(state, "tex.parse.missing_atom", "script or command expects an atom", token.span))
    }
}

micro tex_end_position(tokens: [DataToken<TexTokenKind>]) -> usize {
    if tokens.length() == 0 {
        return 0
    }
    return tokens⁅tokens.length() - 1⁆.span.end
}

micro tex_parse_group(tokens: [DataToken<TexTokenKind>], state: TexParseState, depth: usize, settings: DataSettings) -> TexOut {
    let open: DataToken<TexTokenKind> = tex_peek(tokens, state).unwrap()
    let mut current: TexParseState = tex_advance(state)
    if depth + 1 > settings.max_depth {
        let mut poisoned: [DataCstNode<TexTokenKind>] = [data_cst_token(open)]
        let mut inner_depth: usize = 1
        let mut end: usize = open.span.end
        let mut running: bool = true
        while running {
            let maybe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
            if maybe.is_none() {
                running = false
            } else {
                let token: DataToken<TexTokenKind> = maybe.unwrap()
                poisoned = push(poisoned, data_cst_token(token))
                end = token.span.end
                current = tex_advance(current)
                match token.kind {
                    case OpenBrace:
                        inner_depth = inner_depth + 1
                    case CloseBrace:
                        inner_depth = inner_depth - 1
                        if inner_depth == 0 {
                            running = false
                        }
                    else:
                        inner_depth = inner_depth
                }
            }
        }
        current = tex_diagnose(current, "tex.parse.depth_exceeded", "group nesting exceeds the depth budget", new_span(open.span.start, end))
        return tex_out(data_cst_poison(new_span(open.span.start, end), poisoned, "depth exceeded"), current)
    }
    let row: TexOut = tex_parse_row(tokens, current, true, depth + 1, settings)
    current = row.state
    let mut children: [DataCstNode<TexTokenKind>] = [data_cst_token(open)]
    children = push(children, row.node)
    let closing: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
    let mut end: usize = data_cst_span(row.node).end
    if closing.is_some() {
        match closing.unwrap().kind {
            case CloseBrace:
                children = push(children, data_cst_token(closing.unwrap()))
                end = closing.unwrap().span.end
                current = tex_advance(current)
            else:
                children = push(children, data_cst_missing(new_span(end, end), "close brace expected"))
                current = tex_diagnose(current, "tex.parse.unclosed_group", "group misses its close brace", new_span(end, end))
        }
    } else {
        children = push(children, data_cst_missing(new_span(end, end), "close brace expected"))
        current = tex_diagnose(current, "tex.parse.unclosed_group", "group misses its close brace", new_span(end, end))
    }
    return tex_out(data_cst_node(NodeGroup, new_span(open.span.start, end), children), current)
}

micro tex_parse_frac(tokens: [DataToken<TexTokenKind>], state: TexParseState, depth: usize, settings: DataSettings) -> TexOut {
    let command: DataToken<TexTokenKind> = tex_peek(tokens, state).unwrap()
    let numerator: TexOut = tex_parse_atom(tokens, tex_advance(state), depth, settings)
    let denominator: TexOut = tex_parse_atom(tokens, numerator.state, depth, settings)
    let span: Span = new_span(command.span.start, data_cst_span(denominator.node).end)
    return tex_out(data_cst_node(NodeFrac, span, [data_cst_token(command), numerator.node, denominator.node]), denominator.state)
}

micro tex_parse_sqrt(tokens: [DataToken<TexTokenKind>], state: TexParseState, depth: usize, settings: DataSettings) -> TexOut {
    let command: DataToken<TexTokenKind> = tex_peek(tokens, state).unwrap()
    let radicand: TexOut = tex_parse_atom(tokens, tex_advance(state), depth, settings)
    let span: Span = new_span(command.span.start, data_cst_span(radicand.node).end)
    return tex_out(data_cst_node(NodeSqrt, span, [data_cst_token(command), radicand.node]), radicand.state)
}

# 行解析：直到源末或（`in_group` 时）闭合花括号（闭合符由调用方消费）。
micro tex_parse_row(tokens: [DataToken<TexTokenKind>], state: TexParseState, in_group: bool, depth: usize, settings: DataSettings) -> TexOut {
    let mut current: TexParseState = state
    let mut children: [DataCstNode<TexTokenKind>] = []
    let mut running: bool = true
    while running {
        let maybe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
        if maybe.is_none() {
            running = false
        } else {
            let token: DataToken<TexTokenKind> = maybe.unwrap()
            if tex_kind_is_space_or_illegal(token.kind) {
                children = push(children, data_cst_token(token))
                current = tex_advance(current)
            } else {
                match token.kind {
                    case CloseBrace:
                        if in_group {
                            running = false
                        } else {
                            children = push(children, data_cst_token(token))
                            current = tex_diagnose(tex_advance(current), "tex.parse.stray_close", "close brace without an open group", token.span)
                        }
                    case Sup:
                        children = push(children, data_cst_token(token))
                        current = tex_diagnose(tex_advance(current), "tex.parse.script_without_base", "script marker without a base atom", token.span)
                    case Sub:
                        children = push(children, data_cst_token(token))
                        current = tex_diagnose(tex_advance(current), "tex.parse.script_without_base", "script marker without a base atom", token.span)
                    else:
                        let item: TexOut = tex_parse_item(tokens, current, depth, settings)
                        children = push(children, item.node)
                        current = item.state
                }
            }
        }
    }
    let mut span: Span = new_span(0, 0)
    if children.length() > 0 {
        span = new_span(data_cst_span(children⁅0⁆).start, data_cst_span(children⁅children.length() - 1⁆).end)
    }
    return tex_out(data_cst_node(NodeRow, span, children), current)
}

# 单项：原子加可选脚本链（可换序；同槽重复的后者挂 `Poison`）。
micro tex_parse_item(tokens: [DataToken<TexTokenKind>], state: TexParseState, depth: usize, settings: DataSettings) -> TexOut {
    let base: TexOut = tex_parse_atom(tokens, state, depth, settings)
    let mut current: TexParseState = base.state
    let mut has_sup: bool = false
    let mut has_sub: bool = false
    let mut children: [DataCstNode<TexTokenKind>] = [base.node]
    let mut scripted: bool = false
    let mut scanning: bool = true
    while scanning {
        let maybe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
        let mut is_marker: bool = false
        let mut is_sup: bool = false
        if maybe.is_some() {
            match maybe.unwrap().kind {
                case Sup:
                    is_marker = true
                    is_sup = true
                case Sub:
                    is_marker = true
                    is_sup = false
                else:
                    is_marker = false
            }
        }
        if !is_marker {
            scanning = false
        } else {
            let marker: DataToken<TexTokenKind> = maybe.unwrap()
            let duplicate: bool = (is_sup && has_sup) || (!is_sup && has_sub)
            if is_sup {
                has_sup = true
            } else {
                has_sub = true
            }
            let script: TexOut = tex_parse_atom(tokens, tex_advance(current), depth, settings)
            current = script.state
            scripted = true
            if duplicate {
                let poison_span: Span = new_span(marker.span.start, data_cst_span(script.node).end)
                children = push(children, data_cst_poison(poison_span, [data_cst_token(marker), script.node], "duplicate script slot"))
                current = tex_diagnose(current, "tex.parse.duplicate_script", "script slot already assigned on this base", marker.span)
            } else {
                children = push(children, data_cst_token(marker))
                children = push(children, script.node)
            }
        }
    }
    if !scripted {
        return tex_out(base.node, current)
    }
    let span: Span = new_span(data_cst_span(children⁅0⁆).start, data_cst_span(children⁅children.length() - 1⁆).end)
    return tex_out(data_cst_node(NodeScripts, span, children), current)
}

micro tex_parse(tokens: [DataToken<TexTokenKind>], settings: DataSettings) -> DataOutcome<DataCstNode<TexTokenKind>> {
    let state: TexParseState = TexParseState {
        position: 0,
        diagnostics: []
    }
    let row: TexOut = tex_parse_row(tokens, state, false, 0, settings)
    let span: Span = data_cst_span(row.node)
    return data_outcome_partial(data_cst_node(NodeRoot, span, [row.node]), row.state.diagnostics)
}
