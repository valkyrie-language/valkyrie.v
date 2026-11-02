namespace vutex;

# TeX 数学子集解析：`utf8` → `Option<MathNode>`。
#
# 失败模型 v0：任何畸形输入（未闭合编组、悬空脚本、未支持命令、游离 `}`）
# 返回 `None`，不产占位树。空白符在项间忽略（TeX 数学空白由排版侧管理）。
#
# 文法（v0）：
#   row    := item*                         （`{` 内或全源）
#   item   := atom (`^` atom)? (`_` atom)?  （两脚本可换序，同脚本重复即畸形）
#   atom   := `{` row `}` | `\` command | symbol
#   command:= `frac` `{` row `}` `{` row `}` | `sqrt` `{` row `}` | 希腊字母名
#   symbol := 字母 | 数字 | 运算符单字符

structure MathCursor {
    text: utf8
    position: usize
}

structure MathStep {
    cursor: MathCursor
    node: Option<MathNode>
}

micro math_cursor(text: utf8) -> MathCursor {
    return MathCursor {
        text: text,
        position: 1
    }
}

micro math_cursor_at_end(cursor: MathCursor) -> bool {
    return cursor.position > cursor.text.length()
}

micro math_cursor_peek(cursor: MathCursor) -> Option<char> {
    return cursor.text.try_get(cursor.position)
}

micro math_cursor_advance(cursor: MathCursor) -> MathCursor {
    return MathCursor {
        text: cursor.text,
        position: cursor.position + 1
    }
}

micro math_step_none(cursor: MathCursor) -> MathStep {
    return MathStep {
        cursor: cursor,
        node: None
    }
}

micro math_step_some(cursor: MathCursor, node: MathNode) -> MathStep {
    return MathStep {
        cursor: cursor,
        node: Some(node)
    }
}

micro math_is_letter(c: char) -> bool {
    let code: u32 = c as u32
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122)
}

micro math_is_digit(c: char) -> bool {
    let code: u32 = c as u32
    return code >= 48 && code <= 57
}

micro math_is_operator(c: char) -> bool {
    return c == '+' || c == '-' || c == '*' || c == '/' || c == '='
        || c == '(' || c == ')' || c == '[' || c == ']' || c == '<' || c == '>'
        || c == ',' || c == ';' || c == ':' || c == '!' || c == '?' || c == '|'
        || c == '.' || c as u32 == 39
}

# 读 `\` 后的命令名（连续 ASCII 字母）；游标停在命令名之后。
micro math_read_command(cursor: MathCursor) -> MathStep {
    let mut current: MathCursor = cursor
    let mut name: utf8 = ""
    let mut reading: bool = true
    while reading {
        let maybe: Option<char> = math_cursor_peek(current)
        if maybe.is_none() {
            reading = false
        } else {
            let c: char = maybe.unwrap()
            if math_is_letter(c) {
                name = name + std::text::encode_char_as_utf8(c)
                current = math_cursor_advance(current)
            } else {
                reading = false
            }
        }
    }
    if name.length() == 0 {
        return math_step_none(cursor)
    }
    return math_step_some(current, math_symbol(name))
}

# 解析一个 `{` 编组（前导空白忽略）；非 `{` 开头即畸形。
micro math_parse_braced(cursor: MathCursor) -> MathStep {
    let mut current: MathCursor = cursor
    let mut skipping: bool = true
    while skipping {
        let maybe: Option<char> = math_cursor_peek(current)
        if maybe.is_some() && maybe.unwrap() == ' ' {
            current = math_cursor_advance(current)
        } else {
            skipping = false
        }
    }
    let brace: Option<char> = math_cursor_peek(current)
    if brace.is_none() || brace.unwrap() != '{' {
        return math_step_none(cursor)
    }
    return math_parse_row(math_cursor_advance(current), true)
}

micro math_node_is_scripts(node: MathNode) -> bool {
    match node {
        case MathScripts(payload):
            return true
        else:
            return false
    }
}

# 已挂脚本的项合并新脚本：同槽位重复即畸形（`None`）。
micro math_scripts_merge(node: MathNode, script: MathNode, is_sup: bool) -> Option<MathNode> {
    match node {
        case MathScripts(payload):
            if is_sup && payload.superscript.length() == 0 {
                return Some(MathScripts {
                    base: payload.base,
                    superscript: [script],
                    subscript: payload.subscript
                })
            }
            if !is_sup && payload.subscript.length() == 0 {
                return Some(MathScripts {
                    base: payload.base,
                    superscript: payload.superscript,
                    subscript: [script]
                })
            }
            return None
        else:
            return None
    }
}

