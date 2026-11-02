namespace document.mermaid;

using document.plot::{PlotDecl, PlotEdge, plot_decl, plot_edge};

# 行工具与游标原语。`\r\n` 行尾在切行时剥掉；trim 逐字符扫描（不依赖 host）。

micro mermaid_split_lines(text: utf8) -> [utf8] {
    let mut out: [utf8] = []
    let mut current: utf8 = ""
    let mut position: usize = 1
    let length: usize = text.length()
    while position <= length {
        let c: char = text[position]
        if c == '\n' {
            out = push(out, current)
            current = ""
        } else if c as u32 != 13 {
            current = current + std::text::encode_char_as_utf8(c)
        }
        position = position + 1
    }
    out = push(out, current)
    return out
}

micro mermaid_is_blank(c: char) -> bool {
    return c == ' ' || c == '\t'
}

micro mermaid_trim(text: utf8) -> utf8 {
    let mut start: usize = 1
    let mut stop: usize = text.length()
    while start <= stop && mermaid_is_blank(text[start]) {
        start = start + 1
    }
    while stop >= start && mermaid_is_blank(text[stop]) {
        stop = stop - 1
    }
    if stop < start {
        return ""
    }
    return text.slice(start - 1, stop - start + 1)
}

micro mermaid_cursor(text: utf8) -> MermaidCursor {
    return MermaidCursor {
        text: text,
        position: 1
    }
}

micro mermaid_at_end(cursor: MermaidCursor) -> bool {
    return cursor.position > cursor.text.length()
}

micro mermaid_peek(cursor: MermaidCursor) -> Option<char> {
    return cursor.text.try_get(cursor.position)
}

micro mermaid_advance(cursor: MermaidCursor) -> MermaidCursor {
    return MermaidCursor {
        text: cursor.text,
        position: cursor.position + 1
    }
}

micro mermaid_skip_spaces(cursor: MermaidCursor) -> MermaidCursor {
    let mut current: MermaidCursor = cursor
    let mut running: bool = true
    while running {
        let maybe: Option<char> = mermaid_peek(current)
        if maybe.is_some() && mermaid_is_blank(maybe.unwrap()) {
            current = mermaid_advance(current)
        } else {
            running = false
        }
    }
    return current
}

# 读取定长字面量：游标处必须完整命中 `word`，命中则前进，否则返回 `None`。
micro mermaid_expect(cursor: MermaidCursor, word: utf8) -> Option<MermaidCursor> {
    let length: usize = word.length()
    let mut index: usize = 0
    while index < length {
        let at: Option<char> = cursor.text.try_get(cursor.position + index)
        if at.is_none() {
            return None
        }
        if at.unwrap() != word[index + 1] {
            return None
        }
        index = index + 1
    }
    return Some(MermaidCursor {
        text: cursor.text,
        position: cursor.position + length
    })
}

micro mermaid_is_identifier_char(c: char) -> bool {
    let code: u32 = c as u32
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || (code >= 48 && code <= 57) || c == '_'
}

micro mermaid_read_identifier(cursor: MermaidCursor) -> MermaidSpecStep {
    let mut current: MermaidCursor = cursor
    let mut name: utf8 = ""
    let mut running: bool = true
    while running {
        let maybe: Option<char> = mermaid_peek(current)
        if maybe.is_some() && mermaid_is_identifier_char(maybe.unwrap()) {
            name = name + std::text::encode_char_as_utf8(maybe.unwrap())
            current = mermaid_advance(current)
        } else {
            running = false
        }
    }
    if name.length() == 0 {
        return MermaidSpecStep {
            cursor: cursor,
            spec: None
        }
    }
    return MermaidSpecStep {
        cursor: current,
        spec: Some(MermaidNodeSpec {
            id: name,
            label: None
        })
    }
}

# 节点规格：`id` 或 `id[Label]`；`[` 内标签原样（不 trim，外层语句已 trim）。
micro mermaid_parse_node_spec(cursor: MermaidCursor) -> MermaidSpecStep {
    let id_step: MermaidSpecStep = mermaid_read_identifier(cursor)
    if id_step.spec.is_none() {
        return id_step
    }
    let mut current: MermaidCursor = id_step.cursor
    let mut label: Option<utf8> = None
    let probe: Option<char> = mermaid_peek(current)
    if probe.is_some() && probe.unwrap() == '[' {
        current = mermaid_advance(current)
        let mut text: utf8 = ""
        let mut closing: bool = false
        let mut running: bool = true
        while running {
            let maybe: Option<char> = mermaid_peek(current)
            if maybe.is_none() {
                return MermaidSpecStep {
                    cursor: cursor,
                    spec: None
                }
            }
            let c: char = maybe.unwrap()
            if c == ']' {
                closing = true
                running = false
            } else {
                text = text + std::text::encode_char_as_utf8(c)
                current = mermaid_advance(current)
            }
        }
        if !closing {
            return MermaidSpecStep {
                cursor: cursor,
                spec: None
            }
        }
        current = mermaid_advance(current)
        label = Some(text)
    }
    let id: MermaidNodeSpec = id_step.spec.unwrap()
    return MermaidSpecStep {
        cursor: current,
        spec: Some(MermaidNodeSpec {
            id: id.id,
            label: label
        })
    }
}

