namespace std.data.text.dejavu;

using std.diagnostic::{Diagnostic, Error, Span, new_diagnostic, new_span};
using std.data::{DataCstNode, DataOutcome, DataSettings, DataToken, data_cst_missing, data_cst_node, data_cst_poison, data_cst_span, data_cst_token, data_outcome_partial};

# 语法段：token 流 -> 无损 CST。
#
# 容器层次：Root 下为文本/注释/插值/语句子树；标签的全部 token（含定界与 trivia）
# 保留在对应容器内；表达式子树以 NodeExpression* 承载优先级结构，运算符与括号
# 以 Token 叶子挂在原位。未闭合结构以 `Missing` 占位闭合；被丢弃/越界内容挂 `Poison`
# （字节不丢）；深度超限记 `template.parse.max_depth_exceeded`（Error）并对超深子树挂 Poison。
#
# 恢复同步点：标签闭标 `%>` 与语句闭合头（else/end if/end loop 等）为安全边界。
#
# break/continue 绑定词法最近外层 loop（词法单元目前覆盖模板顶层与 loop body；
# macro/call/partial/block 属未支持表面）。越界产 `template.parse.control_outside_loop`。
# closer 标签（else/else if/end if/end loop）上的 trim marker 一律拒绝
# （`template.parse.closer_trim_marker`）。

# parse_sequence 的停止原因（closer 标签未被消费，由调用点接续）。
unite TemplateParseStop {
    StopEnd
    StopElseIf
    StopElse
    StopEndIf
    StopEndLoop
    StopEndBlock
    StopEndPartial
    StopEndMacro
    StopEndCall
    # 其他闭合形：由顶层按 `template.parse.unmatched_closer` 恢复。
    StopOther
}

structure TemplateSequence {
    children: [DataCstNode<TemplateTokenKind>]
    stop: TemplateParseStop
}

# else if / else 分支的解析产出：节点 + body 序列的停止信号。
structure TemplateBranch {
    node: DataCstNode<TemplateTokenKind>
    stop: TemplateParseStop
}

class TemplateParser {
    _tokens: [DataToken<TemplateTokenKind>]
    _cursor: usize
    _diagnostics: [Diagnostic]
    _max_depth: usize
    # 当前所处的 `block` 覆盖块深度（`super` 只允许出现在覆盖块内）。
    _block_depth: usize
}

