namespace std.data.text.dejavu;

using std.data.text::{Binary, BreakNode, Call, CommentNode, ContinueNode, ExpressionMissing, ExpressionPoison, Identifier, IfNode, Index, InterpolationNode, LiteralFalse, LiteralNull, LiteralNumber, LiteralString, LiteralTrue, LoopNode, Member, MissingNode, ObjectLiteral, OpAdd, OpAnd, OpDivide, OpEqual, OpGreater, OpGreaterEqual, OpIdentity, OpIn, OpLess, OpLessEqual, OpMultiply, OpNegate, OpNot, OpNotEqual, OpOr, OpRemainder, OpSubtract, Pipe, PoisonNode, Test, TemplateBinaryOperator, TemplateDocument, TemplateExpression, TemplateIfBranch, TemplateNode, TemplateObjectEntry, TemplateUnaryOperator, TextNode, Unary};

using std.data::{DataCstNode, DataDiagnostic, DataOutcome, DataSettings, DataSource, DataSpan, Error, data_cst_span, data_outcome_with, new_data_diagnostic, new_data_span};

# 语义段：CST -> AST。唯一做语法到语义结构映射的一层。
#
# 词素按 token span 从源文本切回（无损），故本段显式持有源：
# `template_build(cst, source, settings)`。三段 trait 的 `build` 签名不带 source，
# 本包签名扩展见 readme。
#
# 恢复语义：CST 的 `Missing`/`Poison` 子树如实映射为 AST 的 `MissingNode`/`PoisonNode`
# （表达式侧为 `ExpressionMissing`/`ExpressionPoison`），不擅自修补语义；
# 诊断透传 parser 结果并可补充（本段补充 `template.build.duplicate_key`、
# `template.build.max_depth_exceeded`）。
#
# 字符串字面量只去引号，内容保持原样（反斜杠不展开——与既有模板合同一致：
# 反斜杠仅在词法阶段参与闭引号匹配）。

class TemplateBuilder {
    _text: utf8
    _expressions: [TemplateExpression]
    _diagnostics: [DataDiagnostic]
    _max_depth: usize
}

