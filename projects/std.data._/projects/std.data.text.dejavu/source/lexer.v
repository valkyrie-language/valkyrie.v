namespace std.data.text.dejavu;

using std.diagnostic::{Diagnostic, Error, Severity, Span, Warning, new_diagnostic, new_span};
using std.data::{DataOutcome, DataSource, DataToken, data_outcome_partial, new_data_token};

# 词法段：模板源文本 -> token 流。
#
# 错误容许：非法码位产 `Illegal` token 并继续扫描，登记 `template.lex.illegal_code_point`；
# 单独的 `|` 不是管道，产 `Illegal` 并登记 `template.lex.single_pipe`；
# 注释未闭合产到源末尾的 `Comment` token 并登记 `template.lex.unclosed_comment`（Error）；
# 字符串未闭合产到区间末尾的 `String` token 并登记 `template.lex.unclosed_string`（Warning）；
# 代码标签未闭合不在词法段报告（结构恢复归 parser 的 Missing 占位）。
# 二进制源不是模板输入形态，登记 `template.lex.binary_source`（Error）并产空流。
#
# 字符比较一律用字符字面量；仅 Unicode 码点表（无字面量拼写的非 ASCII 段）保留数值范围。

micro template_is_code_open_at(text: utf8, index: usize) -> bool {
    let length: usize = text.length()
    if index + 1 >= length {
        return false
    }
    return text⁅index⁆ == '<' && text⁅index + 1⁆ == '%'
}

# `<%!` 转义形式。
micro template_is_code_escape_at(text: utf8, index: usize) -> bool {
    let length: usize = text.length()
    if index + 2 >= length {
        return false
    }
    return text⁅index⁆ == '<' && text⁅index + 1⁆ == '%' && text⁅index + 2⁆ == '!'
}

# 注释开 `<#`。
micro template_is_comment_open_at(text: utf8, index: usize) -> bool {
    let length: usize = text.length()
    if index + 1 >= length {
        return false
    }
    return text⁅index⁆ == '<' && text⁅index + 1⁆ == '#'
}

# trim marker 字符 → 级别。
micro template_trim_at(text: utf8, index: usize) -> TemplateTrim {
    let length: usize = text.length()
    if index >= length {
        return TrimNone
    }
    let marker: char = text⁅index⁆
    if marker == '_' {
        return TrimWhitespace
    }
    if marker == '-' {
        return TrimNewline
    }
    if marker == '~' {
        return TrimWhitespaceNewline
    }
    if marker == '=' {
        return TrimAll
    }
    return TrimNone
}

micro template_is_horizontal_whitespace(c: char) -> bool {
    return c == ' ' || c == '\t'
}

# Unicode 空白：ASCII 段用字符比较；133/160/8192-8202/8232/8233/8239/12288 无
# 字符字面量拼写，是码点表而非字符比较，保留数值范围。
micro template_is_unicode_whitespace(c: char) -> bool {
    if c >= '\t' && c <= '\r' {
        return true
    }
    if c == ' ' {
        return true
    }
    let code_point: u32 = c as u32
    if code_point == 133 || code_point == 160 {
        return true
    }
    if code_point >= 8192 && code_point <= 8202 {
        return true
    }
    return code_point == 8232 || code_point == 8233 || code_point == 8239 || code_point == 12288
}

micro template_is_newline(c: char) -> bool {
    return c == '\r' || c == '\n'
}

# ── trim 剥离：返回剥离后的边界（leading 返回新 start，trailing 返回新 stop）──

micro template_strip_leading(text: utf8, start: usize, stop: usize, trim: TemplateTrim) -> usize {
    match trim {
        case TrimNone:
            return start
        case TrimWhitespace:
            return template_strip_horizontal_leading(text, start, stop)
        case TrimNewline:
            return template_strip_one_newline_leading(text, start, stop)
        case TrimWhitespaceNewline:
            let after_horizontal: usize = template_strip_horizontal_leading(text, start, stop)
            let after_newline: usize = template_strip_one_newline_leading(text, after_horizontal, stop)
            return template_strip_horizontal_leading(text, after_newline, stop)
        case TrimAll:
            let mut cursor: usize = start
            while cursor < stop {
                if !template_is_unicode_whitespace(text⁅cursor⁆) {
                    break
                }
                cursor = cursor + 1
            }
            return cursor
    }
}