imply TemplateParser {
    micro new(tokens: [DataToken<TemplateTokenKind>], max_depth: usize) -> Self {
        return TemplateParser {
            _tokens: tokens,
            _cursor: 0,
            _diagnostics: [],
            _max_depth: max_depth,
            _block_depth: 0
        }
    }

    micro diagnostics(self) -> [Diagnostic] {
        return self._diagnostics
    }

    micro at_end(self) -> bool {
        return self._cursor >= self._tokens.length()
    }

    # 当前 token（调用点保证 `!at_end()`）。
    micro current(self) -> DataToken<TemplateTokenKind> {
        return self._tokens⁅self._cursor⁆.unwrap()
    }

    micro current_kind(self) -> TemplateTokenKind {
        return self.current().kind
    }

    micro current_start(self) -> usize {
        return self.current().span.start
    }

    micro end_position(self) -> usize {
        if self._tokens.length() == 0 {
            return 0
        }
        return self._tokens⁅self._tokens.length() - 1⁆.unwrap().span.end
    }

    micro advance(mut self) -> unit {
        self._cursor = self._cursor + 1
    }

    micro diagnose(mut self, code: utf8, message: utf8, start: usize, stop: usize) -> unit {
        self._diagnostics = push(self._diagnostics, new_diagnostic(code, Error, message, new_span(start, stop)))
    }

    # 当前 token 出流为 CST 叶子并追加。
    micro emit_leaf(mut self, children: [DataCstNode<TemplateTokenKind>]) -> [DataCstNode<TemplateTokenKind>] {
        let token: DataToken<TemplateTokenKind> = self.current()
        self.advance()
        return push(children, data_cst_token(token))
    }

    # 汇总子节点 span：首子节点 start 到末子节点 stop；空列表给零宽哨兵。
    micro span_of(self, children: [DataCstNode<TemplateTokenKind>], fallback: usize) -> Span {
        if children.length() == 0 {
            return new_span(fallback, fallback)
        }
        let first: Span = data_cst_span(children⁅0⁆.unwrap())
        let last: Span = data_cst_span(children⁅children.length() - 1⁆.unwrap())
        return new_span(first.start, last.end)
    }

    # 收集连续 trivia token 为 CST 叶子。
    micro collect_trivia(mut self, children: [DataCstNode<TemplateTokenKind>]) -> [DataCstNode<TemplateTokenKind>] {
        let mut collected: [DataCstNode<TemplateTokenKind>] = children
        let mut collecting: bool = true
        while collecting {
            if self.at_end() {
                collecting = false
            }
            else {
                match self.current_kind() {
                    case CodeWhitespace:
                        collected = self.emit_leaf(collected)
                    else:
                        collecting = false
                }
            }
        }
        return collected
    }

    # 已收集但未消费的 trivia 回退（trivia 在流中连续相邻，按个数回退游标）。
    micro rewind_trivia(mut self, trivia: [DataCstNode<TemplateTokenKind>]) -> unit {
        self._cursor = self._cursor - trivia.length()
    }

    # ── 顶层与序列 ──

    micro parse_document(mut self) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let mut running: bool = true
        while running {
            let sequence: TemplateSequence = self.parse_sequence(0, 0)
            let mut index: usize = 0
            while index < sequence.children.length() {
                children = push(children, sequence.children⁅index⁆.unwrap())
                index = index + 1
            }
            match sequence.stop {
                case StopEnd:
                    running = false
                else:
                    children = push(children, self.consume_unmatched_closer())
            }
        }
        let span: Span = self.span_of(children, 0)
        return data_cst_node(NodeRoot, span, children)
    }

    # 顶层出现的 closer：诊断并把整个标签挂 Poison（字节不丢），返回节点挂入树。
    micro consume_unmatched_closer(mut self) -> DataCstNode<TemplateTokenKind> {
        let start: usize = self.current_start()
        let leaves: [DataCstNode<TemplateTokenKind>] = self.consume_tag_tokens()
        let span: Span = self.span_of(leaves, start)
        self.diagnose("template.parse.unmatched_closer", "闭合标记没有匹配的开放结构", span.start, span.end)
        return data_cst_poison(span, leaves, "unmatched closer")
    }

    # 消费一个完整标签的全部 token（CodeOpen 到 CodeClose；缺闭标时到输入末尾）。
    micro consume_tag_tokens(mut self) -> [DataCstNode<TemplateTokenKind>] {
        let mut leaves: [DataCstNode<TemplateTokenKind>] = []
        let mut consuming: bool = true
        while consuming && !self.at_end() {
            match self.current_kind() {
                case CodeClose(payload):
                    leaves = self.emit_leaf(leaves)
                    consuming = false
                else:
                    leaves = self.emit_leaf(leaves)
            }
        }
        return leaves
    }

    # 解析子节点序列，直到输入耗尽或遇到 closer 标签（closer 不消费）。
    micro parse_sequence(mut self, statement_depth: usize, loop_depth: usize) -> TemplateSequence {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let mut stop: TemplateParseStop = StopEnd
        let mut running: bool = true
        while running {
            if self.at_end() {
                stop = StopEnd
                running = false
                continue
            }
            match self.current_kind() {
                case CodeOpen(payload):
                    let head: TemplateTokenKind = self.tag_head_kind()
                    match head {
                        case KeywordIf:
                            children = push(children, self.parse_if(statement_depth, loop_depth))
                        case KeywordLoop:
                            children = push(children, self.parse_loop(statement_depth, loop_depth))
                        case KeywordBreak:
                            children = push(children, self.parse_control(NodeBreak, loop_depth))
                        case KeywordContinue:
                            children = push(children, self.parse_control(NodeContinue, loop_depth))
                        case KeywordElse:
                            stop = self.classify_else()
                            running = false
                        case KeywordEnd:
                            stop = self.classify_end()
                            running = false
                        case KeywordExtends:
                            children = push(children, self.parse_extends(statement_depth))
                        case KeywordInclude:
                            children = push(children, self.parse_include(statement_depth))
                        case KeywordPartial:
                            children = push(children, self.parse_partial(statement_depth))
                        case KeywordMacro:
                            children = push(children, self.parse_macro(statement_depth))
                        case KeywordCall:
                            children = push(children, self.parse_call(statement_depth))
                        case KeywordBlock:
                            children = push(children, self.parse_block(statement_depth))
                        case KeywordSuper:
                            children = push(children, self.parse_super())
                        case KeywordFrom:
                            children = push(children, self.parse_from())
                        else:
                            children = push(children, self.parse_interpolation(statement_depth))
                    }
                else:
                    children = self.emit_leaf(children)
            }
        }
        return TemplateSequence { children: children, stop: stop }
    }

    # 标签头分类：CodeOpen 之后首个非 trivia token 的 kind。
    micro tag_head_kind(self) -> TemplateTokenKind {
        let mut ahead: usize = self._cursor + 1
        while ahead < self._tokens.length() {
            let kind: TemplateTokenKind = self._tokens⁅ahead⁆.unwrap().kind
            match kind {
                case CodeWhitespace:
                    ahead = ahead + 1
                else:
                    return kind
            }
        }
        return Illegal
    }

    micro classify_else(self) -> TemplateParseStop {
        let mut ahead: usize = self._cursor + 1
        while ahead < self._tokens.length() {
            let kind: TemplateTokenKind = self._tokens⁅ahead⁆.unwrap().kind
            match kind {
                case CodeWhitespace:
                    ahead = ahead + 1
                case KeywordIf:
                    return StopElseIf
                else:
                    return StopElse
            }
        }
        return StopElse
    }

    micro classify_end(self) -> TemplateParseStop {
        let mut ahead: usize = self._cursor + 1
        while ahead < self._tokens.length() {
            let kind: TemplateTokenKind = self._tokens⁅ahead⁆.unwrap().kind
            match kind {
                case CodeWhitespace:
                    ahead = ahead + 1
                case KeywordIf:
                    return StopEndIf
                case KeywordLoop:
                    return StopEndLoop
                case KeywordBlock:
                    return StopEndBlock
                case KeywordPartial:
                    return StopEndPartial
                case KeywordMacro:
                    return StopEndMacro
                case KeywordCall:
                    return StopEndCall
                else:
                    return StopOther
            }
        }
        return StopOther
    }

    # closer 标签的 trim marker 拒绝（双侧都禁止）；当前位置必须在 CodeOpen。
    micro check_closer_trim(mut self) -> unit {
        let open: DataToken<TemplateTokenKind> = self.current()
        match open.kind {
            case CodeOpen(payload):
                match payload.trim {
                    case TrimNone:
                        let marker_free: bool = true
                    else:
                        self.diagnose("template.parse.closer_trim_marker", "闭合标记禁止携带 trim marker", open.span.start, open.span.end)
                }
            else:
                self.diagnose("template.parse.unexpected_token", "内部状态错误：closer 校验不在标签起点", open.span.start, open.span.end)
        }
        # 闭标侧。
        let mut ahead: usize = self._cursor + 1
        let mut scanning: bool = true
        while scanning && ahead < self._tokens.length() {
            let candidate: DataToken<TemplateTokenKind> = self._tokens⁅ahead⁆.unwrap()
            match candidate.kind {
                case CodeClose(payload):
                    match payload.trim {
                        case TrimNone:
                            scanning = false
                        else:
                            self.diagnose("template.parse.closer_trim_marker", "闭合标记禁止携带 trim marker", candidate.span.start, candidate.span.end)
                            scanning = false
                    }
                else:
                    ahead = ahead + 1
            }
        }
    }

    # ── 语句 ──

    # `if test`：head + body + 可选 else if 链 + 可选 else + `end if`。
    micro parse_if(mut self, statement_depth: usize, loop_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.parse_tag_expression(children, start, statement_depth + 1)
        children = self.close_tag(children, start)

        let body: TemplateSequence = self.parse_sequence(statement_depth + 1, loop_depth)
        let mut index: usize = 0
        while index < body.children.length() {
            children = push(children, body.children⁅index⁆.unwrap())
            index = index + 1
        }

        let mut stop: TemplateParseStop = body.stop
        let mut continuing: bool = true
        while continuing {
            match stop {
                case StopElseIf:
                    let branch: TemplateBranch = self.parse_elseif(statement_depth, loop_depth)
                    children = push(children, branch.node)
                    stop = branch.stop
                case StopElse:
                    let branch: TemplateBranch = self.parse_else(statement_depth, loop_depth)
                    children = push(children, branch.node)
                    stop = branch.stop
                case StopEndIf:
                    self.check_closer_trim()
                    children = self.consume_end_tag(children, "end if")
                    continuing = false
                case StopEnd:
                    let position: usize = self.end_position()
                    children = push(children, data_cst_missing(new_span(position, position), "if 语句缺少 `end if`"))
                    self.diagnose("template.parse.missing_end_if", "if 语句缺少 `end if`", start, position)
                    continuing = false
                else:
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "if 语句缺少 `end if`"))
                    self.diagnose("template.parse.missing_end_if", "if 语句缺少 `end if`", start, position)
                    continuing = false
            }
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeIf, span, children)
    }

    micro parse_elseif(mut self, statement_depth: usize, loop_depth: usize) -> TemplateBranch {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        self.check_closer_trim()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.parse_tag_expression(children, start, statement_depth + 1)
        children = self.close_tag(children, start)
        let body: TemplateSequence = self.parse_sequence(statement_depth + 1, loop_depth)
        let mut index: usize = 0
        while index < body.children.length() {
            children = push(children, body.children⁅index⁆.unwrap())
            index = index + 1
        }
        let span: Span = self.span_of(children, start)
        return TemplateBranch { node: data_cst_node(NodeElseIf, span, children), stop: body.stop }
    }

    micro parse_else(mut self, statement_depth: usize, loop_depth: usize) -> TemplateBranch {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        self.check_closer_trim()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        # `else` 后不接受其他内容：多余 token 挂 Poison 并诊断。
        if !self.at_end() {
            match self.current_kind() {
                case CodeClose(payload):
                    children = self.emit_leaf(children)
                else:
                    let error_start: usize = self.current_start()
                    let mut leaves: [DataCstNode<TemplateTokenKind>] = []
                    let mut consuming: bool = true
                    while consuming && !self.at_end() {
                        match self.current_kind() {
                            case CodeClose(payload):
                                consuming = false
                            else:
                                leaves = self.emit_leaf(leaves)
                        }
                    }
                    let span: Span = self.span_of(leaves, error_start)
                    self.diagnose("template.parse.unexpected_token", "`else` 后不接受其他内容", span.start, span.end)
                    children = push(children, data_cst_poison(span, leaves, "unexpected tokens after else"))
                    children = self.close_tag(children, start)
            }
        }
        else {
            children = self.close_tag(children, start)
        }
        let body: TemplateSequence = self.parse_sequence(statement_depth + 1, loop_depth)
        let mut index: usize = 0
        while index < body.children.length() {
            children = push(children, body.children⁅index⁆.unwrap())
            index = index + 1
        }
        let span: Span = self.span_of(children, start)
        return TemplateBranch { node: data_cst_node(NodeElse, span, children), stop: body.stop }
    }

    # `loop item in iterable`：head + body + `end loop`。
    micro parse_loop(mut self, statement_depth: usize, loop_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        # item 标识符。
        if !self.at_end() {
            match self.current_kind() {
                case Identifier:
                    children = self.emit_leaf(children)
                else:
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "loop 缺少 item 标识符"))
                    self.diagnose("template.parse.loop_requires_item", "loop 需要 item 标识符", start, position)
            }
        }
        children = self.collect_trivia(children)
        # `in`。
        if !self.at_end() {
            match self.current_kind() {
                case KeywordIn:
                    children = self.emit_leaf(children)
                else:
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "loop 缺少 `in`"))
                    self.diagnose("template.parse.loop_requires_in", "loop 需要 `item in iterable`", start, position)
            }
        }
        children = self.parse_tag_expression(children, start, statement_depth + 1)
        children = self.close_tag(children, start)

        let body: TemplateSequence = self.parse_sequence(statement_depth + 1, loop_depth + 1)
        let mut index: usize = 0
        while index < body.children.length() {
            children = push(children, body.children⁅index⁆.unwrap())
            index = index + 1
        }
        match body.stop {
            case StopEndLoop:
                self.check_closer_trim()
                children = self.consume_end_tag(children, "end loop")
            case StopEnd:
                let position: usize = self.end_position()
                children = push(children, data_cst_missing(new_span(position, position), "loop 缺少 `end loop`"))
                self.diagnose("template.parse.missing_end_loop", "loop 缺少 `end loop`", start, position)
            else:
                let position: usize = self.current_start()
                children = push(children, data_cst_missing(new_span(position, position), "loop 缺少 `end loop`"))
                self.diagnose("template.parse.missing_end_loop", "loop 缺少 `end loop`", start, position)
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeLoop, span, children)
    }

    # break / continue：绑定词法最近外层 loop；多余内容诊断并保留。
    micro parse_control(mut self, node_kind: TemplateTokenKind, loop_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        if loop_depth == 0 {
            self.diagnose("template.parse.control_outside_loop", "break/continue 只可用于同一词法单元内的 loop", start, start)
        }
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        if !self.at_end() {
            match self.current_kind() {
                case CodeClose(payload):
                    children = self.emit_leaf(children)
                else:
                    let error_start: usize = self.current_start()
                    let mut leaves: [DataCstNode<TemplateTokenKind>] = []
                    let mut consuming: bool = true
                    while consuming && !self.at_end() {
                        match self.current_kind() {
                            case CodeClose(payload):
                                consuming = false
                            else:
                                leaves = self.emit_leaf(leaves)
                        }
                    }
                    let span: Span = self.span_of(leaves, error_start)
                    self.diagnose("template.parse.unexpected_token", "break/continue 后不接受其他内容", span.start, span.end)
                    children = push(children, data_cst_poison(span, leaves, "unexpected tokens after control"))
                    children = self.close_tag(children, start)
            }
        }
        else {
            children = self.close_tag(children, start)
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(node_kind, span, children)
    }

    # 暂不支持的语句表面：整个标签挂 NodeUnsupported 并诊断（标签 token 全保留）。
    micro parse_unsupported(mut self, name: utf8) -> DataCstNode<TemplateTokenKind> {
        let start: usize = self.current_start()
        let leaves: [DataCstNode<TemplateTokenKind>] = self.consume_tag_tokens()
        let span: Span = self.span_of(leaves, start)
        self.diagnose("template.parse.unsupported_statement", name, span.start, span.end)
        return data_cst_node(NodeUnsupported, span, leaves)
    }

    # 插值标签：表达式子树；空标签诊断 + Missing。
    micro parse_interpolation(mut self, statement_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.parse_tag_expression(children, start, statement_depth + 1)
        children = self.close_tag(children, start)
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeInterpolation, span, children)
    }

    # 闭标：当前位置应为 CodeClose；缺席则插 Missing 并诊断。
    micro close_tag(mut self, children: [DataCstNode<TemplateTokenKind>], tag_start: usize) -> [DataCstNode<TemplateTokenKind>] {
        let mut result: [DataCstNode<TemplateTokenKind>] = children
        if !self.at_end() {
            match self.current_kind() {
                case CodeClose(payload):
                    result = self.emit_leaf(result)
                else:
                    let position: usize = self.end_position()
                    result = push(result, data_cst_missing(new_span(position, position), "代码标签未闭合"))
                    self.diagnose("template.parse.unclosed_code_tag", "代码标签未闭合", tag_start, position)
            }
        }
        else {
            let position: usize = self.end_position()
            result = push(result, data_cst_missing(new_span(position, position), "代码标签未闭合"))
            self.diagnose("template.parse.unclosed_code_tag", "代码标签未闭合", tag_start, position)
        }
        return result
    }

    # `end if` / `end loop` 标签：定界 + 两个关键字 + trivia + 闭标；多余内容诊断。
    micro consume_end_tag(mut self, children: [DataCstNode<TemplateTokenKind>], name: utf8) -> [DataCstNode<TemplateTokenKind>] {
        let mut result: [DataCstNode<TemplateTokenKind>] = children
        let start: usize = self.current_start()
        result = self.emit_leaf(result)
        result = self.collect_trivia(result)
        result = self.emit_leaf(result)
        result = self.collect_trivia(result)
        result = self.emit_leaf(result)
        result = self.collect_trivia(result)
        if !self.at_end() {
            match self.current_kind() {
                case CodeClose(payload):
                    result = self.emit_leaf(result)
                else:
                    let error_start: usize = self.current_start()
                    let mut leaves: [DataCstNode<TemplateTokenKind>] = []
                    let mut consuming: bool = true
                    while consuming && !self.at_end() {
                        match self.current_kind() {
                            case CodeClose(payload):
                                consuming = false
                            else:
                                leaves = self.emit_leaf(leaves)
                        }
                    }
                    let span: Span = self.span_of(leaves, error_start)
                    self.diagnose("template.parse.unexpected_token", "闭合标记后不接受其他内容", span.start, span.end)
                    result = push(result, data_cst_poison(span, leaves, "unexpected tokens in end tag"))
                    result = self.close_tag(result, start)
            }
        }
        else {
            result = self.close_tag(result, start)
        }
        return result
    }

    # 标签内的表达式区：trivia + 表达式 + trivia；尾随多余内容挂 Poison。
    # 返回追加用的子节点列表（trivia 与表达式同级，保持无损）。
    micro parse_tag_expression(mut self, children: [DataCstNode<TemplateTokenKind>], tag_start: usize, depth: usize) -> [DataCstNode<TemplateTokenKind>] {
        let mut result: [DataCstNode<TemplateTokenKind>] = children
        result = self.collect_trivia(result)
        if depth > self._max_depth {
            let mut leaves: [DataCstNode<TemplateTokenKind>] = []
            let mut consuming: bool = true
            while consuming && !self.at_end() {
                match self.current_kind() {
                    case CodeClose(payload):
                        consuming = false
                    else:
                        leaves = self.emit_leaf(leaves)
                }
            }
            let span: Span = self.span_of(leaves, tag_start)
            self.diagnose("template.parse.max_depth_exceeded", "表达式嵌套深度超限", span.start, span.end)
            result = push(result, data_cst_poison(span, leaves, "max depth exceeded"))
            return result
        }
        if self.at_end() {
            let position: usize = self.end_position()
            self.diagnose("template.parse.empty_code_tag", "标签内缺少表达式", tag_start, position)
            result = push(result, data_cst_missing(new_span(position, position), "缺少表达式"))
            return result
        }
        match self.current_kind() {
            case CodeClose(payload):
                let position: usize = self.current_start()
                self.diagnose("template.parse.empty_code_tag", "标签内缺少表达式", tag_start, position)
                result = push(result, data_cst_missing(new_span(position, position), "缺少表达式"))
            else:
                let expression: DataCstNode<TemplateTokenKind> = self.parse_expression(depth)
                result = push(result, expression)
                result = self.collect_trivia(result)
                if !self.at_end() && !template_kind_is_code_close(self.current_kind()) {
                    let error_start: usize = self.current_start()
                    let mut leaves: [DataCstNode<TemplateTokenKind>] = []
                    let mut consuming: bool = true
                    while consuming && !self.at_end() {
                        match self.current_kind() {
                            case CodeClose(payload):
                                consuming = false
                            else:
                                leaves = self.emit_leaf(leaves)
                        }
                    }
                    let span: Span = self.span_of(leaves, error_start)
                    self.diagnose("template.parse.trailing_input", "表达式后存在多余内容", span.start, span.end)
                    result = push(result, data_cst_poison(span, leaves, "trailing input"))
                }
        }
        return result
    }

    # ── 表达式（Pratt 优先级；trivia 保留在各节点 children 原位）──
    # 优先级（低到高）：`|>` 管道 → `||` → `&&` → 比较/`is` 测试（不可链）→ `+ -` → `* / %`
    # → 一元 `! - +` → 后缀 `.` `[]` `()` → primary（字面量/标识符/对象字面量/括号）。

    micro parse_expression(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        return self.parse_pipe(depth)
    }

    micro parse_pipe(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut left: DataCstNode<TemplateTokenKind> = self.parse_or(depth)
        let mut looping: bool = true
        while looping {
            let mut trivia: [DataCstNode<TemplateTokenKind>] = []
            trivia = self.collect_trivia(trivia)
            if self.at_end() {
                self.rewind_trivia(trivia)
                looping = false
                continue
            }
            match self.current_kind() {
                case Pipe:
                    let mut children: [DataCstNode<TemplateTokenKind>] = []
                    children = push(children, left)
                    let mut index: usize = 0
                    while index < trivia.length() {
                        children = push(children, trivia⁅index⁆.unwrap())
                        index = index + 1
                    }
                    children = self.emit_leaf(children)
                    children = self.collect_trivia(children)
                    # 过滤器名。
                    if !self.at_end() {
                        match self.current_kind() {
                            case Identifier:
                                children = self.emit_leaf(children)
                            else:
                                let position: usize = self.current_start()
                                children = push(children, data_cst_missing(new_span(position, position), "缺少过滤器名"))
                                self.diagnose("template.parse.expected_filter_name", "管道后需要过滤器名", position, position)
                        }
                    }
                    else {
                        let position: usize = self.end_position()
                        children = push(children, data_cst_missing(new_span(position, position), "缺少过滤器名"))
                        self.diagnose("template.parse.expected_filter_name", "管道后需要过滤器名", position, position)
                    }
                    children = self.collect_trivia(children)
                    # 参数：`(args)` 或 `: arg`（冒号形式）。
                    if !self.at_end() && template_kind_is_paren_open(self.current_kind()) {
                        children = self.parse_call_arguments(children, depth)
                    }
                    if !self.at_end() && template_kind_is_colon(self.current_kind()) {
                        children = self.emit_leaf(children)
                        children = self.collect_trivia(children)
                        if !self.at_end() && !template_kind_is_code_close(self.current_kind()) {
                            let argument: DataCstNode<TemplateTokenKind> = self.parse_pipe(depth + 1)
                            children = push(children, argument)
                        }
                        else {
                            let position: usize = self.end_position()
                            children = push(children, data_cst_missing(new_span(position, position), "冒号形式缺少参数"))
                            self.diagnose("template.parse.unexpected_token", "冒号形式缺少参数", position, position)
                        }
                    }
                    let span: Span = self.span_of(children, data_cst_span(left).start)
                    left = data_cst_node(NodeExpressionPipe, span, children)
                else:
                    self.rewind_trivia(trivia)
                    looping = false
            }
        }
        return left
    }

    micro parse_or(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let left: DataCstNode<TemplateTokenKind> = self.parse_and(depth)
        return self.parse_binary_chain(left, depth, 1)
    }

    micro parse_and(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let left: DataCstNode<TemplateTokenKind> = self.parse_comparison(depth)
        return self.parse_binary_chain(left, depth, 2)
    }

    micro parse_additive(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let left: DataCstNode<TemplateTokenKind> = self.parse_multiplicative(depth)
        return self.parse_binary_chain(left, depth, 3)
    }

    micro parse_multiplicative(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let left: DataCstNode<TemplateTokenKind> = self.parse_unary(depth)
        return self.parse_binary_chain(left, depth, 4)
    }

    # 二元链：level 1 = `||`，2 = `&&`，3 = `+ -`，4 = `* / %`。
    micro parse_binary_chain(mut self, left: DataCstNode<TemplateTokenKind>, depth: usize, level: usize) -> DataCstNode<TemplateTokenKind> {
        let mut result: DataCstNode<TemplateTokenKind> = left
        let mut looping: bool = true
        while looping {
            let mut trivia: [DataCstNode<TemplateTokenKind>] = []
            trivia = self.collect_trivia(trivia)
            if self.at_end() {
                self.rewind_trivia(trivia)
                looping = false
                continue
            }
            if !self.operator_at_level(level) {
                self.rewind_trivia(trivia)
                looping = false
                continue
            }
            let mut children: [DataCstNode<TemplateTokenKind>] = []
            children = push(children, result)
            let mut index: usize = 0
            while index < trivia.length() {
                children = push(children, trivia⁅index⁆.unwrap())
                index = index + 1
            }
            children = self.emit_leaf(children)
            children = self.collect_trivia(children)
            if self.at_end() {
                let position: usize = self.end_position()
                children = push(children, data_cst_missing(new_span(position, position), "二元运算符缺少右操作数"))
                self.diagnose("template.parse.unexpected_token", "二元运算符缺少右操作数", position, position)
            }
            else {
                match self.current_kind() {
                    case CodeClose(payload):
                        let position: usize = self.current_start()
                        children = push(children, data_cst_missing(new_span(position, position), "二元运算符缺少右操作数"))
                        self.diagnose("template.parse.unexpected_token", "二元运算符缺少右操作数", position, position)
                    else:
                        let right: DataCstNode<TemplateTokenKind> = self.parse_operand_for_level(level, depth)
                        children = push(children, right)
                }
            }
            let span: Span = self.span_of(children, data_cst_span(result).start)
            result = data_cst_node(NodeExpressionBinary, span, children)
        }
        return result
    }

    micro operator_at_level(self, level: usize) -> bool {
        let kind: TemplateTokenKind = self.current_kind()
        if level == 1 {
            match kind {
                case Or:
                    return true
                else:
                    return false
            }
        }
        if level == 2 {
            match kind {
                case And:
                    return true
                else:
                    return false
            }
        }
        if level == 3 {
            match kind {
                case Plus:
                    return true
                case Minus:
                    return true
                else:
                    return false
            }
        }
        match kind {
            case Star:
                return true
            case Slash:
                return true
            case Percent:
                return true
            else:
                return false
        }
    }

    micro parse_operand_for_level(mut self, level: usize, depth: usize) -> DataCstNode<TemplateTokenKind> {
        if level == 1 {
            return self.parse_and(depth)
        }
        if level == 2 {
            return self.parse_comparison(depth)
        }
        if level == 3 {
            return self.parse_multiplicative(depth)
        }
        return self.parse_unary(depth)
    }

    # 比较与 `is` 测试：不可链（至多一次）。
    micro parse_comparison(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut left: DataCstNode<TemplateTokenKind> = self.parse_additive(depth)
        let mut trivia: [DataCstNode<TemplateTokenKind>] = []
        trivia = self.collect_trivia(trivia)
        if self.at_end() {
            self.rewind_trivia(trivia)
            return left
        }
        match self.current_kind() {
            case KeywordIs:
                let mut children: [DataCstNode<TemplateTokenKind>] = []
                children = push(children, left)
                let mut index: usize = 0
                while index < trivia.length() {
                    children = push(children, trivia⁅index⁆.unwrap())
                    index = index + 1
                }
                children = self.emit_leaf(children)
                children = self.collect_trivia(children)
                # 可选 `not`。
                if !self.at_end() && template_kind_is_keyword_not(self.current_kind()) {
                    children = self.emit_leaf(children)
                    children = self.collect_trivia(children)
                }
                # 测试名：Identifier 或 `null`。
                if !self.at_end() {
                    match self.current_kind() {
                        case Identifier:
                            children = self.emit_leaf(children)
                        case LiteralNull:
                            children = self.emit_leaf(children)
                        else:
                            let position: usize = self.current_start()
                            children = push(children, data_cst_missing(new_span(position, position), "缺少测试名"))
                            self.diagnose("template.parse.expected_test_name", "`is` 后需要测试名", position, position)
                    }
                }
                else {
                    let position: usize = self.end_position()
                    children = push(children, data_cst_missing(new_span(position, position), "缺少测试名"))
                    self.diagnose("template.parse.expected_test_name", "`is` 后需要测试名", position, position)
                }
                children = self.collect_trivia(children)
                # 可选参数列表。
                if !self.at_end() && template_kind_is_paren_open(self.current_kind()) {
                    children = self.parse_call_arguments(children, depth)
                }
                let span: Span = self.span_of(children, data_cst_span(left).start)
                return data_cst_node(NodeExpressionTest, span, children)
            case EqualEqual:
                return self.parse_comparison_tail(left, trivia, depth)
            case BangEqual:
                return self.parse_comparison_tail(left, trivia, depth)
            case LessEqual:
                return self.parse_comparison_tail(left, trivia, depth)
            case GreaterEqual:
                return self.parse_comparison_tail(left, trivia, depth)
            case Less:
                return self.parse_comparison_tail(left, trivia, depth)
            case Greater:
                return self.parse_comparison_tail(left, trivia, depth)
            case KeywordIn:
                return self.parse_comparison_tail(left, trivia, depth)
            else:
                self.rewind_trivia(trivia)
                return left
        }
    }

    micro parse_comparison_tail(mut self, left: DataCstNode<TemplateTokenKind>, trivia: [DataCstNode<TemplateTokenKind>], depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        children = push(children, left)
        let mut index: usize = 0
        while index < trivia.length() {
            children = push(children, trivia⁅index⁆.unwrap())
            index = index + 1
        }
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        if self.at_end() {
            let position: usize = self.end_position()
            children = push(children, data_cst_missing(new_span(position, position), "比较运算符缺少右操作数"))
            self.diagnose("template.parse.unexpected_token", "比较运算符缺少右操作数", position, position)
        }
        else {
            match self.current_kind() {
                case CodeClose(payload):
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "比较运算符缺少右操作数"))
                    self.diagnose("template.parse.unexpected_token", "比较运算符缺少右操作数", position, position)
                else:
                    let right: DataCstNode<TemplateTokenKind> = self.parse_additive(depth)
                    children = push(children, right)
            }
        }
        let span: Span = self.span_of(children, data_cst_span(left).start)
        return data_cst_node(NodeExpressionBinary, span, children)
    }

    micro parse_unary(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        match self.current_kind() {
            case Bang:
                return self.parse_unary_tail(depth)
            case Minus:
                return self.parse_unary_tail(depth)
            case Plus:
                return self.parse_unary_tail(depth)
            else:
                return self.parse_postfix(depth)
        }
    }

    micro parse_unary_tail(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        if self.at_end() {
            let position: usize = self.end_position()
            children = push(children, data_cst_missing(new_span(position, position), "一元运算符缺少操作数"))
            self.diagnose("template.parse.unexpected_token", "一元运算符缺少操作数", position, position)
        }
        else {
            match self.current_kind() {
                case CodeClose(payload):
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "一元运算符缺少操作数"))
                    self.diagnose("template.parse.unexpected_token", "一元运算符缺少操作数", position, position)
                else:
                    let operand: DataCstNode<TemplateTokenKind> = self.parse_unary(depth + 1)
                    children = push(children, operand)
            }
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeExpressionUnary, span, children)
    }

    micro parse_postfix(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut left: DataCstNode<TemplateTokenKind> = self.parse_primary(depth)
        let mut looping: bool = true
        while looping {
            let mut trivia: [DataCstNode<TemplateTokenKind>] = []
            trivia = self.collect_trivia(trivia)
            if self.at_end() {
                self.rewind_trivia(trivia)
                looping = false
                continue
            }
            match self.current_kind() {
                case Dot:
                    let mut children: [DataCstNode<TemplateTokenKind>] = []
                    children = push(children, left)
                    let mut index: usize = 0
                    while index < trivia.length() {
                        children = push(children, trivia⁅index⁆.unwrap())
                        index = index + 1
                    }
                    children = self.emit_leaf(children)
                    children = self.collect_trivia(children)
                    if !self.at_end() {
                        match self.current_kind() {
                            case Identifier:
                                children = self.emit_leaf(children)
                            else:
                                let position: usize = self.current_start()
                                children = push(children, data_cst_missing(new_span(position, position), "成员访问缺少属性名"))
                                self.diagnose("template.parse.expected_property_name", "`.` 后需要属性名", position, position)
                        }
                    }
                    else {
                        let position: usize = self.end_position()
                        children = push(children, data_cst_missing(new_span(position, position), "成员访问缺少属性名"))
                        self.diagnose("template.parse.expected_property_name", "`.` 后需要属性名", position, position)
                    }
                    let span: Span = self.span_of(children, data_cst_span(left).start)
                    left = data_cst_node(NodeExpressionMember, span, children)
                case BracketOpen:
                    let mut children: [DataCstNode<TemplateTokenKind>] = []
                    children = push(children, left)
                    let mut index: usize = 0
                    while index < trivia.length() {
                        children = push(children, trivia⁅index⁆.unwrap())
                        index = index + 1
                    }
                    children = self.emit_leaf(children)
                    children = self.collect_trivia(children)
                    if !self.at_end() {
                        match self.current_kind() {
                            case BracketClose:
                                let position: usize = self.current_start()
                                children = push(children, data_cst_missing(new_span(position, position), "下标缺少表达式"))
                                self.diagnose("template.parse.unexpected_token", "下标缺少表达式", position, position)
                            else:
                                let index_expression: DataCstNode<TemplateTokenKind> = self.parse_pipe(depth + 1)
                                children = push(children, index_expression)
                        }
                    }
                    children = self.collect_trivia(children)
                    if !self.at_end() {
                        match self.current_kind() {
                            case BracketClose:
                                children = self.emit_leaf(children)
                            else:
                                let position: usize = self.current_start()
                                children = push(children, data_cst_missing(new_span(position, position), "缺少 `]`"))
                                self.diagnose("template.parse.unclosed_expression", "下标缺少 `]`", position, position)
                        }
                    }
                    else {
                        let position: usize = self.end_position()
                        children = push(children, data_cst_missing(new_span(position, position), "缺少 `]`"))
                        self.diagnose("template.parse.unclosed_expression", "下标缺少 `]`", position, position)
                    }
                    let span: Span = self.span_of(children, data_cst_span(left).start)
                    left = data_cst_node(NodeExpressionIndex, span, children)
                case ParenOpen:
                    let mut children: [DataCstNode<TemplateTokenKind>] = []
                    children = push(children, left)
                    let mut index: usize = 0
                    while index < trivia.length() {
                        children = push(children, trivia⁅index⁆.unwrap())
                        index = index + 1
                    }
                    children = self.parse_call_arguments(children, depth)
                    let span: Span = self.span_of(children, data_cst_span(left).start)
                    left = data_cst_node(NodeExpressionCall, span, children)
                else:
                    self.rewind_trivia(trivia)
                    looping = false
            }
        }
        return left
    }

    # 调用参数：`( arg, ... )`；当前位置在 ParenOpen。
    micro parse_call_arguments(mut self, children: [DataCstNode<TemplateTokenKind>], depth: usize) -> [DataCstNode<TemplateTokenKind>] {
        let mut result: [DataCstNode<TemplateTokenKind>] = children
        result = self.emit_leaf(result)
        result = self.collect_trivia(result)
        let mut looping: bool = true
        while looping {
            if self.at_end() {
                let position: usize = self.end_position()
                result = push(result, data_cst_missing(new_span(position, position), "缺少 `)`"))
                self.diagnose("template.parse.unclosed_expression", "参数列表缺少 `)`", position, position)
                looping = false
                continue
            }
            match self.current_kind() {
                case ParenClose:
                    result = self.emit_leaf(result)
                    looping = false
                case Comma:
                    result = self.emit_leaf(result)
                    result = self.collect_trivia(result)
                else:
                    let argument: DataCstNode<TemplateTokenKind> = self.parse_pipe(depth + 1)
                    result = push(result, argument)
                    result = self.collect_trivia(result)
            }
        }
        return result
    }

    micro parse_primary(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        if self.at_end() {
            let position: usize = self.end_position()
            self.diagnose("template.parse.unexpected_token", "缺少表达式", position, position)
            return data_cst_missing(new_span(position, position), "缺少表达式")
        }
        match self.current_kind() {
            case String:
                return self.parse_leaf()
            case Number:
                return self.parse_leaf()
            case LiteralTrue:
                return self.parse_leaf()
            case LiteralFalse:
                return self.parse_leaf()
            case LiteralNull:
                return self.parse_leaf()
            case Identifier:
                return self.parse_leaf()
            case ParenOpen:
                return self.parse_group(depth)
            case BraceOpen:
                return self.parse_object_literal(depth)
            case Illegal:
                let token: DataToken<TemplateTokenKind> = self.current()
                self.diagnose("template.parse.unexpected_token", "非法 token 不能参与表达式", token.span.start, token.span.end)
                return self.parse_leaf()
            else:
                let token: DataToken<TemplateTokenKind> = self.current()
                self.diagnose("template.parse.unexpected_token", "表达式中的意外 token", token.span.start, token.span.end)
                # 恢复：消费该 token 挂 Poison（字节不丢），继续。
                let mut leaves: [DataCstNode<TemplateTokenKind>] = []
                leaves = self.emit_leaf(leaves)
                return data_cst_poison(token.span, leaves, "unexpected token")
        }
    }

    micro parse_leaf(mut self) -> DataCstNode<TemplateTokenKind> {
        let token: DataToken<TemplateTokenKind> = self.current()
        self.advance()
        return data_cst_token(token)
    }

    micro parse_group(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        if !self.at_end() {
            match self.current_kind() {
                case ParenClose:
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "括号内缺少表达式"))
                    self.diagnose("template.parse.unexpected_token", "括号内缺少表达式", position, position)
                else:
                    let inner: DataCstNode<TemplateTokenKind> = self.parse_pipe(depth + 1)
                    children = push(children, inner)
            }
        }
        children = self.collect_trivia(children)
        if !self.at_end() {
            match self.current_kind() {
                case ParenClose:
                    children = self.emit_leaf(children)
                else:
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "缺少 `)`"))
                    self.diagnose("template.parse.unclosed_expression", "分组缺少 `)`", position, position)
            }
        }
        else {
            let position: usize = self.end_position()
            children = push(children, data_cst_missing(new_span(position, position), "缺少 `)`"))
            self.diagnose("template.parse.unclosed_expression", "分组缺少 `)`", position, position)
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeExpressionGroup, span, children)
    }

    # 对象字面量：`{ key: expr, "key": expr }`；key 唯一性检查需词素，
    # 词素在 builder（持有源）完成，语法段只承载结构。
    micro parse_object_literal(mut self, depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        let mut looping: bool = true
        while looping {
            if self.at_end() {
                let position: usize = self.end_position()
                children = push(children, data_cst_missing(new_span(position, position), "缺少 `\}`"))
                self.diagnose("template.parse.unclosed_expression", "对象字面量缺少 `\}`", position, position)
                looping = false
                continue
            }
            match self.current_kind() {
                case BraceClose:
                    children = self.emit_leaf(children)
                    looping = false
                case Identifier:
                    children = self.parse_object_entry(children, depth)
                case String:
                    children = self.parse_object_entry(children, depth)
                else:
                    let token: DataToken<TemplateTokenKind> = self.current()
                    self.diagnose("template.parse.unexpected_token", "对象字面量需要键", token.span.start, token.span.end)
                    let mut leaves: [DataCstNode<TemplateTokenKind>] = []
                    leaves = self.emit_leaf(leaves)
                    children = push(children, data_cst_poison(token.span, leaves, "unexpected object key"))
            }
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeExpressionObject, span, children)
    }

    micro parse_object_entry(mut self, children: [DataCstNode<TemplateTokenKind>], depth: usize) -> [DataCstNode<TemplateTokenKind>] {
        let mut entry: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        entry = self.emit_leaf(entry)
        entry = self.collect_trivia(entry)
        if !self.at_end() {
            match self.current_kind() {
                case Colon:
                    entry = self.emit_leaf(entry)
                else:
                    let position: usize = self.current_start()
                    entry = push(entry, data_cst_missing(new_span(position, position), "缺少 `:`"))
                    self.diagnose("template.parse.unexpected_token", "对象键后需要 `:`", position, position)
            }
        }
        entry = self.collect_trivia(entry)
        if !self.at_end() {
            match self.current_kind() {
                case BraceClose:
                    let position: usize = self.current_start()
                    entry = push(entry, data_cst_missing(new_span(position, position), "缺少对象值"))
                    self.diagnose("template.parse.unexpected_token", "缺少对象值", position, position)
                else:
                    let value: DataCstNode<TemplateTokenKind> = self.parse_pipe(depth + 1)
                    entry = push(entry, value)
            }
        }
        let span: Span = self.span_of(entry, start)
        let node: DataCstNode<TemplateTokenKind> = data_cst_node(NodeExpressionObjectEntry, span, entry)
        let mut result: [DataCstNode<TemplateTokenKind>] = children
        result = push(result, node)
        result = self.collect_trivia(result)
        if !self.at_end() && template_kind_is_comma(self.current_kind()) {
            result = self.emit_leaf(result)
            result = self.collect_trivia(result)
        }
        return result
    }
}

    # ── 继承 / 包含 / partial / 宏 ──

    # `extends <string-expr>`：只允许左侧 trim marker（右 marker 拒绝）。
    micro parse_extends(mut self, statement_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.parse_tag_expression(children, start, statement_depth + 1)
        # 闭标：extends 只允许左侧 marker。
        if !self.at_end() {
            match self.current_kind() {
                case CodeClose(payload):
                    match payload.trim {
                        case TrimNone:
                            children = self.emit_leaf(children)
                        else:
                            self.diagnose("template.parse.extends_trim_marker", "`extends` 只允许左侧 trim marker", self.current_start(), self.current().span.end)
                            children = self.emit_leaf(children)
                    }
                else:
                    let position: usize = self.end_position()
                    children = push(children, data_cst_missing(new_span(position, position), "代码标签未闭合"))
                    self.diagnose("template.parse.unclosed_code_tag", "代码标签未闭合", start, position)
            }
        }
        else {
            let position: usize = self.end_position()
            children = push(children, data_cst_missing(new_span(position, position), "代码标签未闭合"))
            self.diagnose("template.parse.unclosed_code_tag", "代码标签未闭合", start, position)
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeExtends, span, children)
    }

    # `block <name>` … `end block`：name 恰为一个标识符；block body 是独立词法单元
    # （loop 绑定深度重计），`super` 深度在 body 解析期间加一。
    micro parse_block(mut self, statement_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        if !self.at_end() {
            match self.current_kind() {
                case Identifier:
                    children = self.emit_leaf(children)
                else:
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "block 缺少名称"))
                    self.diagnose("template.parse.block_requires_name", "block 需要恰好一个名称标识符", start, position)
            }
        }
        children = self.collect_trivia(children)
        # 多余内容诊断并保留。
        if !self.at_end() && !template_kind_is_code_close(self.current_kind()) {
            let error_start: usize = self.current_start()
            let mut leaves: [DataCstNode<TemplateTokenKind>] = []
            let mut consuming: bool = true
            while consuming && !self.at_end() {
                match self.current_kind() {
                    case CodeClose(payload):
                        consuming = false
                    else:
                        leaves = self.emit_leaf(leaves)
                }
            }
            let span: Span = self.span_of(leaves, error_start)
            self.diagnose("template.parse.block_requires_name", "block 名称后不接受其他内容", span.start, span.end)
            children = push(children, data_cst_poison(span, leaves, "unexpected tokens after block name"))
        }
        children = self.close_tag(children, start)
        self._block_depth = self._block_depth + 1
        let body: TemplateSequence = self.parse_sequence(statement_depth + 1, 0)
        self._block_depth = self._block_depth - 1
        let mut index: usize = 0
        while index < body.children.length() {
            children = push(children, body.children⁅index⁆.unwrap())
            index = index + 1
        }
        match body.stop {
            case StopEndBlock:
                self.check_closer_trim()
                children = self.consume_end_tag(children, "end block")
            case StopEnd:
                let position: usize = self.end_position()
                children = push(children, data_cst_missing(new_span(position, position), "block 缺少 `end block`"))
                self.diagnose("template.parse.missing_end_block", "block 缺少 `end block`", start, position)
            else:
                let position: usize = self.current_start()
                children = push(children, data_cst_missing(new_span(position, position), "block 缺少 `end block`"))
                self.diagnose("template.parse.missing_end_block", "block 缺少 `end block`", start, position)
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeBlock, span, children)
    }

    # `super`：仅可出现在覆盖中的 block 内；裸标签（后不接受其他内容）。
    micro parse_super(mut self) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        if self._block_depth == 0 {
            self.diagnose("template.parse.super_outside_block", "`super` 只可用于覆盖中的 block", start, start)
        }
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        if !self.at_end() && !template_kind_is_code_close(self.current_kind()) {
            let error_start: usize = self.current_start()
            let mut leaves: [DataCstNode<TemplateTokenKind>] = []
            let mut consuming: bool = true
            while consuming && !self.at_end() {
                match self.current_kind() {
                    case CodeClose(payload):
                        consuming = false
                    else:
                        leaves = self.emit_leaf(leaves)
                }
            }
            let span: Span = self.span_of(leaves, error_start)
            self.diagnose("template.parse.unexpected_token", "`super` 后不接受其他内容", span.start, span.end)
            children = push(children, data_cst_poison(span, leaves, "unexpected tokens after super"))
        }
        children = self.close_tag(children, start)
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeSuper, span, children)
    }

    # `include <path> [with <expr>] [only | without context]`。
    micro parse_include(mut self, statement_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        # path 表达式（必填）。
        if !self.at_end() && !template_kind_is_code_close(self.current_kind()) {
            let path: DataCstNode<TemplateTokenKind> = self.parse_expression(statement_depth + 1)
            children = push(children, path)
        }
        else {
            let position: usize = self.current_start()
            if self.at_end() {
                children = push(children, data_cst_missing(new_span(position, position), "include 缺少路径表达式"))
                self.diagnose("template.parse.include_requires_path", "include 需要路径表达式", start, position)
            }
            else {
                children = push(children, data_cst_missing(new_span(position, position), "include 缺少路径表达式"))
                self.diagnose("template.parse.include_requires_path", "include 需要路径表达式", start, position)
            }
        }
        children = self.collect_trivia(children)
        # 上下文修饰：`with expr` / `only` / `without context`。
        let mut modifying: bool = true
        while modifying && !self.at_end() {
            match self.current_kind() {
                case KeywordWith:
                    children = self.emit_leaf(children)
                    children = self.collect_trivia(children)
                    if !self.at_end() && !template_kind_is_code_close(self.current_kind()) {
                        let with_expression: DataCstNode<TemplateTokenKind> = self.parse_expression(statement_depth + 1)
                        children = push(children, with_expression)
                    }
                    else {
                        let position: usize = self.current_start()
                        children = push(children, data_cst_missing(new_span(position, position), "`with` 缺少表达式"))
                        self.diagnose("template.parse.include_with_requires_expression", "`with` 需要上下文表达式", start, position)
                    }
                    children = self.collect_trivia(children)
                case KeywordOnly:
                    children = self.emit_leaf(children)
                    children = self.collect_trivia(children)
                    modifying = false
                case KeywordWithout:
                    children = self.emit_leaf(children)
                    children = self.collect_trivia(children)
                    if !self.at_end() {
                        match self.current_kind() {
                            case KeywordContext:
                                children = self.emit_leaf(children)
                            else:
                                let position: usize = self.current_start()
                                children = push(children, data_cst_missing(new_span(position, position), "`without` 需要 `context`"))
                                self.diagnose("template.parse.include_without_requires_context", "`without` 需要 `context`", start, position)
                        }
                    }
                    children = self.collect_trivia(children)
                    modifying = false
                else:
                    modifying = false
            }
        }
        # 修饰后只许闭标；多余内容挂 Poison。
        if !self.at_end() && !template_kind_is_code_close(self.current_kind()) {
            let error_start: usize = self.current_start()
            let mut leaves: [DataCstNode<TemplateTokenKind>] = []
            let mut consuming: bool = true
            while consuming && !self.at_end() {
                match self.current_kind() {
                    case CodeClose(payload):
                        consuming = false
                    else:
                        leaves = self.emit_leaf(leaves)
                }
            }
            let span: Span = self.span_of(leaves, error_start)
            self.diagnose("template.parse.trailing_input", "include 修饰后存在多余内容", span.start, span.end)
            children = push(children, data_cst_poison(span, leaves, "trailing input in include"))
        }
        children = self.close_tag(children, start)
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeInclude, span, children)
    }

    # `partial name, other = "x"` … `end partial`：只许模板顶层；参数至少一个、
    # 默认值只许字面量；partial body 是独立词法单元。
    micro parse_partial(mut self, statement_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        if statement_depth > 0 {
            self.diagnose("template.parse.partial_nested", "partial 只可用于模板顶层", start, start)
        }
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.parse_parameter_list(children, start, false)
        children = self.close_tag(children, start)
        let body: TemplateSequence = self.parse_sequence(statement_depth + 1, 0)
        let mut index: usize = 0
        while index < body.children.length() {
            children = push(children, body.children⁅index⁆.unwrap())
            index = index + 1
        }
        match body.stop {
            case StopEndPartial:
                self.check_closer_trim()
                children = self.consume_end_tag(children, "end partial")
            case StopEnd:
                let position: usize = self.end_position()
                children = push(children, data_cst_missing(new_span(position, position), "partial 缺少 `end partial`"))
                self.diagnose("template.parse.missing_end_partial", "partial 缺少 `end partial`", start, position)
            else:
                let position: usize = self.current_start()
                children = push(children, data_cst_missing(new_span(position, position), "partial 缺少 `end partial`"))
                self.diagnose("template.parse.missing_end_partial", "partial 缺少 `end partial`", start, position)
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodePartial, span, children)
    }

    # `macro name(a, b = "x")` … `end macro`：macro body 是独立词法单元。
    micro parse_macro(mut self, statement_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        # 名称。
        if !self.at_end() {
            match self.current_kind() {
                case Identifier:
                    children = self.emit_leaf(children)
                else:
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "macro 缺少名称"))
                    self.diagnose("template.parse.macro_requires_name", "macro 需要名称标识符", start, position)
            }
        }
        children = self.collect_trivia(children)
        # 参数必须写在括号内。
        if !self.at_end() && template_kind_is_paren_open(self.current_kind()) {
            children = self.emit_leaf(children)
            children = self.collect_trivia(children)
            children = self.parse_parameter_list(children, start, true)
            if !self.at_end() {
                match self.current_kind() {
                    case ParenClose:
                        children = self.emit_leaf(children)
                    else:
                        let position: usize = self.current_start()
                        children = push(children, data_cst_missing(new_span(position, position), "参数列表缺少 `)`"))
                        self.diagnose("template.parse.unclosed_expression", "macro 参数列表缺少 `)`", start, position)
                }
            }
            else {
                let position: usize = self.end_position()
                children = push(children, data_cst_missing(new_span(position, position), "参数列表缺少 `)`"))
                self.diagnose("template.parse.unclosed_expression", "macro 参数列表缺少 `)`", start, position)
            }
        }
        else {
            let position: usize = self.current_start()
            children = push(children, data_cst_missing(new_span(position, position), "macro 参数必须写在括号内"))
            self.diagnose("template.parse.macro_requires_parentheses", "macro 参数必须写在括号内", start, position)
        }
        children = self.close_tag(children, start)
        let body: TemplateSequence = self.parse_sequence(statement_depth + 1, 0)
        let mut index: usize = 0
        while index < body.children.length() {
            children = push(children, body.children⁅index⁆.unwrap())
            index = index + 1
        }
        match body.stop {
            case StopEndMacro:
                self.check_closer_trim()
                children = self.consume_end_tag(children, "end macro")
            case StopEnd:
                let position: usize = self.end_position()
                children = push(children, data_cst_missing(new_span(position, position), "macro 缺少 `end macro`"))
                self.diagnose("template.parse.missing_end_macro", "macro 缺少 `end macro`", start, position)
            else:
                let position: usize = self.current_start()
                children = push(children, data_cst_missing(new_span(position, position), "macro 缺少 `end macro`"))
                self.diagnose("template.parse.missing_end_macro", "macro 缺少 `end macro`", start, position)
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeMacro, span, children)
    }

    # `call [ (caller 参数) ] name(args)` … `end call`：caller 参数只许裸标识符、
    # 不允许默认值；caller 块体在调用方作用域渲染，是独立词法单元。
    micro parse_call(mut self, statement_depth: usize) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        # 可选 caller 参数括号。
        if !self.at_end() && template_kind_is_paren_open(self.current_kind()) {
            children = self.emit_leaf(children)
            children = self.collect_trivia(children)
            children = self.parse_caller_parameters(children, start)
            if !self.at_end() {
                match self.current_kind() {
                    case ParenClose:
                        children = self.emit_leaf(children)
                    else:
                        let position: usize = self.current_start()
                        children = push(children, data_cst_missing(new_span(position, position), "caller 参数缺少 `)`"))
                        self.diagnose("template.parse.unclosed_expression", "caller 参数缺少 `)`", start, position)
                }
            }
            children = self.collect_trivia(children)
        }
        # 宏调用表达式（`name(args)` 形由 builder 校验）。
        if !self.at_end() && !template_kind_is_code_close(self.current_kind()) {
            let callee: DataCstNode<TemplateTokenKind> = self.parse_expression(statement_depth + 1)
            children = push(children, callee)
        }
        else {
            let position: usize = self.current_start()
            children = push(children, data_cst_missing(new_span(position, position), "call 缺少宏调用"))
            self.diagnose("template.parse.call_requires_macro", "call 需要 `name(args)` 形的宏调用", start, position)
        }
        children = self.collect_trivia(children)
        # 多余内容挂 Poison。
        if !self.at_end() && !template_kind_is_code_close(self.current_kind()) {
            let error_start: usize = self.current_start()
            let mut leaves: [DataCstNode<TemplateTokenKind>] = []
            let mut consuming: bool = true
            while consuming && !self.at_end() {
                match self.current_kind() {
                    case CodeClose(payload):
                        consuming = false
                    else:
                        leaves = self.emit_leaf(leaves)
                }
            }
            let span: Span = self.span_of(leaves, error_start)
            self.diagnose("template.parse.trailing_input", "call 宏调用后存在多余内容", span.start, span.end)
            children = push(children, data_cst_poison(span, leaves, "trailing input in call"))
        }
        children = self.close_tag(children, start)
        let body: TemplateSequence = self.parse_sequence(statement_depth + 1, 0)
        let mut index: usize = 0
        while index < body.children.length() {
            children = push(children, body.children⁅index⁆.unwrap())
            index = index + 1
        }
        match body.stop {
            case StopEndCall:
                self.check_closer_trim()
                children = self.consume_end_tag(children, "end call")
            case StopEnd:
                let position: usize = self.end_position()
                children = push(children, data_cst_missing(new_span(position, position), "call 缺少 `end call`"))
                self.diagnose("template.parse.missing_end_call", "call 缺少 `end call`", start, position)
            else:
                let position: usize = self.current_start()
                children = push(children, data_cst_missing(new_span(position, position), "call 缺少 `end call`"))
                self.diagnose("template.parse.missing_end_call", "call 缺少 `end call`", start, position)
        }
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeCall, span, children)
    }

    # `from "path" import a, b as c`。
    micro parse_from(mut self) -> DataCstNode<TemplateTokenKind> {
        let mut children: [DataCstNode<TemplateTokenKind>] = []
        let start: usize = self.current_start()
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        children = self.emit_leaf(children)
        children = self.collect_trivia(children)
        # 路径字符串。
        if !self.at_end() {
            match self.current_kind() {
                case String:
                    children = self.emit_leaf(children)
                else:
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "`from` 需要字符串路径"))
                    self.diagnose("template.parse.from_requires_path", "`from` 需要字符串路径", start, position)
            }
        }
        children = self.collect_trivia(children)
        # `import`。
        if !self.at_end() {
            match self.current_kind() {
                case KeywordImport:
                    children = self.emit_leaf(children)
                else:
                    let position: usize = self.current_start()
                    children = push(children, data_cst_missing(new_span(position, position), "`from` 后需要 `import`"))
                    self.diagnose("template.parse.from_requires_import", "`from` 后需要 `import`", start, position)
            }
        }
        children = self.collect_trivia(children)
        # 导入名列表：ident [`as` ident] 逗号分隔。
        let mut expecting_name: bool = true
        let mut scanning: bool = true
        while scanning && !self.at_end() {
            match self.current_kind() {
                case Identifier:
                    children = self.emit_leaf(children)
                    expecting_name = false
                    children = self.collect_trivia(children)
                    # 可选 `as` 别名。
                    if !self.at_end() && template_kind_is_keyword_as(self.current_kind()) {
                        children = self.emit_leaf(children)
                        children = self.collect_trivia(children)
                        if !self.at_end() {
                            match self.current_kind() {
                                case Identifier:
                                    children = self.emit_leaf(children)
                                else:
                                    let position: usize = self.current_start()
                                    children = push(children, data_cst_missing(new_span(position, position), "`as` 需要本地名"))
                                    self.diagnose("template.parse.from_as_requires_name", "`as` 需要本地名", start, position)
                            }
                        }
                        children = self.collect_trivia(children)
                    }
                case Comma:
                    if expecting_name {
                        let position: usize = self.current_start()
                        self.diagnose("template.parse.from_requires_name", "导入名列表需要标识符", position, position)
                    }
                    expecting_name = true
                    children = self.emit_leaf(children)
                    children = self.collect_trivia(children)
                case CodeClose(payload):
                    if expecting_name {
                        let position: usize = self.current_start()
                        self.diagnose("template.parse.from_requires_name", "逗号后需要标识符", position, position)
                    }
                    scanning = false
                else:
                    let position: usize = self.current_start()
                    self.diagnose("template.parse.unexpected_token", "导入名列表中的意外内容", position, position)
                    children = self.emit_leaf(children)
                    children = self.collect_trivia(children)
            }
        }
        children = self.close_tag(children, start)
        let span: Span = self.span_of(children, start)
        return data_cst_node(NodeImport, span, children)
    }

    # 参数列表（partial 顶层与 macro 括号共用）：`name [= 字面量]` 逗号分隔；
    # 默认值只许单个字面量 token；重名与 `caller` 保留名的检查需词素，归 builder。
    micro parse_parameter_list(mut self, children: [DataCstNode<TemplateTokenKind>], start: usize, in_parentheses: bool) -> [DataCstNode<TemplateTokenKind>] {
        let mut result: [DataCstNode<TemplateTokenKind>] = children
        let mut count: usize = 0
        let mut scanning: bool = true
        while scanning && !self.at_end() {
            match self.current_kind() {
                case Identifier:
                    count = count + 1
                    result = self.emit_leaf(result)
                    result = self.collect_trivia(result)
                    # 可选默认值。
                    if !self.at_end() && template_kind_is_assign(self.current_kind()) {
                        result = self.emit_leaf(result)
                        result = self.collect_trivia(result)
                        if !self.at_end() && template_kind_is_literal_token(self.current_kind()) {
                            result = self.emit_leaf(result)
                        }
                        else {
                            let position: usize = self.current_start()
                            result = push(result, data_cst_missing(new_span(position, position), "默认值只许字面量"))
                            self.diagnose("template.parse.default_must_be_literal", "参数默认值只许字面量", start, position)
                        }
                        result = self.collect_trivia(result)
                    }
                case Comma:
                    result = self.emit_leaf(result)
                    result = self.collect_trivia(result)
                case CodeClose(payload):
                    scanning = false
                case ParenClose:
                    scanning = false
                else:
                    let position: usize = self.current_start()
                    self.diagnose("template.parse.unexpected_token", "参数列表中的意外内容", position, position)
                    result = self.emit_leaf(result)
                    result = self.collect_trivia(result)
            }
        }
        if count == 0 && !in_parentheses {
            self.diagnose("template.parse.partial_requires_parameter", "partial 至少需要一个参数", start, start)
        }
        return result
    }

    # caller 参数：只许裸标识符，逗号分隔；`=` 与 `caller` 名归 builder/诊断
    # （`=` 在语法段即拒绝，保留名检查需词素归 builder）。
    micro parse_caller_parameters(mut self, children: [DataCstNode<TemplateTokenKind>], start: usize) -> [DataCstNode<TemplateTokenKind>] {
        let mut result: [DataCstNode<TemplateTokenKind>] = children
        let mut scanning: bool = true
        while scanning && !self.at_end() {
            match self.current_kind() {
                case Identifier:
                    result = self.emit_leaf(result)
                    result = self.collect_trivia(result)
                case Comma:
                    result = self.emit_leaf(result)
                    result = self.collect_trivia(result)
                case Assign:
                    let position: usize = self.current_start()
                    self.diagnose("template.parse.caller_param_default", "caller 参数不允许默认值", position, position)
                    result = self.emit_leaf(result)
                    result = self.collect_trivia(result)
                case ParenClose:
                    scanning = false
                else:
                    let position: usize = self.current_start()
                    self.diagnose("template.parse.unexpected_token", "caller 参数只许裸标识符", position, position)
                    result = self.emit_leaf(result)
                    result = self.collect_trivia(result)
            }
        }
        return result
    }

