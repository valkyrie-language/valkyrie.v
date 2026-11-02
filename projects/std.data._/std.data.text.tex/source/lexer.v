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

micro tex_scan(text: utf8) -> DataOutcome<[DataToken<TexTokenKind>]> {
    let mut tokens: [DataToken<TexTokenKind>] = []
    let mut diagnostics: [Diagnostic] = []
    let mut iter: Utf8ByteIndicator = byte_indicates(text)
    let mut index: usize = 0
    let mut pending: Option<(usize, char)> = iter.next()
    while pending.is_some() {
        let ch: char = pending.unwrap().1
        let start: usize = index
        index = index + 1
        if ch == ' ' || ch == '\t' || ch == '\n' || ch as u32 == 13 {
            tokens = push(tokens, new_data_token(Space, start, index))
            pending = iter.next()
        } else if ch == '{' {
            tokens = push(tokens, new_data_token(OpenBrace, start, index))
            pending = iter.next()
        } else if ch == '}' {
            tokens = push(tokens, new_data_token(CloseBrace, start, index))
            pending = iter.next()
        } else if ch == '^' {
            tokens = push(tokens, new_data_token(Sup, start, index))
            pending = iter.next()
        } else if ch == '_' {
            tokens = push(tokens, new_data_token(Sub, start, index))
            pending = iter.next()
        } else if ch == '\\' {
            let mut look: Option<(usize, char)> = iter.next()
            let mut is_command: bool = false
            if look.is_some() && tex_is_letter(look.unwrap().1) {
                is_command = true
            }
            if is_command {
                while look.is_some() && tex_is_letter(look.unwrap().1) {
                    index = index + 1
                    look = iter.next()
                }
                # 结构命令按名分流（表驱动）；其余归 `Command`（语义归 builder）。
                let name: utf8 = text.slice(start + 1, index - start - 1)
                let kind: TexTokenKind = tex_command_table().get(name).unwrap_or(Command)
                tokens = push(tokens, new_data_token(kind, start, index))
            } else {
                if look.is_some() && look.unwrap().1 == '\\' {
                    index = index + 1
                    tokens = push(tokens, new_data_token(DoubleBackslash, start, index))
                    pending = iter.next()
                } else {
                    tokens = push(tokens, new_data_token(Symbol, start, index))
                    pending = look
                }
            }
        } else if ch == '&' {
            tokens = push(tokens, new_data_token(Ampersand, start, index))
            pending = iter.next()
        } else if tex_is_letter(ch) || tex_is_digit(ch) || tex_is_operator(ch) {
            tokens = push(tokens, new_data_token(Symbol, start, index))
            pending = iter.next()
        } else {
            tokens = push(tokens, new_data_token(Illegal, start, index))
            diagnostics = push(diagnostics, new_diagnostic("tex.lex.illegal_code_point", Warning, "code point outside the TeX math subset", new_span(start, index)))
            pending = iter.next()
        }
    }
    return data_outcome_partial(tokens, diagnostics)
}