micro template_strip_trailing(text: utf8, start: usize, stop: usize, trim: TemplateTrim) -> usize {
    match trim {
        case TrimNone:
            return stop
        case TrimWhitespace:
            return template_strip_horizontal_trailing(text, start, stop)
        case TrimNewline:
            return template_strip_one_newline_trailing(text, start, stop)
        case TrimWhitespaceNewline:
            let before_horizontal: usize = template_strip_horizontal_trailing(text, start, stop)
            let before_newline: usize = template_strip_one_newline_trailing(text, start, before_horizontal)
            return template_strip_horizontal_trailing(text, start, before_newline)
        case TrimAll:
            let mut cursor: usize = stop
            while cursor > start {
                if !template_is_unicode_whitespace(text⁅cursor - 1⁆) {
                    break
                }
                cursor = cursor - 1
            }
            return cursor
    }
}

micro template_strip_horizontal_leading(text: utf8, start: usize, stop: usize) -> usize {
    let mut cursor: usize = start
    while cursor < stop {
        if !template_is_horizontal_whitespace(text⁅cursor⁆) {
            break
        }
        cursor = cursor + 1
    }
    return cursor
}

micro template_strip_horizontal_trailing(text: utf8, start: usize, stop: usize) -> usize {
    let mut cursor: usize = stop
    while cursor > start {
        if !template_is_horizontal_whitespace(text⁅cursor - 1⁆) {
            break
        }
        cursor = cursor - 1
    }
    return cursor
}

# 恰好一个换行序列（\r\n 视为一个）；边界处无换行则不剥离。
micro template_strip_one_newline_leading(text: utf8, start: usize, stop: usize) -> usize {
    if start >= stop {
        return start
    }
    if text⁅start⁆ == '\r' {
        if start + 1 < stop && text⁅start + 1⁆ == '\n' {
            return start + 2
        }
        return start + 1
    }
    if text⁅start⁆ == '\n' {
        return start + 1
    }
    return start
}

micro template_strip_one_newline_trailing(text: utf8, start: usize, stop: usize) -> usize {
    if stop <= start {
        return stop
    }
    if text⁅stop - 1⁆ == '\n' {
        if stop - 1 > start && text⁅stop - 2⁆ == '\r' {
            return stop - 2
        }
        return stop - 1
    }
    if text⁅stop - 1⁆ == '\r' {
        return stop - 1
    }
    return stop
}

# 字符串闭引号位置：从 `quote_start + 1` 起扫描，反斜杠转义只参与闭引号匹配。
# 找到返回闭引号下标；未找到返回 `limit`（哨兵，调用点按 `>= limit` 判未闭合）。
micro template_string_close_at(text: utf8, quote_start: usize, limit: usize) -> usize {
    let quote: char = text⁅quote_start⁆
    let mut cursor: usize = quote_start + 1
    while cursor < limit {
        let c: char = text⁅cursor⁆
        if c == r'\' {
            cursor = cursor + 2
            continue
        }
        if c == quote {
            return cursor
        }
        cursor = cursor + 1
    }
    return limit
}

# ── 词法器状态 ──

class TemplateLexer {
    _text: utf8
    _length: usize
    _cursor: usize
    _text_start: usize
    _pending_trim: TemplateTrim
    _tokens: [DataToken<TemplateTokenKind>]
    _diagnostics: [Diagnostic]
}

