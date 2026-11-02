namespace template;

# 语义 AST：builder 段的产物，渲染段的输入。
#
# 表达式树以平坦 arena 承载：`TemplateDocument.expressions` 为节点数组，
# 节点内的子引用为数组下标（usize 句柄）。不经数组的直接递归 unite payload
# 在 V 侧 CLR 自举不可用（`std.data.text.valkyrie` 的 flat term shell 注释），
# arena 是确定、可序列化的等价承载。语句树经数组递归（`DataCstNode`/`VonValue` 先例）。

unite TemplateBinaryOperator {
    OpEqual
    OpNotEqual
    OpLess
    OpLessEqual
    OpGreater
    OpGreaterEqual
    OpAnd
    OpOr
    OpIn
    OpAdd
    OpSubtract
    OpMultiply
    OpDivide
    OpRemainder
}

unite TemplateUnaryOperator {
    OpNot
    OpNegate
    OpIdentity
}

[tag(TemplateExpressionTag)]
unite TemplateExpression {
    LiteralNull
    LiteralTrue
    LiteralFalse
    [constructor]
    LiteralNumber { value: f64 }
    [constructor]
    LiteralString { value: utf8 }
    [constructor]
    Identifier { name: utf8 }
    # 对象字面量：key 有序、唯一（重复 key 在 parser 即诊断）。
    [constructor]
    ObjectLiteral { entries: [TemplateObjectEntry] }
    [constructor]
    Member { object: usize, property: utf8 }
    [constructor]
    Index { object: usize, index: usize }
    # 调用：语义上 callee 必须解析为 Identifier（裸标识符），成员调用在渲染段拒绝。
    [constructor]
    Call { callee: usize, arguments: [usize] }
    [constructor]
    Binary { operator: TemplateBinaryOperator, left: usize, right: usize }
    [constructor]
    Unary { operator: TemplateUnaryOperator, operand: usize }
    [constructor]
    Pipe { expression: usize, filter: utf8, arguments: [usize] }
    [constructor]
    Test { expression: usize, name: utf8, arguments: [usize], negated: bool }
    # builder 对 CST `Missing`/`Poison` 的如实映射：语义缺席/污染占位，不修补。
    [constructor]
    ExpressionMissing { reason: utf8 }
    [constructor]
    ExpressionPoison { reason: utf8 }
}

structure TemplateObjectEntry {
    key: utf8
    value: usize
}

[tag(TemplateNodeTag)]
unite TemplateNode {
    # 模板文本（trim 已应用）；`<%!` 转义形式在本变体以字面 `<%` 进入。
    [constructor]
    TextNode { text: utf8 }
    # 注释体（含定界符的原文）；渲染忽略。
    [constructor]
    CommentNode { text: utf8 }
    # 插值：渲染表达式为字符串，默认 HTML 转义。
    [constructor]
    InterpolationNode { expression: usize }
    [constructor]
    IfNode { branches: [TemplateIfBranch], alternate: [TemplateNode] }
    [constructor]
    LoopNode { item: utf8, iterable: usize, body: [TemplateNode] }
    BreakNode
    ContinueNode
    # builder 对 CST `Missing`/`Poison` 的如实映射。
    [constructor]
    MissingNode { reason: utf8 }
    [constructor]
    PoisonNode { reason: utf8 }
}

structure TemplateIfBranch {
    test: usize
    body: [TemplateNode]
}

structure TemplateDocument {
    body: [TemplateNode]
    expressions: [TemplateExpression]
}
