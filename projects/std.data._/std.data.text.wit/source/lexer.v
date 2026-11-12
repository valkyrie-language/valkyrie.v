namespace std.data.text.wit;

using std.text::{Utf8ByteIndicator, byte_indicates, Utf8Builder};

⍝ ── 词法合同 ────────────────────────────────────────────────────
⍝ 单一前向游标：`WitLexCursor` 是扫描位置的唯一所有者。
⍝   - `pending` 是唯一前看槽，持有“下一个未消费码点”；peek 只读，不动游标。
⍝   - `advance` 是唯一消费路径：取走 `pending`、推进码点位置与行列、
⍝     并从底层 `byte_indicates` 线性迭代器（均摊 O(1)/码点）补满 `pending`。
⍝   - 状态转移规则：peek 到的字符要么留在 `pending`（未消费，交下一轮处理），
⍝     要么随当前词素被 `advance` 消费——二者必居其一，不存在第三份游标状态。
⍝ 位置单位：token span 与 line/column 一律为码点口径（与 `slice` 同源）；
⍝ 字节偏移只在迭代器内部推进，绝不进入 token。
⍝ 词素文本：连续无转义词素（注释、标识符、关键字、类型名、数字、标点、包引用）
⍝ 直接 `slice` 引用源区间；字符串字面量含转义解码，用 `Utf8Builder` 构造。

micro is_wit_keyword(word: utf8) -> bool {
    return word == "interface" || word == "world" || word == "record" || word == "variant"
        || word == "enum" || word == "flags" || word == "use" || word == "type"
        || word == "resource" || word == "func" || word == "import" || word == "export"
        || word == "include" || word == "default" || word == "static" || word == "constructor"
        || word == "with" || word == "as"
}

micro is_wit_type_name(word: utf8) -> bool {
    return word == "u8" || word == "u16" || word == "u32" || word == "u64"
        || word == "s8" || word == "s16" || word == "s32" || word == "s64"
        || word == "float32" || word == "float64" || word == "char" || word == "bool"
        || word == "string" || word == "list" || word == "option" || word == "result"
        || word == "tuple" || word == "future" || word == "stream"
}

structure WitLexCursor {
    iter: Utf8ByteIndicator
    pending: Option<(usize, char)>
    position: usize
    line: usize
    column: usize
}

micro wit_lex_cursor_new(source: utf8) -> WitLexCursor {
    let mut iter: Utf8ByteIndicator = byte_indicates(source)
    let first: Option<(usize, char)> = iter.next()
    return WitLexCursor {
        iter: iter,
        pending: first,
        position: 0,
        line: 1,
        column: 1
    }
}

