namespace std.data.text.tex;

using std.collection::{HashMap};
using std.data::{DataCstNode, DataOutcome, DataSettings, DataSource, DataToken, data_cst_missing, data_cst_span, data_outcome_diagnostics, data_outcome_failed, data_outcome_partial, data_outcome_value_or, data_source_from_text, new_data_settings};
using std.diagnostic::{Diagnostic, Error, Warning, Span, new_diagnostic, new_span};
using vutex::{MathNode, math_aligned, math_big_op, math_delimited, math_frac, math_matrix, math_row, math_scripts, math_sqrt, math_symbol};

# 语义段：CST -> `vutex::MathNode`。词素按 span 从源切回。
# 映射规则：`Space` trivia 丢弃（TeX 空白不表义）；`Illegal` 原样映射为
# 可见符号（诊断已在词法段登记）；`Missing`/`Poison` 子树跳过（诊断已在
# 语法段登记）；未知命令映射为命令名符号并登记 `tex.build.unknown_command`
# （Warning，内容可见可降级）。希腊字母命令映射为对应字形。

# 希腊字母命令 → 字形：表驱动（数据而非控制流）。
micro tex_greek_table() -> HashMap<utf8, utf8> {
    let mut table: HashMap<utf8, utf8> = HashMap::new(32)
    table.insert("alpha", "α")
    table.insert("beta", "β")
    table.insert("gamma", "γ")
    table.insert("delta", "δ")
    table.insert("epsilon", "ε")
    table.insert("zeta", "ζ")
    table.insert("eta", "η")
    table.insert("theta", "θ")
    table.insert("iota", "ι")
    table.insert("kappa", "κ")
    table.insert("lambda", "λ")
    table.insert("mu", "μ")
    table.insert("nu", "ν")
    table.insert("xi", "ξ")
    table.insert("pi", "π")
    table.insert("rho", "ρ")
    table.insert("sigma", "σ")
    table.insert("tau", "τ")
    table.insert("upsilon", "υ")
    table.insert("phi", "φ")
    table.insert("chi", "χ")
    table.insert("psi", "ψ")
    table.insert("omega", "ω")
    return table
}

micro tex_greek_glyph(name: utf8) -> Option<utf8> {
    return tex_greek_table().get(name)
}

structure TexBuildState {
    text: utf8
    diagnostics: [Diagnostic]
}

structure TexMapOut {
    state: TexBuildState
    has_value: bool
    node: Option<MathNode>
}

micro tex_map_none(state: TexBuildState) -> TexMapOut {
    return TexMapOut {
        state: state,
        has_value: false,
        node: None
    }
}

micro tex_map_some(state: TexBuildState, node: MathNode) -> TexMapOut {
    return TexMapOut {
        state: state,
        has_value: true,
        node: Some(node)
    }
}

micro tex_lexeme(state: TexBuildState, span: Span) -> utf8 {
    return state.text.slice(span.start, span.end - span.start)
}

micro tex_diagnose(state: TexBuildState, code: utf8, message: utf8, span: Span) -> TexBuildState {
    return TexBuildState {
        text: state.text,
        diagnostics: push(state.diagnostics, new_diagnostic(code, Warning, message, span))
    }
}

micro tex_build_children(children: [DataCstNode<TexTokenKind>], state: TexBuildState) -> [MathNode] {
    let mut out: [MathNode] = []
    let mut current: TexBuildState = state
    let mut index: usize = 0
    while index < children.length() {
        let mapped: TexMapOut = tex_build_node(children⁅index⁆, current)
        current = mapped.state
        if mapped.has_value {
            out = push(out, mapped.node.unwrap())
        }
        index = index + 1
    }
    return out
}

# 子节点映射（缺席/占位即空行）；诊断经 `TexBuildState` 线程化，不丢。
micro tex_build_child_or_empty(children: [DataCstNode<TexTokenKind>], index: usize, state: TexBuildState) -> TexMapOut {
    if index >= children.length() {
        return tex_map_some(state, math_row([]))
    }
    let mapped: TexMapOut = tex_build_node(children⁅index⁆, state)
    if mapped.has_value {
        return mapped
    }
    return tex_map_some(mapped.state, math_row([]))
}

