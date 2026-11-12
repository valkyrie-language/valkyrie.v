namespace std.data.text.tex;

using std.collection::{HashMap};
using std.data::{DataOutcome, DataSource, DataSettings, DataToken, data_outcome_failed, data_outcome_partial, new_data_token};
using std.diagnostic::{Diagnostic, Error, Warning, new_diagnostic, new_span};
using std.text::{Utf8ByteIndicator, byte_indicates};

# 词法段：源文本 -> token 流。每字符恰好属于一个 token（无损）；
# `Space` 为 trivia 保留。扫描经 `byte_indicates`（均摊 O(1)/元素），
# token span 单位是码点偏移（迭代器字节偏移不进 span）。
#
# 错误容许：非子集字符产 `Illegal` token 并登记
# `tex.lex.illegal_code_point`（Warning）后继续；二进制源登记
# `tex.lex.binary_source`（Error）并产空流。
#
# 单一游标所有者：`TexScanCursor` 持有全部扫描状态——`pending` 是唯一前看槽
# （持有下一个未消费码点，peek 只读不动游标），`position` 是码点 span 坐标，
# `advance` 是唯一消费路径。状态转移规则：peek 到的终止字符要么留在 `pending`
# 交回下一轮（命令名后的非字母字符、单 `\` 后的任意字符），要么随当前词素被
# `advance` 消费并推进游标（`\\` 的第二个反斜杠、命令名的每个字母）——二者
# 必居其一，不存在第二份 look/pending 并行状态。
# 词素全部是连续源区间：命令名以 `slice` 直接引用源文本，无逐字符拼接；
# 本段无转义解码内容，故不需要 builder（解码内容用 builder 的合同见 wit/von 字符串）。

micro tex_is_letter(ch: char) -> bool {
    let code: u32 = ch as u32
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122)
}

# 结构命令名 → token 类：表驱动（数据而非控制流）；未收录者归 `Command`。
micro tex_command_table() -> HashMap<utf8, TexTokenKind> {
    let mut table: HashMap<utf8, TexTokenKind> = HashMap::new(8)
    table.insert("frac", FracCommand)
    table.insert("sqrt", SqrtCommand)
    table.insert("begin", BeginCommand)
    table.insert("end", EndCommand)
    table.insert("sum", SumCommand)
    table.insert("left", LeftCommand)
    table.insert("right", RightCommand)
    return table
}

micro tex_is_digit(ch: char) -> bool {
    let code: u32 = ch as u32
    return code >= 48 && code <= 57
}

micro tex_is_operator(ch: char) -> bool {
    return ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '='
        || ch == '(' || ch == ')' || ch == '[' || ch == ']' || ch == '<' || ch == '>'
        || ch == ',' || ch == ';' || ch == ':' || ch == '!' || ch == '?' || ch == '|'
        || ch == '.' || ch as u32 == 39
}

micro tex_lex(source: DataSource, settings: DataSettings) -> DataOutcome<[DataToken<TexTokenKind>]> {
    match source {
        case Text(payload):
            return tex_scan(payload.text)
        case Bytes(payload):
            return data_outcome_failed([new_diagnostic("tex.lex.binary_source", Error, "binary source is not TeX math input", new_span(0, 0))])
    }
}

micro tex_lex_text(text: utf8) -> DataOutcome<[DataToken<TexTokenKind>]> {
    return tex_scan(text)
}

structure TexScanCursor {
    iter: Utf8ByteIndicator
    pending: Option<(usize, char)>
    position: usize
}

micro tex_scan_cursor_new(text: utf8) -> TexScanCursor {
    let mut iter: Utf8ByteIndicator = byte_indicates(text)
    let first: Option<(usize, char)> = iter.next()
    return TexScanCursor {
        iter: iter,
        pending: first,
        position: 0
    }
}

imply TexScanCursor {
    micro at_end(self) -> bool {
        return self.pending.is_none()
    }

    ⍝ 前看下一个未消费码点；不移动游标。
    micro peek(self) -> Option<char> {
        if self.pending.is_none() {
            return None
        }

        return Some(self.pending.unwrap().1)
    }

    micro peek_is(self, ch: char) -> bool {
        return self.pending.is_some() && self.pending.unwrap().1 == ch
    }

    micro peek_is_letter(self) -> bool {
        return self.pending.is_some() && tex_is_letter(self.pending.unwrap().1)
    }

    ⍝ 唯一消费路径：取走 `pending` 中的码点，推进码点位置，再补满前看槽。
    micro advance(mut self) -> char {
        let ch: char = self.pending.unwrap().1
        self.pending = self.iter.next()
        self.position = self.position + 1
        return ch
    }
}

micro tex_scan(text: utf8) -> DataOutcome<[DataToken<TexTokenKind>]> {
    let mut tokens: [DataToken<TexTokenKind>] = []
    let mut diagnostics: [Diagnostic] = []
    let mut cursor: TexScanCursor = tex_scan_cursor_new(text)

    while !cursor.at_end() {
        let start: usize = cursor.position
        let ch: char = cursor.advance()

        if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
            tokens = push(tokens, new_data_token(Space, start, cursor.position))
        } else if ch == '{' {
            tokens = push(tokens, new_data_token(OpenBrace, start, cursor.position))
        } else if ch == '}' {
            tokens = push(tokens, new_data_token(CloseBrace, start, cursor.position))
        } else if ch == '^' {
            tokens = push(tokens, new_data_token(Sup, start, cursor.position))
        } else if ch == '_' {
            tokens = push(tokens, new_data_token(Sub, start, cursor.position))
        } else if ch == '\\' {
            if cursor.peek_is_letter() {
                # 命令名：逐字母消费；peek 到的非字母终止字符留在 `pending`，交下一轮。
                while cursor.peek_is_letter() {
                    cursor.advance()
                }
                let name: utf8 = text.slice(start + 1, cursor.position - start - 1)
                let kind: TexTokenKind = tex_command_table().get(name).unwrap_or(Command)
                tokens = push(tokens, new_data_token(kind, start, cursor.position))
            } else if cursor.peek_is('\\') {
                # 第二个反斜杠属于当前词素（`\\`），随词素消费并推进游标。
                cursor.advance()
                tokens = push(tokens, new_data_token(DoubleBackslash, start, cursor.position))
            } else {
                # 单反斜杠符号：peek 到的字符（或 EOF）留在 `pending`，由下一轮处理。
                tokens = push(tokens, new_data_token(Symbol, start, cursor.position))
            }
        } else if ch == '&' {
            tokens = push(tokens, new_data_token(Ampersand, start, cursor.position))
        } else if tex_is_letter(ch) || tex_is_digit(ch) || tex_is_operator(ch) {
            tokens = push(tokens, new_data_token(Symbol, start, cursor.position))
        } else {
            tokens = push(tokens, new_data_token(Illegal, start, cursor.position))
            diagnostics = push(diagnostics, new_diagnostic("tex.lex.illegal_code_point", Warning, "code point outside the TeX math subset", new_span(start, cursor.position)))
        }
    }

    return data_outcome_partial(tokens, diagnostics)
}