imply TemplateBuilder {
    micro new(text: utf8, max_depth: usize) -> Self {
        return TemplateBuilder {
            _text: text,
            _expressions: [],
            _diagnostics: [],
            _max_depth: max_depth
        }
    }

    micro diagnostics(self) -> [DataDiagnostic] {
        return self._diagnostics
    }

    micro expressions(self) -> [TemplateExpression] {
        return self._expressions
    }

    micro diagnose(mut self, code: utf8, message: utf8, span: DataSpan) -> unit {
        self._diagnostics = push(self._diagnostics, new_data_diagnostic(code, Error, message, span))
    }

    micro lexeme(self, span: DataSpan) -> utf8 {
        return self._text.slice(span.start, span.stop - span.start)
    }

    micro add_expression(mut self, expression: TemplateExpression) -> usize {
        self._expressions = push(self._expressions, expression)
        return self._expressions.length() - 1
    }

    # ── 文档与语句 ──

    micro build_document(mut self, root: DataCstNode<TemplateTokenKind>) -> TemplateDocument {
        let body: [TemplateNode] = self.build_children(root)
        return TemplateDocument { body: body, expressions: self._expressions }
    }

    # 子节点列表 -> 语句列表：Token 叶子按类映射，容器递归，trivia/定界跳过。
    micro build_children(mut self, node: DataCstNode<TemplateTokenKind>) -> [TemplateNode] {
        let mut nodes: [TemplateNode] = []
        if !template_cst_is_node(node) {
            return nodes
        }
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            let mapped: TemplateNode? = self.build_child(child)
            if mapped.is_some() {
                nodes = push(nodes, mapped.unwrap())
            }
            index = index + 1
        }
        return nodes
    }

    # 单个子节点映射；不产语句的（trivia/定界/trim 剥离段）返回 null。
    micro build_child(mut self, child: DataCstNode<TemplateTokenKind>) -> TemplateNode? {
        let leaf_kind: TemplateTokenKind? = template_cst_token_kind(child)
        if leaf_kind.is_some() {
            let kind: TemplateTokenKind = leaf_kind.unwrap()
            let span: DataSpan = data_cst_span(child)
            if kind == Text {
                return TextNode { text: self.lexeme(span) }
            }
            if kind == Comment {
                return CommentNode { text: self.lexeme(span) }
            }
            if kind == CodeEscape {
                return TextNode { text: "<%" }
            }
            return null
        }
        if template_cst_is_missing_node(child) {
            return MissingNode { reason: template_cst_missing_reason(child) }
        }
        if template_cst_is_poison_node(child) {
            return PoisonNode { reason: template_cst_poison_reason(child) }
        }
        let node_kind: TemplateTokenKind = template_cst_node_kind(child)
        if node_kind == NodeInterpolation {
            return self.build_interpolation(child)
        }
        if node_kind == NodeIf {
            return self.build_if(child)
        }
        if node_kind == NodeLoop {
            return self.build_loop(child)
        }
        if node_kind == NodeBreak {
            return BreakNode
        }
        if node_kind == NodeContinue {
            return ContinueNode
        }
        if node_kind == NodeUnsupported {
            return PoisonNode { reason: "unsupported statement surface" }
        }
        return null
    }

    # 插值：头区内首个表达式位子节点为表达式。
    micro build_interpolation(mut self, node: DataCstNode<TemplateTokenKind>) -> TemplateNode? {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if template_cst_is_expression_site(child) {
                let expression: usize = self.build_expression(child, 1)
                return InterpolationNode { expression: expression }
            }
            index = index + 1
        }
        # 结构性缺席：parser 必然已插入 Missing，此处兜底。
        let span: DataSpan = data_cst_span(node)
        self.diagnose("template.build.missing_expression", "插值缺少表达式子树", span)
        return InterpolationNode { expression: self.add_expression(ExpressionMissing { reason: "missing interpolation expression" }) }
    }

    # if：head 条件 + consequent + else if 链 + else。
    micro build_if(mut self, node: DataCstNode<TemplateTokenKind>) -> TemplateNode? {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut branches: [TemplateIfBranch] = []
        let mut alternate: [TemplateNode] = []
        # 阶段 1：head（到首个 CodeClose 叶子或 Missing 为止），取条件表达式。
        let mut test: usize = self.add_expression(ExpressionMissing { reason: "missing if condition" })
        let mut index: usize = 0
        let mut head_done: bool = false
        while index < children.length() && !head_done {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if template_cst_is_expression_site(child) {
                test = self.build_expression(child, 1)
            }
            if template_cst_is_head_end(child) {
                head_done = true
            }
            index = index + 1
        }
        # 阶段 2：consequent body 到首个 NodeElseIf/NodeElse/收尾段。
        let consequent: [TemplateNode] = self.build_body_segment(children, index)
        index = self.body_segment_stop(children, index)
        branches = push(branches, TemplateIfBranch { test: test, body: consequent })
        # 阶段 3：分支链。
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if !template_cst_is_token(child) {
                let child_kind: TemplateTokenKind = template_cst_node_kind(child)
                if child_kind == NodeElseIf {
                    let branch: TemplateIfBranch = self.build_elseif(child)
                    branches = push(branches, branch)
                }
                if child_kind == NodeElse {
                    alternate = self.build_else_body(child)
                }
            }
            index = index + 1
        }
        return IfNode { branches: branches, alternate: alternate }
    }

    micro build_elseif(mut self, node: DataCstNode<TemplateTokenKind>) -> TemplateIfBranch {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut test: usize = self.add_expression(ExpressionMissing { reason: "missing else-if condition" })
        let mut index: usize = 0
        let mut head_done: bool = false
        while index < children.length() && !head_done {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if template_cst_is_expression_site(child) {
                test = self.build_expression(child, 1)
            }
            if template_cst_is_head_end(child) {
                head_done = true
            }
            index = index + 1
        }
        let body: [TemplateNode] = self.build_body_segment(children, index)
        return TemplateIfBranch { test: test, body: body }
    }

    micro build_else_body(mut self, node: DataCstNode<TemplateTokenKind>) -> [TemplateNode] {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        # else 头：跳到 CodeClose/Missing 之后。
        let mut index: usize = 0
        let mut head_done: bool = false
        while index < children.length() && !head_done {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if template_cst_is_head_end(child) {
                head_done = true
            }
            index = index + 1
        }
        return self.build_body_segment(children, index)
    }

    # body 段：从 from 起到 end-tag（CodeOpen 叶子）或分支容器或 Missing/Poison 为止。
    micro build_body_segment(mut self, children: [DataCstNode<TemplateTokenKind>], from: usize) -> [TemplateNode] {
        let stop: usize = self.body_segment_stop(children, from)
        let mut nodes: [TemplateNode] = []
        let mut index: usize = from
        while index < stop {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            let mapped: TemplateNode? = self.build_child(child)
            if mapped.is_some() {
                nodes = push(nodes, mapped.unwrap())
            }
            index = index + 1
        }
        return nodes
    }

    micro body_segment_stop(self, children: [DataCstNode<TemplateTokenKind>], from: usize) -> usize {
        let mut index: usize = from
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if template_cst_is_missing_node(child) || template_cst_is_poison_node(child) {
                return index
            }
            let leaf_kind: TemplateTokenKind? = template_cst_token_kind(child)
            if leaf_kind.is_some() {
                if leaf_kind.unwrap() == CodeOpen {
                    return index
                }
            }
            else {
                let child_kind: TemplateTokenKind = template_cst_node_kind(child)
                if child_kind == NodeElseIf || child_kind == NodeElse {
                    return index
                }
            }
            index = index + 1
        }
        return children.length()
    }

    # loop：item 标识符 + iterable 表达式 + body。
    micro build_loop(mut self, node: DataCstNode<TemplateTokenKind>) -> TemplateNode? {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut item: utf8 = ""
        let mut iterable: usize = self.add_expression(ExpressionMissing { reason: "missing loop iterable" })
        # head：KeywordIn 之前的首个 Identifier 叶子为 item；之后的首个表达式位为 iterable。
        let mut seen_in: bool = false
        let mut head_done: bool = false
        let mut index: usize = 0
        while index < children.length() && !head_done {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            let leaf_kind: TemplateTokenKind? = template_cst_token_kind(child)
            if leaf_kind.is_some() {
                let kind: TemplateTokenKind = leaf_kind.unwrap()
                if kind == KeywordIn {
                    seen_in = true
                }
                if kind == Identifier && !seen_in && item.length() == 0 {
                    item = self.lexeme(data_cst_span(child))
                }
                if kind == CodeOpen {
                    head_done = true
                }
            }
            else {
                if template_cst_is_missing_node(child) || template_cst_is_poison_node(child) {
                    # Missing/Poison 不终止 head（item/in 缺失时已插占位）；仅缺闭标的
                    # Missing 才是 head 终点——其 reason 含"未闭合"。
                    let reason: utf8 = template_cst_missing_or_poison_reason(child)
                    if template_text_contains(reason, "未闭合") {
                        head_done = true
                    }
                }
                else {
                    if seen_in && template_cst_is_expression_site(child) {
                        iterable = self.build_expression(child, 1)
                    }
                }
            }
            index = index + 1
        }
        let body: [TemplateNode] = self.build_body_segment(children, index)
        return LoopNode { item: item, iterable: iterable, body: body }
    }

    # ── 表达式（CST 子树 -> arena 下标）──

    micro build_expression(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        if depth > self._max_depth {
            let span: DataSpan = data_cst_span(node)
            self.diagnose("template.build.max_depth_exceeded", "表达式嵌套深度超限", span)
            return self.add_expression(ExpressionPoison { reason: "max depth exceeded" })
        }
        let leaf_kind: TemplateTokenKind? = template_cst_token_kind(node)
        if leaf_kind.is_some() {
            return self.build_expression_leaf(leaf_kind.unwrap(), data_cst_span(node))
        }
        if template_cst_is_missing_node(node) {
            return self.add_expression(ExpressionMissing { reason: template_cst_missing_reason(node) })
        }
        if template_cst_is_poison_node(node) {
            return self.add_expression(ExpressionPoison { reason: template_cst_poison_reason(node) })
        }
        let kind: TemplateTokenKind = template_cst_node_kind(node)
        if kind == NodeExpressionBinary {
            return self.build_binary(node, depth)
        }
        if kind == NodeExpressionUnary {
            return self.build_unary(node, depth)
        }
        if kind == NodeExpressionPipe {
            return self.build_pipe(node, depth)
        }
        if kind == NodeExpressionTest {
            return self.build_test(node, depth)
        }
        if kind == NodeExpressionCall {
            return self.build_call(node, depth)
        }
        if kind == NodeExpressionMember {
            return self.build_member(node, depth)
        }
        if kind == NodeExpressionIndex {
            return self.build_index_access(node, depth)
        }
        if kind == NodeExpressionObject {
            return self.build_object(node, depth)
        }
        if kind == NodeExpressionGroup {
            return self.build_group(node, depth)
        }
        let span: DataSpan = data_cst_span(node)
        self.diagnose("template.build.unexpected_node", "表达式位出现非表达式节点", span)
        return self.add_expression(ExpressionPoison { reason: "unexpected node in expression" })
    }

    micro build_expression_leaf(mut self, kind: TemplateTokenKind, span: DataSpan) -> usize {
        if kind == String {
            return self.add_expression(LiteralString { value: self.unquote(span) })
        }
        if kind == Number {
            return self.add_expression(LiteralNumber { value: template_parse_number(self.lexeme(span)) })
        }
        if kind == LiteralTrue {
            return self.add_expression(LiteralTrue)
        }
        if kind == LiteralFalse {
            return self.add_expression(LiteralFalse)
        }
        if kind == LiteralNull {
            return self.add_expression(LiteralNull)
        }
        if kind == Identifier {
            return self.add_expression(Identifier { name: self.lexeme(span) })
        }
        if kind == Illegal {
            return self.add_expression(ExpressionPoison { reason: "illegal token" })
        }
        self.diagnose("template.build.unexpected_token", "表达式位的意外 token", span)
        return self.add_expression(ExpressionPoison { reason: "unexpected token in expression" })
    }

    # 去引号：首尾码点均为同一引号时去掉；未闭合（词法已诊断）只去首引号。
    micro unquote(self, span: DataSpan) -> utf8 {
        let text: utf8 = self.lexeme(span)
        let length: usize = text.length()
        if length < 2 {
            if length == 1 {
                return ""
            }
            return text
        }
        let first: char = text⁅0⁆
        let last: char = text⁅length - 1⁆
        if (first == '"' || first == '\'') && last == first {
            return text.slice(1, length - 2)
        }
        return text.slice(1, length - 1)
    }

    # 二元：children = [left, trivia..., operator 叶子, trivia..., right]。
    micro build_binary(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut operator: TemplateBinaryOperator = OpAdd
        let mut operator_found: bool = false
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            let leaf_kind: TemplateTokenKind? = template_cst_token_kind(child)
            if leaf_kind.is_some() {
                let mapped: TemplateBinaryOperator? = template_binary_operator_of(leaf_kind.unwrap())
                if mapped.is_some() {
                    operator = mapped.unwrap()
                    operator_found = true
                }
            }
            index = index + 1
        }
        let left: usize = self.build_expression(children⁅0⁆.unwrap(), depth + 1)
        let right: usize = self.build_expression(children⁅children.length() - 1⁆.unwrap(), depth + 1)
        if !operator_found {
            let span: DataSpan = data_cst_span(node)
            self.diagnose("template.build.missing_operator", "二元表达式缺少运算符", span)
        }
        return self.add_expression(Binary { operator: operator, left: left, right: right })
    }

    # 一元：children = [operator 叶子, trivia..., operand]。
    micro build_unary(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut operator: TemplateUnaryOperator = OpIdentity
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            let leaf_kind: TemplateTokenKind? = template_cst_token_kind(child)
            if leaf_kind.is_some() {
                let kind: TemplateTokenKind = leaf_kind.unwrap()
                if kind == Bang {
                    operator = OpNot
                }
                if kind == Minus {
                    operator = OpNegate
                }
                if kind == Plus {
                    operator = OpIdentity
                }
            }
            index = index + 1
        }
        let operand: usize = self.build_expression(children⁅children.length() - 1⁆.unwrap(), depth + 1)
        return self.add_expression(Unary { operator: operator, operand: operand })
    }

    # 管道：children = [expr, trivia, `|>`, trivia, 过滤器名叶子, 参数段...]。
    micro build_pipe(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let source_expression: usize = self.build_expression(children⁅0⁆.unwrap(), depth + 1)
        let mut filter: utf8 = ""
        let mut arguments: [usize] = []
        let mut seen_pipe: bool = false
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            let leaf_kind: TemplateTokenKind? = template_cst_token_kind(child)
            if leaf_kind.is_some() {
                let kind: TemplateTokenKind = leaf_kind.unwrap()
                if kind == Pipe {
                    seen_pipe = true
                }
                if kind == Identifier && seen_pipe && filter.length() == 0 {
                    filter = self.lexeme(data_cst_span(child))
                }
            }
            else {
                if seen_pipe && template_cst_is_expression_site(child) {
                    let argument: usize = self.build_expression(child, depth + 1)
                    arguments = push(arguments, argument)
                }
            }
            index = index + 1
        }
        if filter.length() == 0 {
            let span: DataSpan = data_cst_span(node)
            self.diagnose("template.build.missing_filter", "管道缺少过滤器名", span)
        }
        return self.add_expression(Pipe { expression: source_expression, filter: filter, arguments: arguments })
    }

    # 测试：children = [expr, trivia, `is`, trivia, `not`?, trivia, 测试名叶子, 参数段...]。
    micro build_test(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let source_expression: usize = self.build_expression(children⁅0⁆.unwrap(), depth + 1)
        let mut name: utf8 = ""
        let mut negated: bool = false
        let mut arguments: [usize] = []
        let mut seen_is: bool = false
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            let leaf_kind: TemplateTokenKind? = template_cst_token_kind(child)
            if leaf_kind.is_some() {
                let kind: TemplateTokenKind = leaf_kind.unwrap()
                if kind == KeywordIs {
                    seen_is = true
                }
                if kind == KeywordNot {
                    negated = true
                }
                if kind == Identifier && seen_is && name.length() == 0 {
                    name = self.lexeme(data_cst_span(child))
                }
                if kind == LiteralNull && seen_is && name.length() == 0 {
                    name = "null"
                }
            }
            else {
                if seen_is && template_cst_is_expression_site(child) {
                    let argument: usize = self.build_expression(child, depth + 1)
                    arguments = push(arguments, argument)
                }
            }
            index = index + 1
        }
        return self.add_expression(Test { expression: source_expression, name: name, arguments: arguments, negated: negated })
    }

    # 调用：children = [callee, trivia, `(`, 参数..., `)`]。
    micro build_call(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let callee: usize = self.build_expression(children⁅0⁆.unwrap(), depth + 1)
        let mut arguments: [usize] = []
        let mut index: usize = 1
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if template_cst_is_expression_site(child) {
                let argument: usize = self.build_expression(child, depth + 1)
                arguments = push(arguments, argument)
            }
            index = index + 1
        }
        return self.add_expression(Call { callee: callee, arguments: arguments })
    }

    # 成员：children = [object, trivia, `.`, trivia, 属性名叶子]。
    micro build_member(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let object: usize = self.build_expression(children⁅0⁆.unwrap(), depth + 1)
        let mut property: utf8 = ""
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            let leaf_kind: TemplateTokenKind? = template_cst_token_kind(child)
            if leaf_kind.is_some() {
                if leaf_kind.unwrap() == Identifier {
                    property = self.lexeme(data_cst_span(child))
                }
            }
            index = index + 1
        }
        return self.add_expression(Member { object: object, property: property })
    }

    # 下标：children = [object, trivia, `[`, index, `]`]。
    micro build_index_access(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let object: usize = self.build_expression(children⁅0⁆.unwrap(), depth + 1)
        let mut index_expression: usize = self.add_expression(ExpressionMissing { reason: "missing index expression" })
        let mut index: usize = 1
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if template_cst_is_expression_site(child) {
                index_expression = self.build_expression(child, depth + 1)
            }
            index = index + 1
        }
        return self.add_expression(Index { object: object, index: index_expression })
    }

    # 分组：children = [`(`, inner, `)`]；分组对语义透明。
    micro build_group(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if template_cst_is_expression_site(child) {
                return self.build_expression(child, depth + 1)
            }
            index = index + 1
        }
        return self.add_expression(ExpressionMissing { reason: "empty group" })
    }

    # 对象字面量：entries 为 NodeExpressionObjectEntry 容器；key 唯一性在此检查
    # （词素只在本段可用），重复 key 产 `template.build.duplicate_key`。
    micro build_object(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> usize {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut entries: [TemplateObjectEntry] = []
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            if !template_cst_is_token(child) && template_cst_node_kind(child) == NodeExpressionObjectEntry {
                let entry: TemplateObjectEntry = self.build_object_entry(child, depth)
                let mut duplicate: bool = false
                let mut existing: usize = 0
                while existing < entries.length() {
                    if entries⁅existing⁆.unwrap().key == entry.key {
                        duplicate = true
                    }
                    existing = existing + 1
                }
                if duplicate {
                    self.diagnose("template.build.duplicate_key", "对象字面量键重复", data_cst_span(child))
                }
                entries = push(entries, entry)
            }
            index = index + 1
        }
        return self.add_expression(ObjectLiteral { entries: entries })
    }

    # 对象条目：children = [key 叶子, trivia, `:`, trivia, value]。
    micro build_object_entry(mut self, node: DataCstNode<TemplateTokenKind>, depth: usize) -> TemplateObjectEntry {
        let children: [DataCstNode<TemplateTokenKind>] = template_cst_children(node)
        let mut key: utf8 = ""
        let mut value: usize = self.add_expression(ExpressionMissing { reason: "missing object value" })
        let mut index: usize = 0
        while index < children.length() {
            let child: DataCstNode<TemplateTokenKind> = children⁅index⁆.unwrap()
            let leaf_kind: TemplateTokenKind? = template_cst_token_kind(child)
            if leaf_kind.is_some() {
                let kind: TemplateTokenKind = leaf_kind.unwrap()
                if kind == Identifier && key.length() == 0 {
                    key = self.lexeme(data_cst_span(child))
                }
                if kind == String && key.length() == 0 {
                    key = self.unquote(data_cst_span(child))
                }
            }
            else {
                if template_cst_is_expression_site(child) {
                    value = self.build_expression(child, depth + 1)
                }
            }
            index = index + 1
        }
        return TemplateObjectEntry { key: key, value: value }
    }
}