micro tex_build_node(node: DataCstNode<TexTokenKind>, state: TexBuildState) -> TexMapOut {
    match node {
        case Node(payload):
            match payload.kind {
                case NodeRoot:
                    return tex_map_some(state, math_row(tex_build_children(payload.children, state)))
                case NodeRow:
                    return tex_map_some(state, math_row(tex_build_children(payload.children, state)))
                case NodeGroup:
                    return tex_map_some(state, math_row(tex_build_children(payload.children, state)))
                case NodeAtom:
                    return tex_build_atom(payload.children, state)
                case NodeFrac:
                    return tex_build_frac(payload.children, state)
                case NodeSqrt:
                    return tex_build_sqrt(payload.children, state)
                case NodeScripts:
                    return tex_build_scripts(payload.children, state)
                case NodeBigOp:
                    return tex_map_some(state, math_big_op("∑", [], []))
                case NodeDelimited:
                    return tex_build_delimited(payload.children, state)
                case NodeEnvironment:
                    return tex_build_environment(payload.children, state)
                case NodeEnvRow:
                    return tex_map_some(state, math_row(tex_build_children(payload.children, state)))
                case NodeEnvCell:
                    return tex_map_some(state, math_row(tex_build_children(payload.children, state)))
                else:
                    return tex_map_none(state)
            }
        case Token(payload):
            match payload.token.kind {
                case Illegal:
                    return tex_map_some(state, math_symbol(tex_lexeme(state, payload.token.span)))
                else:
                    return tex_map_none(state)
            }
        case Missing(payload):
            return tex_map_none(state)
        case Poison(payload):
            return tex_map_none(state)
    }
}

micro tex_build_atom(children: [DataCstNode<TexTokenKind>], state: TexBuildState) -> TexMapOut {
    if children.length() == 0 {
        return tex_map_none(state)
    }
    match children⁅0⁆ {
        case Token(payload):
            match payload.token.kind {
                case Command:
                    let name: utf8 = tex_lexeme(state, payload.token.span).slice(1, payload.token.span.end - payload.token.span.start - 1)
                    let glyph: Option<utf8> = tex_greek_glyph(name)
                    if glyph.is_some() {
                        return tex_map_some(state, math_symbol(glyph.unwrap()))
                    }
                    let diagnosed: TexBuildState = tex_diagnose(state, "tex.build.unknown_command", "command outside the supported subset, kept as plain symbol", payload.token.span)
                    return tex_map_some(diagnosed, math_symbol(name))
                case Symbol:
                    return tex_map_some(state, math_symbol(tex_lexeme(state, payload.token.span)))
                else:
                    return tex_map_none(state)
            }
        else:
            return tex_map_none(state)
    }
}

micro tex_build_frac(children: [DataCstNode<TexTokenKind>], state: TexBuildState) -> TexMapOut {
    let numerator: TexMapOut = tex_build_child_or_empty(children, 1, state)
    let denominator: TexMapOut = tex_build_child_or_empty(children, 2, numerator.state)
    return tex_map_some(denominator.state, math_frac(numerator.node.unwrap(), denominator.node.unwrap()))
}

micro tex_build_sqrt(children: [DataCstNode<TexTokenKind>], state: TexBuildState) -> TexMapOut {
    let radicand: TexMapOut = tex_build_child_or_empty(children, 1, state)
    return tex_map_some(radicand.state, math_sqrt(radicand.node.unwrap()))
}

