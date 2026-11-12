namespace std.data.text.mermaid;

using std.data::{DataOutcome, DataSource, DataSettings, DataToken, data_outcome_failed, data_outcome_partial, new_data_token};
using std.diagnostic::{Diagnostic, Error, Warning, new_diagnostic, new_span};
using std.text::{Utf8ByteIndicator, byte_indicates};

# 词法段：源文本 -> token 流。`\r\n` 合并为单个 `Newline`。
# `-` 系：`-->` 为 `Arrow`，`->>` 为 `SeqArrow`；其余 `-`/`>` 形态产 `Illegal`
# 并登记 `mermaid.lex.malformed_arrow`（Warning）后继续。

micro mermaid_lex(source: DataSource, settings: DataSettings) -> DataOutcome<[DataToken<MermaidTokenKind>]> {
    match source {
        case Text(payload):
            return mermaid_scan(payload.text)
        case Bytes(payload):
            return data_outcome_failed([new_diagnostic("mermaid.lex.binary_source", Error, "binary source is not mermaid input", new_span(0, 0))])
    }
}

micro mermaid_lex_text(text: utf8) -> DataOutcome<[DataToken<MermaidTokenKind>]> {
    return mermaid_scan(text)
}

micro mermaid_is_text_char(ch: char) -> bool {
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
        return false
    }
    if ch == '-' || ch == '>' || ch == '<' || ch == '|' || ch == '[' || ch == ']' || ch == ':' || ch == '%' || ch == '(' || ch == ')' || ch == '{' || ch == '}' {
        return false
    }
    return true
}

