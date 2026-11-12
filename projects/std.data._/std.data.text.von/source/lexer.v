namespace std.data.text.von;

using std.text::{Utf8ByteIndicator, byte_indicates, Utf8Builder};

⍝ ── 词法合同 ────────────────────────────────────────────────────
⍝ 单一前向游标：`VonLexCursor` 是扫描位置的唯一所有者。
⍝   - `pending` 是唯一前看槽，持有“下一个未消费码点”；peek 只读，不动游标。
⍝   - `advance` 是唯一消费路径：取走 `pending`、推进码点位置，并从底层
⍝     `byte_indicates` 线性迭代器（均摊 O(1)/码点）补满 `pending`。
⍝   - 状态转移规则：peek 到的字符要么留在 `pending`（未消费，交下一轮处理），
⍝     要么随当前词素被 `advance` 消费——二者必居其一，不存在第三份游标状态。
⍝ 位置单位：token span 一律为码点口径（与 `slice` 同源）；字节偏移只在迭代器
⍝ 内部推进，绝不进入 token。
⍝ 词素文本：标识符/数字直接 `slice` 引用源区间；字符串字面量含转义解码，
⍝ 用 `Utf8Builder` 构造。

micro is_von_whitespace(ch: char) -> bool {
    return ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n'
}

micro is_von_digit(ch: char) -> bool {
    let code: u32 = ch as u32
    return code >= 48 && code <= 57
}

micro is_von_identifier_start(ch: char) -> bool {
    let code: u32 = ch as u32
    return (code >= 97 && code <= 122)
        || (code >= 65 && code <= 90)
        || ch == '_'
}

micro is_von_identifier_continue(ch: char) -> bool {
    return is_von_identifier_start(ch)
        || is_von_digit(ch)
        || ch == '.'
        || ch == '-'
}

structure VonLexCursor {
    iter: Utf8ByteIndicator
    pending: Option<(usize, char)>
    position: usize
}

micro von_lex_cursor_new(source: utf8) -> VonLexCursor {
    let mut iter: Utf8ByteIndicator = byte_indicates(source)
    let first: Option<(usize, char)> = iter.next()
    return VonLexCursor {
        iter: iter,
        pending: first,
        position: 0
    }
}

imply VonLexCursor {
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

    ⍝ 唯一消费路径：取走 `pending` 中的码点，推进码点位置，再补满前看槽。
    micro advance(mut self) -> char {
        let ch: char = self.pending.unwrap().1
        self.pending = self.iter.next()
        self.position = self.position + 1
        return ch
    }

    ⍝ 字符串字面量：当前 `pending` 必须是开引号。转义解码后的内容以
    ⍝ `Utf8Builder` 构造；缺结束引号或转义缺后续字符都结构化失败。
    micro lex_string(mut self, start: usize) -> VonParseResult<utf8> {
        self.advance()
        let mut builder: Utf8Builder = Utf8Builder::new(8)
        while !self.at_end() {
            let c: char = self.advance()
            if c == '''"''' {
                return Fine(builder.build())
            }

            if c == '\\' {
                if self.at_end() {
                    return Fail(new_von_diagnostic("字符串转义缺少后续字符", start, self.position))
                }

                let esc: char = self.advance()
                if esc == 'n' {
                    builder.append('\n')
                } else if esc == 'r' {
                    builder.append('\r')
                } else if esc == 't' {
                    builder.append('\t')
                } else {
                    builder.append(esc)
                }
            } else {
                builder.append(c)
            }
        }

        return Fail(new_von_diagnostic("字符串缺少结束引号", start, self.position))
    }
}

micro lex_von(source: utf8) -> VonParseResult<[VonToken]> {
    let mut tokens: [VonToken] = []
    let mut cursor: VonLexCursor = von_lex_cursor_new(source)

    while !cursor.at_end() {
        let start: usize = cursor.position
        let ch: char = cursor.peek().unwrap()

        if is_von_whitespace(ch) {
            cursor.advance()
            continue
        }

        if ch == '#' {
            cursor.advance()
            while !cursor.at_end() && !cursor.peek_is('\n') {
                cursor.advance()
            }
            # 终止换行留在 `pending`（未消费），由下一轮按空白处理；注释是 trivia，不产 token。
            continue
        }

        if ch == '{' {
            cursor.advance()
            push(tokens, new_von_marker_token(LeftBrace, start, cursor.position))
            continue
        }

        if ch == '}' {
            cursor.advance()
            push(tokens, new_von_marker_token(RightBrace, start, cursor.position))
            continue
        }

        if ch == '[' {
            cursor.advance()
            push(tokens, new_von_marker_token(LeftBracket, start, cursor.position))
            continue
        }

        if ch == ']' {
            cursor.advance()
            push(tokens, new_von_marker_token(RightBracket, start, cursor.position))
            continue
        }

        if ch == ':' {
            cursor.advance()
            push(tokens, new_von_marker_token(Colon, start, cursor.position))
            continue
        }

        if ch == ',' {
            cursor.advance()
            push(tokens, new_von_marker_token(Comma, start, cursor.position))
            continue
        }

        if ch == '''"''' {
            match cursor.lex_string(start) {
                case Fine(text):
                    push(tokens, new_von_token(StringLiteral, text, start, cursor.position))
                    continue
                case Fail(error):
                    return Fail(error)
            }
        }

        if is_von_digit(ch) || ch == '-' {
            cursor.advance()
            while !cursor.at_end() && (is_von_digit(cursor.peek().unwrap()) || cursor.peek_is('-') || cursor.peek_is('.')) {
                cursor.advance()
            }
            push(tokens, new_von_token(NumberLiteral, source.slice(start, cursor.position - start), start, cursor.position))
            continue
        }

        if is_von_identifier_start(ch) {
            cursor.advance()
            while !cursor.at_end() && is_von_identifier_continue(cursor.peek().unwrap()) {
                cursor.advance()
            }
            let text: utf8 = source.slice(start, cursor.position - start)
            if text == "true" || text == "false" {
                push(tokens, new_von_token(BooleanLiteral, text, start, cursor.position))
            } else {
                push(tokens, new_von_token(Identifier, text, start, cursor.position))
            }
            continue
        }

        return Fail(new_von_diagnostic("存在无法识别的 VON 字符", start, start + 1))
    }

    push(tokens, eof_von_token(cursor.position))
    return Fine(tokens)
}