# 脚本链：基项后跟 `Token(Sup/Sub)` + 原子对；`Poison`（同槽重复）跳过。
micro tex_build_scripts(children: [DataCstNode<TexTokenKind>], state: TexBuildState) -> TexMapOut {
    if children.length() == 0 {
        return tex_map_none(state)
    }
    let base_out: TexMapOut = tex_build_child_or_empty(children, 0, state)
    let base: MathNode = base_out.node.unwrap()
    let mut current: TexBuildState = base_out.state
    let mut superscript: [MathNode] = []
    let mut subscript: [MathNode] = []
    let mut index: usize = 1
    while index < children.length() {
        let mut slot: usize = 0
        match children⁅index⁆ {
            case Token(payload):
                match payload.token.kind {
                    case Sup:
                        slot = 1
                    case Sub:
                        slot = 2
                    else:
                        slot = 0
                }
            else:
                slot = 0
        }
        if slot > 0 && index + 1 < children.length() {
            let script: TexMapOut = tex_build_child_or_empty(children, index + 1, current)
            current = script.state
            if slot == 1 && superscript.length() == 0 {
                superscript = push(superscript, script.node.unwrap())
            }
            if slot == 2 && subscript.length() == 0 {
                subscript = push(subscript, script.node.unwrap())
            }
            index = index + 2
        } else {
            index = index + 1
        }
    }
    if superscript.length() == 0 && subscript.length() == 0 {
        return tex_map_some(current, base)
    }
    # 大算子的上下限：基项是 `NodeBigOp` 时按上下限承载，不按肩标。
    let mut base_is_big_op: bool = false
    match children⁅0⁆ {
        case Node(payload):
            match payload.kind {
                case NodeBigOp:
                    base_is_big_op = true
                else:
                    base_is_big_op = false
            }
        else:
            base_is_big_op = false
    }
    if base_is_big_op {
        return tex_map_some(current, math_big_op("∑", subscript, superscript))
    }
    return tex_map_some(current, math_scripts(base, superscript, subscript))
}

# 伸缩括号：children = [Token(LeftCommand), 左定界原子, NodeRow 内容, Token(RightCommand), 右定界原子]。
micro tex_build_delimited(children: [DataCstNode<TexTokenKind>], state: TexBuildState) -> TexMapOut {
    let mut left: utf8 = "("
    let mut right: utf8 = ")"
    let mut content: [MathNode] = []
    let mut current: TexBuildState = state
    let left_out: TexMapOut = tex_build_child_or_empty(children, 1, current)
    current = left_out.state
    match left_out.node.unwrap() {
        case MathSymbol(payload):
            left = payload.text
        else:
            left = "("
    }
    let mut content_index: usize = 2
    if children.length() > 2 {
        let content_out: TexMapOut = tex_build_node(children⁅2⁆, current)
        current = content_out.state
        if content_out.has_value {
            content = [content_out.node.unwrap()]
        }
    }
    if children.length() > 4 {
        let right_out: TexMapOut = tex_build_child_or_empty(children, 4, current)
        current = right_out.state
        match right_out.node.unwrap() {
            case MathSymbol(payload):
                right = payload.text
            else:
                right = ")"
        }
    }
    if content.length() == 0 {
        return tex_map_some(current, math_delimited(left, right, []))
    }
    match content⁅0⁆ {
        case MathRow(payload):
            return tex_map_some(current, math_delimited(left, right, payload.children))
        else:
            return tex_map_some(current, math_delimited(left, right, content))
    }
}

# 环境名：编组内符号词素的原样拼接。
micro tex_group_name(node: DataCstNode<TexTokenKind>, state: TexBuildState) -> utf8 {
    match node {
        case Node(payload):
            let mut out: utf8 = ""
            let mut index: usize = 0
            while index < payload.children.length() {
                out = out + tex_group_name(payload.children⁅index⁆, state)
                index = index + 1
            }
            return out
        case Token(payload):
            match payload.token.kind {
                case Symbol:
                    return tex_lexeme(state, payload.token.span)
                else:
                    return ""
            }
        else:
            return ""
    }
}