# flowchart 语句：`A[Label] --> B[Label]`、`A -->|label| B`、裸节点 `A[Label]`。
micro mermaid_parse_flowchart_statement(line: utf8) -> MermaidEdgeStep {
    let source_step: MermaidSpecStep = mermaid_parse_node_spec(mermaid_skip_spaces(mermaid_cursor(line)))
    if source_step.spec.is_none() {
        return MermaidEdgeStep {
            cursor: mermaid_cursor(line),
            edge: None
        }
    }
    let source: MermaidNodeSpec = source_step.spec.unwrap()
    let after_source: MermaidCursor = mermaid_skip_spaces(source_step.cursor)
    if mermaid_at_end(after_source) {
        return MermaidEdgeStep {
            cursor: after_source,
            edge: Some(MermaidEdgeSpec {
                source: source,
                target: MermaidNodeSpec {
                    id: "",
                    label: None
                },
                label: ""
            })
        }
    }
    let arrow: Option<MermaidCursor> = mermaid_expect(after_source, "-->")
    if arrow.is_none() {
        return MermaidEdgeStep {
            cursor: after_source,
            edge: None
        }
    }
    let mut current: MermaidCursor = mermaid_skip_spaces(arrow.unwrap())
    let mut label: utf8 = ""
    let bar: Option<char> = mermaid_peek(current)
    if bar.is_some() && bar.unwrap() == '|' {
        current = mermaid_advance(current)
        let mut closing: bool = false
        let mut running: bool = true
        while running {
            let maybe: Option<char> = mermaid_peek(current)
            if maybe.is_none() {
                return MermaidEdgeStep {
                    cursor: current,
                    edge: None
                }
            }
            let c: char = maybe.unwrap()
            if c == '|' {
                closing = true
                running = false
            } else {
                label = label + std::text::encode_char_as_utf8(c)
                current = mermaid_advance(current)
            }
        }
        if !closing {
            return MermaidEdgeStep {
                cursor: current,
                edge: None
            }
        }
        current = mermaid_skip_spaces(mermaid_advance(current))
    }
    let target_step: MermaidSpecStep = mermaid_parse_node_spec(current)
    if target_step.spec.is_none() {
        return MermaidEdgeStep {
            cursor: current,
            edge: None
        }
    }
    if !mermaid_at_end(mermaid_skip_spaces(target_step.cursor)) {
        return MermaidEdgeStep {
            cursor: target_step.cursor,
            edge: None
        }
    }
    return MermaidEdgeStep {
        cursor: target_step.cursor,
        edge: Some(MermaidEdgeSpec {
            source: source,
            target: target_step.spec.unwrap(),
            label: label
        })
    }
}

# sequence 语句：`A->>B: message`；`participant X as Label` 由调用方先判。
micro mermaid_parse_sequence_statement(line: utf8) -> MermaidEdgeStep {
    let source_step: MermaidSpecStep = mermaid_read_identifier(mermaid_cursor(line))
    if source_step.spec.is_none() {
        return MermaidEdgeStep {
            cursor: mermaid_cursor(line),
            edge: None
        }
    }
    let arrow: Option<MermaidCursor> = mermaid_expect(source_step.cursor, "->>")
    if arrow.is_none() {
        return MermaidEdgeStep {
            cursor: source_step.cursor,
            edge: None
        }
    }
    let target_step: MermaidSpecStep = mermaid_read_identifier(arrow.unwrap())
    if target_step.spec.is_none() {
        return MermaidEdgeStep {
            cursor: arrow.unwrap(),
            edge: None
        }
    }
    let colon: Option<MermaidCursor> = mermaid_expect(mermaid_skip_spaces(target_step.cursor), ":")
    if colon.is_none() {
        return MermaidEdgeStep {
            cursor: target_step.cursor,
            edge: None
        }
    }
    let message_start: MermaidCursor = colon.unwrap()
    let message: utf8 = mermaid_trim(message_start.text.slice(message_start.position - 1, message_start.text.length() - message_start.position + 1))
    return MermaidEdgeStep {
        cursor: message_start,
        edge: Some(MermaidEdgeSpec {
            source: source_step.spec.unwrap(),
            target: target_step.spec.unwrap(),
            label: message
        })
    }
}