imply TemplateLexer {
    micro new(text: utf8) -> Self {
        return TemplateLexer {
            _text: text,
            _length: text.length(),
            _cursor: 0,
            _text_start: 0,
            _pending_trim: TrimNone,
            _tokens: [],
            _diagnostics: []
        }
    }

    micro char_at(self, index: usize) -> char {
        return self._text⁅index⁆
    }

    micro tokens(self) -> [DataToken<TemplateTokenKind>] {
        return self._tokens
    }

    micro diagnostics(self) -> [Diagnostic] {
        return self._diagnostics
    }

    micro emit(mut self, kind: TemplateTokenKind, start: usize, stop: usize) -> unit {
        self._tokens = push(self._tokens, new_data_token(kind, start, stop))
    }

    micro diagnose(mut self, code: utf8, severity: Severity, message: utf8, start: usize, stop: usize) -> unit {
        self._diagnostics = push(self._diagnostics, new_diagnostic(code, severity, message, new_span(start, stop)))
    }

    # 冲刷 [self._text_start, stop) 的文本：头部应用上一标签的右 marker，
    # 尾部应用本标签的左 marker；剥离段以 Trimmed token 保留（无损覆盖）。
    micro flush_text(mut self, stop: usize, right_trim: TemplateTrim) -> unit {
        let start: usize = self._text_start
        if stop <= start {
            return
        }
        let head_stop: usize = template_strip_leading(self._text, start, stop, self._pending_trim)
        let tail_start: usize = template_strip_trailing(self._text, head_stop, stop, right_trim)
        if head_stop > start {
            self.emit(Trimmed, start, head_stop)
        }
        if tail_start > head_stop {
            self.emit(Text, head_stop, tail_start)
        }
        if stop > tail_start {
            self.emit(Trimmed, tail_start, stop)
        }
    }

    micro scan(mut self) -> unit {
        while self._cursor < self._length {
            if template_is_code_escape_at(self._text, self._cursor) {
                self.flush_text(self._cursor, TrimNone)
                self.emit(CodeEscape, self._cursor, self._cursor + 3)
                self._cursor = self._cursor + 3
                self._text_start = self._cursor
                self._pending_trim = TrimNone
                continue
            }
            if template_is_code_open_at(self._text, self._cursor) {
                self.scan_code_tag()
                continue
            }
            if template_is_comment_open_at(self._text, self._cursor) {
                self.scan_comment()
                continue
            }
            self._cursor = self._cursor + 1
        }
        self.flush_text(self._length, TrimNone)
    }

    # 注释 `<# ... #>`：单 token 覆盖整个注释（含定界符），渲染忽略。
    # 注释定界的 trim marker 当前不支持。
    micro scan_comment(mut self) -> unit {
        self.flush_text(self._cursor, TrimNone)
        let start: usize = self._cursor
        let mut cursor: usize = start + 2
        let mut closed: bool = false
        while cursor < self._length {
            if self.char_at(cursor) == '#' && cursor + 1 < self._length && self.char_at(cursor + 1) == '>' {
                cursor = cursor + 2
                closed = true
                break
            }
            cursor = cursor + 1
        }
        self.emit(Comment, start, cursor)
        if !closed {
            self.diagnose("template.lex.unclosed_comment", Error, "注释定界 `<#` 未闭合", start, cursor)
        }
        self._cursor = cursor
        self._text_start = cursor
        self._pending_trim = TrimNone
    }

    # 代码标签 `<% ... %>`：先按字符串感知找闭标，再切左右 marker，最后词法化内部。
    micro scan_code_tag(mut self) -> unit {
        let open_start: usize = self._cursor
        let left_trim: TemplateTrim = template_trim_at(self._text, open_start + 2)
        let mut content_start: usize = open_start + 2
        match left_trim {
            case TrimNone:
                content_start = open_start + 2
            else:
                content_start = open_start + 3
        }
        self.flush_text(open_start, left_trim)
        self.emit(CodeOpen { trim: left_trim }, open_start, content_start)

        # 字符串感知地寻找 `%>`：字符串内的 `%>` 不闭合标签。
        let mut cursor: usize = content_start
        let mut close_at: usize = self._length
        let mut found: bool = false
        while cursor < self._length {
            let c: char = self.char_at(cursor)
            if c == '"' || c == "'" {
                let quote_close: usize = template_string_close_at(self._text, cursor, self._length)
                if quote_close >= self._length {
                    cursor = self._length
                    break
                }
                cursor = quote_close + 1
                continue
            }
            if c == '%' && cursor + 1 < self._length && self.char_at(cursor + 1) == '>' {
                close_at = cursor
                found = true
                break
            }
            cursor = cursor + 1
        }

        let mut interior_stop: usize = close_at
        let mut right_trim: TemplateTrim = TrimNone
        let mut close_start: usize = close_at
        if found && close_at > content_start {
            let candidate: TemplateTrim = template_trim_at(self._text, close_at - 1)
            match candidate {
                case TrimNone:
                    right_trim = TrimNone
                else:
                    right_trim = candidate
                    interior_stop = close_at - 1
                    close_start = close_at - 1
            }
        }

        self.lex_interior(content_start, interior_stop)
        if found {
            self.emit(CodeClose { trim: right_trim }, close_start, close_at + 2)
            self._cursor = close_at + 2
        }
        else {
            self._cursor = self._length
        }
        self._text_start = self._cursor
        self._pending_trim = right_trim
    }

    # 代码内部词法化：[start, stop) 区间内的 token；span 均为源内绝对码点偏移。
    micro lex_interior(mut self, start: usize, stop: usize) -> unit {
        let mut cursor: usize = start
        while cursor < stop {
            let c: char = self.char_at(cursor)
            if template_is_horizontal_whitespace(c) || template_is_newline(c) {
                let run_start: usize = cursor
                while cursor < stop {
                    let current: char = self.char_at(cursor)
                    if !template_is_horizontal_whitespace(current) && !template_is_newline(current) {
                        break
                    }
                    cursor = cursor + 1
                }
                self.emit(CodeWhitespace, run_start, cursor)
                continue
            }
            if c == '"' || c == "'" {
                let quote_close: usize = template_string_close_at(self._text, cursor, stop)
                if quote_close >= stop {
                    self.emit(String, cursor, stop)
                    self.diagnose("template.lex.unclosed_string", Warning, "字符串字面量未闭合", cursor, stop)
                    cursor = stop
                    continue
                }
                self.emit(String, cursor, quote_close + 1)
                cursor = quote_close + 1
                continue
            }
            # 数字：十进制整数，可选 `.` 后至少一位的小数。
            if c >= '0' && c <= '9' {
                let number_start: usize = cursor
                while cursor < stop {
                    let current: char = self.char_at(cursor)
                    if current < '0' || current > '9' {
                        break
                    }
                    cursor = cursor + 1
                }
                if cursor + 1 < stop && self.char_at(cursor) == '.' {
                    let after_dot: char = self.char_at(cursor + 1)
                    if after_dot >= '0' && after_dot <= '9' {
                        cursor = cursor + 1
                        while cursor < stop {
                            let current: char = self.char_at(cursor)
                            if current < '0' || current > '9' {
                                break
                            }
                            cursor = cursor + 1
                        }
                    }
                }
                self.emit(Number, number_start, cursor)
                continue
            }
            # 标识符/关键字：[a-zA-Z_][a-zA-Z0-9_]*。
            if template_is_identifier_start(c) {
                let word_start: usize = cursor
                while cursor < stop {
                    let current: char = self.char_at(cursor)
                    if !template_is_identifier_continue(current) {
                        break
                    }
                    cursor = cursor + 1
                }
                self.emit(template_keyword_kind(self._text, word_start, cursor), word_start, cursor)
                continue
            }
            # 双字符运算符优先：|>、||、&&、==、!=、<=、>=。
            if cursor + 1 < stop {
                let next: char = self.char_at(cursor + 1)
                if c == '|' && next == '>' {
                    self.emit(Pipe, cursor, cursor + 2)
                    cursor = cursor + 2
                    continue
                }
                if c == '|' && next == '|' {
                    self.emit(Or, cursor, cursor + 2)
                    cursor = cursor + 2
                    continue
                }
                if c == '&' && next == '&' {
                    self.emit(And, cursor, cursor + 2)
                    cursor = cursor + 2
                    continue
                }
                if c == '=' && next == '=' {
                    self.emit(EqualEqual, cursor, cursor + 2)
                    cursor = cursor + 2
                    continue
                }
                if c == '!' && next == '=' {
                    self.emit(BangEqual, cursor, cursor + 2)
                    cursor = cursor + 2
                    continue
                }
                if c == '<' && next == '=' {
                    self.emit(LessEqual, cursor, cursor + 2)
                    cursor = cursor + 2
                    continue
                }
                if c == '>' && next == '=' {
                    self.emit(GreaterEqual, cursor, cursor + 2)
                    cursor = cursor + 2
                    continue
                }
            }
            # 单字符运算符与标点。
            let single: TemplateTokenKind = template_single_operator_kind(c)
            match single {
                case Illegal:
                    if c == '|' {
                        self.diagnose("template.lex.single_pipe", Warning, "单独的 `|` 不是管道，管道写作 `|>`", cursor, cursor + 1)
                    }
                    else {
                        self.diagnose("template.lex.illegal_code_point", Warning, "代码区内无法识别的码位", cursor, cursor + 1)
                    }
                    self.emit(Illegal, cursor, cursor + 1)
                    cursor = cursor + 1
                else:
                    self.emit(single, cursor, cursor + 1)
                    cursor = cursor + 1
            }
        }
    }
}