# ── CST 形状辅助 ──

micro template_cst_is_token(node: DataCstNode<TemplateTokenKind>) -> bool {
    match node {
        case Token(payload):
            return true
        else:
            return false
    }
}

micro template_cst_is_node(node: DataCstNode<TemplateTokenKind>) -> bool {
    match node {
        case Node(payload):
            return true
        else:
            return false
    }
}

micro template_cst_token_kind(node: DataCstNode<TemplateTokenKind>) -> TemplateTokenKind? {
    match node {
        case Token(payload):
            return payload.token.kind
        else:
            return null
    }
}

# 容器节点的 kind（非容器返回非法哨兵 `Illegal`，调用点只在已知容器时取值）。
micro template_cst_node_kind(node: DataCstNode<TemplateTokenKind>) -> TemplateTokenKind {
    match node {
        case Node(payload):
            return payload.kind
        else:
            return Illegal
    }
}

micro template_cst_children(node: DataCstNode<TemplateTokenKind>) -> [DataCstNode<TemplateTokenKind>] {
    match node {
        case Node(payload):
            return payload.children
        else:
            let empty: [DataCstNode<TemplateTokenKind>] = []
            return empty
    }
}

micro template_cst_is_missing_node(node: DataCstNode<TemplateTokenKind>) -> bool {
    match node {
        case Missing(payload):
            return true
        else:
            return false
    }
}