# ── kind 谓词（可选结构的先行判定）──

micro template_kind_is_paren_open(kind: TemplateTokenKind) -> bool {
    match kind {
        case ParenOpen:
            return true
        else:
            return false
    }
}

micro template_kind_is_colon(kind: TemplateTokenKind) -> bool {
    match kind {
        case Colon:
            return true
        else:
            return false
    }
}

micro template_kind_is_code_close(kind: TemplateTokenKind) -> bool {
    match kind {
        case CodeClose(payload):
            return true
        else:
            return false
    }
}

micro template_kind_is_keyword_not(kind: TemplateTokenKind) -> bool {
    match kind {
        case KeywordNot:
            return true
        else:
            return false
    }
}

micro template_kind_is_comma(kind: TemplateTokenKind) -> bool {
    match kind {
        case Comma:
            return true
        else:
            return false
    }
}

micro template_kind_is_assign(kind: TemplateTokenKind) -> bool {
    match kind {
        case Assign:
            return true
        else:
            return false
    }
}

micro template_kind_is_keyword_as(kind: TemplateTokenKind) -> bool {
    match kind {
        case KeywordAs:
            return true
        else:
            return false
    }
}

# 参数默认值只许字面量 token。
micro template_kind_is_literal_token(kind: TemplateTokenKind) -> bool {
    match kind {
        case String:
            return true
        case Number:
            return true
        case LiteralTrue:
            return true
        case LiteralFalse:
            return true
        case LiteralNull:
            return true
        else:
            return false
    }
}

# 三段合同入口：语法段。
micro template_parse(tokens: [DataToken<TemplateTokenKind>], settings: DataSettings) -> DataOutcome<DataCstNode<TemplateTokenKind>> {
    let mut parser: TemplateParser = TemplateParser::new(tokens, settings.max_depth)
    let root: DataCstNode<TemplateTokenKind> = parser.parse_document()
    return data_outcome_partial(root, parser.diagnostics())
}