# 标识符起止字符判定。
micro template_is_identifier_start(c: char) -> bool {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

micro template_is_identifier_continue(c: char) -> bool {
    return template_is_identifier_start(c) || (c >= '0' && c <= '9')
}

# 单字符运算符分派。`|` 与不可识别码位都归 Illegal（诊断在调用点区分）。
micro template_single_operator_kind(c: char) -> TemplateTokenKind {
    if c == '<' {
        return Less
    }
    if c == '>' {
        return Greater
    }
    if c == '+' {
        return Plus
    }
    if c == '-' {
        return Minus
    }
    if c == '*' {
        return Star
    }
    if c == '/' {
        return Slash
    }
    if c == '%' {
        return Percent
    }
    if c == '!' {
        return Bang
    }
    if c == '.' {
        return Dot
    }
    if c == ',' {
        return Comma
    }
    if c == '=' {
        return Assign
    }
    if c == '(' {
        return ParenOpen
    }
    if c == ')' {
        return ParenClose
    }
    if c == '[' {
        return BracketOpen
    }
    if c == ']' {
        return BracketClose
    }
    if c == '{' {
        return BraceOpen
    }
    if c == '}' {
        return BraceClose
    }
    if c == ':' {
        return Colon
    }
    return Illegal
}

# 关键字分派：按 span 从源切回词素比对。词素比对是词法事实（语句关键字的
# 上下文分类在 parser 按 token 类完成，不需要源文本）。
micro template_keyword_kind(text: utf8, start: usize, stop: usize) -> TemplateTokenKind {
    let word: utf8 = text.slice(start, stop - start)
    if word == "true" {
        return LiteralTrue
    }
    if word == "false" {
        return LiteralFalse
    }
    if word == "null" {
        return LiteralNull
    }
    if word == "if" {
        return KeywordIf
    }
    if word == "else" {
        return KeywordElse
    }
    if word == "end" {
        return KeywordEnd
    }
    if word == "loop" {
        return KeywordLoop
    }
    if word == "in" {
        return KeywordIn
    }
    if word == "break" {
        return KeywordBreak
    }
    if word == "continue" {
        return KeywordContinue
    }
    if word == "is" {
        return KeywordIs
    }
    if word == "not" {
        return KeywordNot
    }
    if word == "extends" {
        return KeywordExtends
    }
    if word == "block" {
        return KeywordBlock
    }
    if word == "super" {
        return KeywordSuper
    }
    if word == "include" {
        return KeywordInclude
    }
    if word == "with" {
        return KeywordWith
    }
    if word == "only" {
        return KeywordOnly
    }
    if word == "without" {
        return KeywordWithout
    }
    if word == "context" {
        return KeywordContext
    }
    if word == "partial" {
        return KeywordPartial
    }
    if word == "macro" {
        return KeywordMacro
    }
    if word == "call" {
        return KeywordCall
    }
    if word == "from" {
        return KeywordFrom
    }
    if word == "import" {
        return KeywordImport
    }
    if word == "as" {
        return KeywordAs
    }
    return Identifier
}

# 三段合同入口：词法段。二进制源不是模板输入形态，结构化诊断并产空流。
micro template_lex(source: DataSource, settings: DataSettings) -> DataOutcome<[DataToken<TemplateTokenKind>]> {
    match source {
        case Text(payload):
            return template_lex_text(payload.text)
        case Bytes(payload):
            let mut diagnostics: [Diagnostic] = []
            diagnostics = push(diagnostics, new_diagnostic("template.lex.binary_source", Error, "模板是文本格式，不接受字节源", new_span(0, 0)))
            let empty: [DataToken<TemplateTokenKind>] = []
            return data_outcome_partial(empty, diagnostics)
    }
}

# 文本词法入口（段内实现；`settings` 当前无词法字段消费，保留合同形状）。
micro template_lex_text(text: utf8) -> DataOutcome<[DataToken<TemplateTokenKind>]> {
    let mut lexer: TemplateLexer = TemplateLexer::new(text)
    lexer.scan()
    return data_outcome_partial(lexer.tokens(), lexer.diagnostics())
}