micro template_cst_is_poison_node(node: DataCstNode<TemplateTokenKind>) -> bool {
    match node {
        case Poison(payload):
            return true
        else:
            return false
    }
}

micro template_cst_missing_reason(node: DataCstNode<TemplateTokenKind>) -> utf8 {
    match node {
        case Missing(payload):
            return payload.reason
        else:
            return ""
    }
}

micro template_cst_poison_reason(node: DataCstNode<TemplateTokenKind>) -> utf8 {
    match node {
        case Poison(payload):
            return payload.reason
        else:
            return ""
    }
}

micro template_cst_missing_or_poison_reason(node: DataCstNode<TemplateTokenKind>) -> utf8 {
    if template_cst_is_missing_node(node) {
        return template_cst_missing_reason(node)
    }
    return template_cst_poison_reason(node)
}

# head 终点判定：CodeClose 叶子或任何 Missing（缺闭标/缺条件等占位）。
micro template_cst_is_head_end(node: DataCstNode<TemplateTokenKind>) -> bool {
    let leaf_kind: TemplateTokenKind? = template_cst_token_kind(node)
    if leaf_kind.is_some() {
        return leaf_kind.unwrap() == CodeClose
    }
    return template_cst_is_missing_node(node)
}

# 子串包含（builder 内部判定用，避免依赖 `Utf8Text.contains` 的方法分派歧义）。
micro template_text_contains(text: utf8, needle: utf8) -> bool {
    if needle.length() == 0 {
        return true
    }
    if text.length() < needle.length() {
        return false
    }
    let mut index: usize = 0
    while index + needle.length() <= text.length() {
        if text.slice(index, needle.length()) == needle {
            return true
        }
        index = index + 1
    }
    return false
}

