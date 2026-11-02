namespace std.data.text.tex;

using std.data::{DataCstNode, DataSettings, DataToken, data_cst_missing, data_cst_node, data_cst_span, data_cst_token};
using std.diagnostic::{Span, new_span};

# 环境与伸缩括号的语法段（`tex_parse_atom` 的下挂实现）。
#
# 环境：`\begin{name}` + 行/单元内容（`\\` 分行、`&` 分单元）+ `\end{name}`；
# 未闭合以 `Missing` 占位并登记 `tex.parse.unclosed_environment`。
# 伸缩括号：`\left X ... \right Y`；未闭合登记 `tex.parse.unclosed_delimiter`。

micro tex_parse_delimited(tokens: [DataToken<TexTokenKind>], state: TexParseState, depth: usize, settings: DataSettings) -> TexOut {
    let left_command: DataToken<TexTokenKind> = tex_peek(tokens, state).unwrap()
    let mut current: TexParseState = tex_advance(state)
    let mut children: [DataCstNode<TexTokenKind>] = [data_cst_token(left_command)]
    # 左定界符：单个符号原子（缺失即 Missing）。
    let left: TexOut = tex_parse_atom(tokens, current, depth, settings)
    children = push(children, left.node)
    current = left.state
    # 内容：直到 RightCommand 或源末。
    let mut running: bool = true
    let mut content: [DataCstNode<TexTokenKind>] = []
    while running {
        let maybe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
        if maybe.is_none() {
            running = false
        } else {
            match maybe.unwrap().kind {
                case RightCommand:
                    running = false
                else:
                    let item: TexOut = tex_parse_item(tokens, current, depth, settings)
                    content = push(content, item.node)
                    current = item.state
            }
        }
    }
    let content_span: Span = if content.length() > 0 { new_span(data_cst_span(content⁅0⁆).start, data_cst_span(content⁅content.length() - 1⁆).end) } else { new_span(0, 0) }
    children = push(children, data_cst_node(NodeRow, content_span, content))
    let right_probe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
    if right_probe.is_some() {
        match right_probe.unwrap().kind {
            case RightCommand:
                children = push(children, data_cst_token(right_probe.unwrap()))
                current = tex_advance(current)
                let right: TexOut = tex_parse_atom(tokens, current, depth, settings)
                children = push(children, right.node)
                current = right.state
            else:
                current = current
        }
    }
    let end: usize = data_cst_span(children⁅children.length() - 1⁆).end
    match tex_last_is_right(children) {
        case true:
            return tex_out(data_cst_node(NodeDelimited, new_span(left_command.span.start, end), children), current)
        else:
            current = tex_diagnose(current, "tex.parse.unclosed_delimiter", "delimited group misses its right delimiter", new_span(end, end))
            children = push(children, data_cst_missing(new_span(end, end), "right delimiter expected"))
            return tex_out(data_cst_node(NodeDelimited, new_span(left_command.span.start, end), children), current)
    }
}

micro tex_last_is_right(children: [DataCstNode<TexTokenKind>]) -> bool {
    if children.length() == 0 {
        return false
    }
    match children⁅children.length() - 1⁆ {
        case Node(payload):
            match payload.kind {
                case NodeAtom:
                    return true
                else:
                    return false
            }
        else:
            return false
    }
}

micro tex_parse_environment(tokens: [DataToken<TexTokenKind>], state: TexParseState, depth: usize, settings: DataSettings) -> TexOut {
    let begin_command: DataToken<TexTokenKind> = tex_peek(tokens, state).unwrap()
    let mut current: TexParseState = tex_advance(state)
    let mut children: [DataCstNode<TexTokenKind>] = [data_cst_token(begin_command)]
    let name: TexOut = tex_parse_atom(tokens, current, depth, settings)
    children = push(children, name.node)
    current = name.state

    let mut running: bool = true
    while running {
        let maybe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
        if maybe.is_none() {
            running = false
        } else {
            match maybe.unwrap().kind {
                case EndCommand:
                    running = false
                case DoubleBackslash:
                    children = push(children, data_cst_token(maybe.unwrap()))
                    current = tex_advance(current)
                else:
                    let row: TexOut = tex_parse_env_row(tokens, current, depth, settings)
                    children = push(children, row.node)
                    current = row.state
            }
        }
    }

    let mut end: usize = data_cst_span(children⁅children.length() - 1⁆).end
    let end_probe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
    if end_probe.is_some() {
        children = push(children, data_cst_token(end_probe.unwrap()))
        current = tex_advance(current)
        let end_name: TexOut = tex_parse_atom(tokens, current, depth, settings)
        children = push(children, end_name.node)
        current = end_name.state
        end = data_cst_span(end_name.node).end
    } else {
        current = tex_diagnose(current, "tex.parse.unclosed_environment", "environment misses its end command", new_span(end, end))
        children = push(children, data_cst_missing(new_span(end, end), "end command expected"))
    }
    return tex_out(data_cst_node(NodeEnvironment, new_span(begin_command.span.start, end), children), current)
}

# 环境行：`&` 分单元、`\\` 在行级由调用方推进；行内容解析到分隔符或行末。
micro tex_parse_env_row(tokens: [DataToken<TexTokenKind>], state: TexParseState, depth: usize, settings: DataSettings) -> TexOut {
    let mut current: TexParseState = state
    let mut cells: [DataCstNode<TexTokenKind>] = []
    let mut running: bool = true
    while running {
        let cell: TexOut = tex_parse_env_cell(tokens, current, depth, settings)
        cells = push(cells, cell.node)
        current = cell.state
        let maybe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
        let mut more: bool = false
        if maybe.is_some() {
            match maybe.unwrap().kind {
                case Ampersand:
                    more = true
                else:
                    more = false
            }
        }
        if more {
            let amp: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
            if amp.is_some() {
                cells = push(cells, data_cst_token(amp.unwrap()))
            }
            current = tex_advance(current)
        } else {
            running = false
        }
    }
    let span: Span = if cells.length() > 0 { new_span(data_cst_span(cells⁅0⁆).start, data_cst_span(cells⁅cells.length() - 1⁆).end) } else { new_span(0, 0) }
    return tex_out(data_cst_node(NodeEnvRow, span, cells), current)
}

micro tex_parse_env_cell(tokens: [DataToken<TexTokenKind>], state: TexParseState, depth: usize, settings: DataSettings) -> TexOut {
    let mut current: TexParseState = state
    let mut children: [DataCstNode<TexTokenKind>] = []
    let mut running: bool = true
    while running {
        let maybe: Option<DataToken<TexTokenKind>> = tex_peek(tokens, current)
        if maybe.is_none() {
            running = false
        } else {
            match maybe.unwrap().kind {
                case Ampersand:
                    running = false
                case DoubleBackslash:
                    running = false
                case EndCommand:
                    running = false
                else:
                    let item: TexOut = tex_parse_item(tokens, current, depth, settings)
                    children = push(children, item.node)
                    current = item.state
            }
        }
    }
    let span: Span = if children.length() > 0 { new_span(data_cst_span(children⁅0⁆).start, data_cst_span(children⁅children.length() - 1⁆).end) } else { new_span(0, 0) }
    return tex_out(data_cst_node(NodeEnvCell, span, children), current)
}