micro mermaid_scan(text: utf8) -> DataOutcome<[DataToken<MermaidTokenKind>]> {
    let mut tokens: [DataToken<MermaidTokenKind>] = []
    let mut diagnostics: [Diagnostic] = []
    let mut iter: Utf8ByteIndicator = byte_indicates(text)
    let mut index: usize = 0
    let mut pending: Option<(usize, char)> = iter.next()
    while pending.is_some() {
        let ch: char = pending.unwrap().1
        let start: usize = index
        index = index + 1
        if ch == '\n' || ch == '\r' {
            let look: Option<(usize, char)> = iter.next()
            if ch == '\r' && look.is_some() && look.unwrap().1 == '\n' {
                index = index + 1
                pending = iter.next()
            } else {
                pending = look
            }
            tokens = push(tokens, new_data_token(Newline, start, index))
        } else if ch == ' ' || ch == '\t' {
            let mut look: Option<(usize, char)> = iter.next()
            while look.is_some() && (look.unwrap().1 == ' ' || look.unwrap().1 == '\t') {
                index = index + 1
                look = iter.next()
            }
            pending = look
            tokens = push(tokens, new_data_token(Space, start, index))
        } else if ch == '<' {
            let first: Option<(usize, char)> = iter.next()
            if first.is_some() && first.unwrap().1 == '-' {
                index = index + 1
                let second: Option<(usize, char)> = iter.next()
                if second.is_some() && second.unwrap().1 == '-' {
                    index = index + 1
                    let third: Option<(usize, char)> = iter.next()
                    if third.is_some() && third.unwrap().1 == '-' {
                        index = index + 1
                        let fourth: Option<(usize, char)> = iter.next()
                        if fourth.is_some() && fourth.unwrap().1 == '>' {
                            index = index + 1
                            tokens = push(tokens, new_data_token(BiArrow, start, index))
                            pending = iter.next()
                        } else {
                            tokens = push(tokens, new_data_token(Illegal, start, index))
                            diagnostics = push(diagnostics, new_diagnostic("mermaid.lex.malformed_arrow", Warning, "bidirectional arrow misses its head", new_span(start, index)))
                            pending = fourth
                        }
                    } else {
                        tokens = push(tokens, new_data_token(Illegal, start, index))
                        diagnostics = push(diagnostics, new_diagnostic("mermaid.lex.malformed_arrow", Warning, "bidirectional arrow misses its head", new_span(start, index)))
                        pending = third
                    }
                } else {
                    tokens = push(tokens, new_data_token(Illegal, start, index))
                    diagnostics = push(diagnostics, new_diagnostic("mermaid.lex.malformed_arrow", Warning, "bidirectional arrow misses its body", new_span(start, index)))
                    pending = second
                }
            } else {
                tokens = push(tokens, new_data_token(Illegal, start, index))
                diagnostics = push(diagnostics, new_diagnostic("mermaid.lex.malformed_arrow", Warning, "lone angle bracket", new_span(start, index)))
                pending = first
            }
        } else if ch == '-' {
            let first: Option<(usize, char)> = iter.next()
            if first.is_some() && first.unwrap().1 == '-' {
                index = index + 1
                let second: Option<(usize, char)> = iter.next()
                if second.is_some() && second.unwrap().1 == '>' {
                    index = index + 1
                    tokens = push(tokens, new_data_token(Arrow, start, index))
                    pending = iter.next()
                } else {
                    tokens = push(tokens, new_data_token(Illegal, start, index))
                    diagnostics = push(diagnostics, new_diagnostic("mermaid.lex.malformed_arrow", Warning, "dash run without its arrow head", new_span(start, index)))
                    pending = second
                }
            } else if first.is_some() && first.unwrap().1 == '>' {
                index = index + 1
                let second: Option<(usize, char)> = iter.next()
                if second.is_some() && second.unwrap().1 == '>' {
                    index = index + 1
                    tokens = push(tokens, new_data_token(SeqArrow, start, index))
                    pending = iter.next()
                } else {
                    tokens = push(tokens, new_data_token(Illegal, start, index))
                    diagnostics = push(diagnostics, new_diagnostic("mermaid.lex.malformed_arrow", Warning, "sequence arrow misses its second head", new_span(start, index)))
                    pending = second
                }
            } else {
                tokens = push(tokens, new_data_token(Illegal, start, index))
                diagnostics = push(diagnostics, new_diagnostic("mermaid.lex.malformed_arrow", Warning, "lone dash outside an arrow", new_span(start, index)))
                pending = first
            }
        } else if ch == '>' {
            tokens = push(tokens, new_data_token(Illegal, start, index))
            diagnostics = push(diagnostics, new_diagnostic("mermaid.lex.malformed_arrow", Warning, "lone arrow head", new_span(start, index)))
            pending = iter.next()
        } else if ch == '|' {
            tokens = push(tokens, new_data_token(Pipe, start, index))
            pending = iter.next()
        } else if ch == '[' {
            tokens = push(tokens, new_data_token(LBracket, start, index))
            pending = iter.next()
        } else if ch == ']' {
            tokens = push(tokens, new_data_token(RBracket, start, index))
            pending = iter.next()
        } else if ch == '(' {
            tokens = push(tokens, new_data_token(LParen, start, index))
            pending = iter.next()
        } else if ch == ')' {
            tokens = push(tokens, new_data_token(RParen, start, index))
            pending = iter.next()
        } else if ch == '{' {
            tokens = push(tokens, new_data_token(LBrace, start, index))
            pending = iter.next()
        } else if ch == '}' {
            tokens = push(tokens, new_data_token(RBrace, start, index))
            pending = iter.next()
        } else if ch == ':' {
            tokens = push(tokens, new_data_token(Colon, start, index))
            pending = iter.next()
        } else if ch == '%' {
            tokens = push(tokens, new_data_token(Percent, start, index))
            pending = iter.next()
        } else {
            let mut look: Option<(usize, char)> = iter.next()
            while look.is_some() && mermaid_is_text_char(look.unwrap().1) {
                index = index + 1
                look = iter.next()
            }
            pending = look
            tokens = push(tokens, new_data_token(Text, start, index))
        }
    }
    return data_outcome_partial(tokens, diagnostics)
}