# 表达式位判定：非 trivia、非定界/关键字叶子的子树（表达式节点、字面量/标识符叶子、
# Missing/Poison 占位）都是表达式位。
micro template_cst_is_expression_site(node: DataCstNode<TemplateTokenKind>) -> bool {
    let leaf_kind: TemplateTokenKind? = template_cst_token_kind(node)
    if leaf_kind.is_some() {
        let kind: TemplateTokenKind = leaf_kind.unwrap()
        if kind == String || kind == Number || kind == LiteralTrue || kind == LiteralFalse {
            return true
        }
        if kind == LiteralNull || kind == Identifier || kind == Illegal {
            return true
        }
        return false
    }
    if template_cst_is_missing_node(node) || template_cst_is_poison_node(node) {
        return true
    }
    let kind: TemplateTokenKind = template_cst_node_kind(node)
    if kind == NodeExpressionBinary || kind == NodeExpressionUnary || kind == NodeExpressionPipe {
        return true
    }
    if kind == NodeExpressionTest || kind == NodeExpressionCall || kind == NodeExpressionMember {
        return true
    }
    if kind == NodeExpressionIndex || kind == NodeExpressionObject || kind == NodeExpressionGroup {
        return true
    }
    return false
}

# 运算符叶子 -> AST 运算符。
micro template_binary_operator_of(kind: TemplateTokenKind) -> TemplateBinaryOperator? {
    if kind == EqualEqual {
        return OpEqual
    }
    if kind == BangEqual {
        return OpNotEqual
    }
    if kind == Less {
        return OpLess
    }
    if kind == LessEqual {
        return OpLessEqual
    }
    if kind == Greater {
        return OpGreater
    }
    if kind == GreaterEqual {
        return OpGreaterEqual
    }
    if kind == And {
        return OpAnd
    }
    if kind == Or {
        return OpOr
    }
    if kind == KeywordIn {
        return OpIn
    }
    if kind == Plus {
        return OpAdd
    }
    if kind == Minus {
        return OpSubtract
    }
    if kind == Star {
        return OpMultiply
    }
    if kind == Slash {
        return OpDivide
    }
    if kind == Percent {
        return OpRemainder
    }
    return null
}

# 三段合同入口：语义段（签名扩展：显式携带源文本）。
micro template_build(node: DataCstNode<TemplateTokenKind>, source: DataSource, settings: DataSettings) -> DataOutcome<TemplateDocument> {
    match source {
        case Text(payload):
            let mut builder: TemplateBuilder = TemplateBuilder::new(payload.text, settings.max_depth)
            let document: TemplateDocument = builder.build_document(node)
            return data_outcome_with(document, builder.diagnostics())
        case Bytes(payload):
            let mut diagnostics: [DataDiagnostic] = []
            diagnostics = push(diagnostics, new_data_diagnostic("template.build.binary_source", Error, "模板是文本格式，不接受字节源", new_data_span(0, 0)))
            let empty: TemplateDocument = TemplateDocument { body: [], expressions: [] }
            return data_outcome_with(empty, diagnostics)
    }
}