imply WitLexCursor {
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

    micro peek_is_identifier_part(self) -> bool {
        return self.pending.is_some() && is_wit_identifier_part(self.pending.unwrap().1)
    }

    ⍝ 唯一消费路径：取走 `pending` 中的码点，推进码点位置与行列，再补满前看槽。
    micro advance(mut self) -> char {
        let ch: char = self.pending.unwrap().1
        self.pending = self.iter.next()
        self.position = self.position + 1
        if ch == '\n' {
            self.line = self.line + 1
            self.column = 0
        }

        self.column = self.column + 1
        return ch
    }

    ⍝ 字符串字面量：当前 `pending` 必须是开引号。转义解码后内容以 `Utf8Builder`
    ⍝ 构造；缺结束引号或转义缺后续字符都结构化失败，不产出截断词素。
    micro lex_string(mut self, start: usize) -> WitParseResult<utf8> {
        self.advance()
        let mut builder: Utf8Builder = Utf8Builder::new(8)
        while !self.at_end() {
            let c: char = self.advance()
            if c == '''"''' {
                return Fine(builder.build())
            }

            if c == '\\' {
                if self.at_end() {
                    return Fail(new_wit_diagnostic("字符串转义缺少后续字符", start, self.position))
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

        return Fail(new_wit_diagnostic("字符串缺少结束引号", start, self.position))
    }
}

micro lex_wit(source: utf8) -> WitParseResult<[WitToken]> {
    let mut tokens: [WitToken] = []
    let mut cursor: WitLexCursor = wit_lex_cursor_new(source)

    while !cursor.at_end() {
        let start: usize = cursor.position
        let start_line: usize = cursor.line
        let start_col: usize = cursor.column
        let ch: char = cursor.peek().unwrap()

        if is_wit_whitespace(ch) {
            cursor.advance()
            continue
        }

        if ch == '/' && cursor.peek_is('/') {
            cursor.advance()
            cursor.advance()
            while !cursor.at_end() && !cursor.peek_is('\n') {
                cursor.advance()
            }
            # 终止换行留在 `pending`（未消费），由下一轮按空白处理。
            push(tokens, new_wit_token(Comment(source.slice(start, cursor.position - start)), start, cursor.position, start_line, start_col))
            continue
        }

        if ch == '/' && cursor.peek_is('*') {
            cursor.advance()
            cursor.advance()
            let mut terminated: bool = false
            while !cursor.at_end() {
                if cursor.peek_is('*') {
                    cursor.advance()
                    if cursor.peek_is('/') {
                        cursor.advance()
                        terminated = true
                        break
                    }
                } else {
                    cursor.advance()
                }
            }
            if !terminated {
                return Fail(new_wit_diagnostic("块注释缺少结束符 */", start, cursor.position))
            }
            push(tokens, new_wit_token(Comment(source.slice(start, cursor.position - start)), start, cursor.position, start_line, start_col))
            continue
        }

        if ch == '''"''' {
            match cursor.lex_string(start) {
                case Fine(text):
                    push(tokens, new_wit_token(String(text), start, cursor.position, start_line, start_col))
                    continue
                case Fail(error):
                    return Fail(error)
            }
        }

        if ch == '-' && cursor.peek_is('>') {
            cursor.advance()
            cursor.advance()
            push(tokens, new_wit_token(Punctuation("->"), start, cursor.position, start_line, start_col))
            continue
        }

        if ch == ':' && cursor.peek_is(':') {
            cursor.advance()
            cursor.advance()
            push(tokens, new_wit_token(Punctuation("::"), start, cursor.position, start_line, start_col))
            continue
        }

        if ch == '%' {
            cursor.advance()
            while !cursor.at_end() && (is_wit_letter_or_digit(cursor.peek().unwrap()) || cursor.peek_is('-') || cursor.peek_is(':')) {
                cursor.advance()
            }
            if cursor.position - start <= 1 {
                return Fail(new_wit_diagnostic("包引用缺少主体", start, cursor.position))
            }
            # 包引用主体不含 `%`  sigil，但 span 从 sigil 起算。
            push(tokens, new_wit_token(PackageRef(source.slice(start + 1, cursor.position - start - 1)), start, cursor.position, start_line, start_col))
            continue
        }

        if ch == '{' || ch == '}' || ch == '(' || ch == ')' || ch == ';'
            || ch == ',' || ch == ':' || ch == '=' || ch == '<' || ch == '>'
            || ch == '*' || (ch == '_' && !cursor.peek_is_identifier_part()) {
            cursor.advance()
            push(tokens, new_wit_token(Punctuation(source.slice(start, cursor.position - start)), start, cursor.position, start_line, start_col))
            continue
        }

        if is_wit_digit(ch) {
            cursor.advance()
            while !cursor.at_end() && (is_wit_digit(cursor.peek().unwrap()) || cursor.peek_is('_')) {
                cursor.advance()
            }
            push(tokens, new_wit_token(Number(source.slice(start, cursor.position - start)), start, cursor.position, start_line, start_col))
            continue
        }

        if is_wit_letter(ch) || ch == '_' || ch == '-' {
            cursor.advance()
            while !cursor.at_end() && is_wit_identifier_part(cursor.peek().unwrap()) {
                cursor.advance()
            }
            let text: utf8 = source.slice(start, cursor.position - start)
            if is_wit_keyword(text) {
                push(tokens, new_wit_token(Keyword(text), start, cursor.position, start_line, start_col))
            } else if is_wit_type_name(text) {
                push(tokens, new_wit_token(TypeName(text), start, cursor.position, start_line, start_col))
            } else {
                push(tokens, new_wit_token(Identifier(text), start, cursor.position, start_line, start_col))
            }
            continue
        }

        return Fail(new_wit_diagnostic("存在无法识别的 WIT 字符", start, start + 1))
    }

    push(tokens, eof_wit_token(cursor.position, cursor.line, cursor.column))
    return Fine(tokens)
}

micro is_wit_whitespace(ch: char) -> bool {
    return ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n'
}

micro is_wit_digit(ch: char) -> bool {
    return ch >= '0' && ch <= '9'
}

micro is_wit_letter(ch: char) -> bool {
    return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
}

micro is_wit_letter_or_digit(ch: char) -> bool {
    return is_wit_letter(ch) || is_wit_digit(ch)
}

micro is_wit_identifier_part(ch: char) -> bool {
    return is_wit_letter_or_digit(ch) || ch == '-' || ch == '_' || ch == '/'
}