micro math_parse_row(cursor: MathCursor, in_brace: bool) -> MathStep {
    let mut current: MathCursor = cursor
    let mut items: [MathNode] = []
    let mut running: bool = true
    while running {
        let maybe: Option<char> = math_cursor_peek(current)
        if maybe.is_none() {
            if in_brace {
                return math_step_none(current)
            }
            return math_step_some(current, math_row(items))
        }
        let c: char = maybe.unwrap()
        if c == ' ' {
            current = math_cursor_advance(current)
        } else if c == '}' {
            if !in_brace {
                return math_step_none(current)
            }
            return math_step_some(math_cursor_advance(current), math_row(items))
        } else if c == '^' || c == '_' {
            if items.length() == 0 {
                return math_step_none(current)
            }
            let script_step: MathStep = math_parse_atom(math_cursor_advance(current))
            if script_step.node.is_none() {
                return math_step_none(current)
            }
            current = script_step.cursor
            let script_node: MathNode = script_step.node.unwrap()
            let last_index: usize = items.length() - 1
            let base: MathNode = items⁅last_index⁆
            let mut merged: Option<MathNode> = math_scripts_merge(base, script_node, c == '^')
            if merged.is_none() && !math_node_is_scripts(base) {
                if c == '^' {
                    merged = Some(math_scripts(base, [script_node], []))
                } else {
                    merged = Some(math_scripts(base, [], [script_node]))
                }
            }
            if merged.is_none() {
                return math_step_none(current)
            }
            items⁅last_index⁆ = merged.unwrap()
        } else {
            let atom_step: MathStep = math_parse_atom(current)
            if atom_step.node.is_none() {
                return math_step_none(current)
            }
            items = push(items, atom_step.node.unwrap())
            current = atom_step.cursor
        }
    }
    return math_step_none(current)
}

micro math_parse_atom(cursor: MathCursor) -> MathStep {
    let maybe: Option<char> = math_cursor_peek(cursor)
    if maybe.is_none() {
        return math_step_none(cursor)
    }
    let c: char = maybe.unwrap()
    if c == '{' {
        return math_parse_row(math_cursor_advance(cursor), true)
    }
    if c == '\\' {
        let after_slash: MathCursor = math_cursor_advance(cursor)
        let probe: Option<char> = math_cursor_peek(after_slash)
        if probe.is_none() {
            return math_step_none(cursor)
        }
        if !math_is_letter(probe.unwrap()) {
            # `\` 后非字母：按单字符符号处理（如 `\!`）；v0 不解释其语义。
            return math_step_some(math_cursor_advance(after_slash), math_symbol(std::text::encode_char_as_utf8(probe.unwrap())))
        }
        let command_step: MathStep = math_read_command(after_slash)
        if command_step.node.is_none() {
            return math_step_none(cursor)
        }
        let name_node: MathNode = command_step.node.unwrap()
        let mut name: utf8 = ""
        match name_node {
            case MathSymbol(payload):
                name = payload.text
            else:
                name = ""
        }
        if name.equals("frac") {
            let numerator_step: MathStep = math_parse_braced(command_step.cursor)
            if numerator_step.node.is_none() {
                return math_step_none(cursor)
            }
            let denominator_step: MathStep = math_parse_braced(numerator_step.cursor)
            if denominator_step.node.is_none() {
                return math_step_none(cursor)
            }
            return math_step_some(denominator_step.cursor, math_frac(numerator_step.node.unwrap(), denominator_step.node.unwrap()))
        }
        if name.equals("sqrt") {
            let radicand_step: MathStep = math_parse_braced(command_step.cursor)
            if radicand_step.node.is_none() {
                return math_step_none(cursor)
            }
            return math_step_some(radicand_step.cursor, math_sqrt(radicand_step.node.unwrap()))
        }
        let glyph: Option<utf8> = math_greek_glyph(name)
        if glyph.is_some() {
            return math_step_some(command_step.cursor, math_symbol(glyph.unwrap()))
        }
        return math_step_none(cursor)
    }
    if math_is_letter(c) || math_is_digit(c) || math_is_operator(c) {
        return math_step_some(math_cursor_advance(cursor), math_symbol(std::text::encode_char_as_utf8(c)))
    }
    return math_step_none(cursor)
}

# 全源入口：整源必须消费完；任何畸形返回 `None`。
micro math_parse(text: utf8) -> Option<MathNode> {
    let step: MathStep = math_parse_row(math_cursor(text), false)
    if step.node.is_none() {
        return None
    }
    if !math_cursor_at_end(step.cursor) {
        return None
    }
    return step.node
}