# 环境：`matrix`/`aligned` 映射为网格；未知名登记 `tex.build.unknown_environment`
# （Warning）并按矩阵网格降级（内容可见）。
micro tex_build_environment(children: [DataCstNode<TexTokenKind>], state: TexBuildState) -> TexMapOut {
    let name: utf8 = if children.length() > 1 { tex_group_name(children⁅1⁆, state) } else { "" }
    let mut current: TexBuildState = state
    let mut rows: [[MathNode]] = []
    let mut index: usize = 2
    while index < children.length() {
        match children⁅index⁆ {
            case Node(payload):
                match payload.kind {
                    case NodeEnvRow:
                        let mut cells: [MathNode] = []
                        let mut cell_index: usize = 0
                        while cell_index < payload.children.length() {
                            match payload.children⁅cell_index⁆ {
                                case Node(cell_node):
                                    match cell_node.kind {
                                        case NodeEnvCell:
                                            let cell_out: TexMapOut = tex_build_node(payload.children⁅cell_index⁆, current)
                                            current = cell_out.state
                                            if cell_out.has_value {
                                                cells = push(cells, cell_out.node.unwrap())
                                            }
                                        else:
                                            current = current
                                    }
                                else:
                                    current = current
                            }
                            cell_index = cell_index + 1
                        }
                        rows = push(rows, cells)
                    else:
                        current = current
                }
            else:
                current = current
        }
        index = index + 1
    }
    if name.equals("matrix") {
        return tex_map_some(current, math_matrix(rows))
    }
    if name.equals("aligned") {
        return tex_map_some(current, math_aligned(rows))
    }
    let diagnosed: TexBuildState = tex_diagnose(current, "tex.build.unknown_environment", "environment outside the supported subset, kept as a matrix grid", data_cst_span(children⁅0⁆))
    return tex_map_some(diagnosed, math_matrix(rows))
}

micro tex_build(node: DataCstNode<TexTokenKind>, source: DataSource, settings: DataSettings) -> DataOutcome<MathNode> {
    match source {
        case Text(payload):
            let state: TexBuildState = TexBuildState {
                text: payload.text,
                diagnostics: []
            }
            let mapped: TexMapOut = tex_build_node(node, state)
            if mapped.has_value {
                return data_outcome_partial(mapped.node.unwrap(), mapped.state.diagnostics)
            }
            return data_outcome_partial(math_row([]), mapped.state.diagnostics)
        case Bytes(payload):
            return data_outcome_failed([new_diagnostic("tex.build.binary_source", Error, "binary source is not TeX math input", new_span(0, 0))])
    }
}

# 便捷管线：文本 -> 数学 AST（三段全链；诊断跨段聚合）。
micro tex_parse_text(text: utf8) -> DataOutcome<MathNode> {
    let settings: DataSettings = new_data_settings(64, 0)
    let source: DataSource = data_source_from_text(text)
    let lexed: DataOutcome<[DataToken<TexTokenKind>]> = tex_lex(source, settings)
    let mut diagnostics: [Diagnostic] = data_outcome_diagnostics(lexed)
    let tokens: [DataToken<TexTokenKind>] = data_outcome_value_or(lexed, [])
    let parsed: DataOutcome<DataCstNode<TexTokenKind>> = tex_parse(tokens, settings)
    diagnostics = tex_concat_diagnostics(diagnostics, data_outcome_diagnostics(parsed))
    let cst: DataCstNode<TexTokenKind> = data_outcome_value_or(parsed, data_cst_missing(new_span(0, 0), "parse failed"))
    let built: DataOutcome<MathNode> = tex_build(cst, source, settings)
    diagnostics = tex_concat_diagnostics(diagnostics, data_outcome_diagnostics(built))
    match built {
        case Fine(payload):
            return data_outcome_partial(payload.value, diagnostics)
        case Partial(payload):
            return data_outcome_partial(payload.value, diagnostics)
        case Failed(payload):
            return data_outcome_failed(diagnostics)
    }
}

micro tex_concat_diagnostics(first: [Diagnostic], second: [Diagnostic]) -> [Diagnostic] {
    let mut out: [Diagnostic] = first
    let mut index: usize = 0
    while index < second.length() {
        out = push(out, second⁅index⁆)
        index = index + 1
    }
    return out
}
