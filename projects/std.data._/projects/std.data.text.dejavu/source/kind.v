namespace std.data.text.dejavu;

# 空白控制级别（单侧可剥离宽度阶梯）。
# marker 拼写：`none` 无 marker，`ws` ↔ `_`，`nl` ↔ `-`，`ws_nl` ↔ `~`，`all` ↔ `=`。
unite TemplateTrim {
    TrimNone
    TrimWhitespace
    TrimNewline
    TrimWhitespaceNewline
    TrimAll
}

# 词法与 CST 节点类同一 unite：三段合同要求 parser 产出的
# `DataCstNode<TemplateTokenKind>` 与 lexer 的 token 共用一个 kind 类型。
# 分两段登记：前半为 token 类，后半（Node*）为 CST 容器类。
#
# 词素不复制进 kind（`Identifier`/`Number`/`String`/`Text` 均为无负载变体），
# 消费方按 token span 从源文本切回；字符串 span 含引号，去引号在 builder 完成。
[tag(TemplateTokenKindTag)]
unite TemplateTokenKind {
    # ── 文本区 token ──
    # 定界符外的模板文本。
    Text
    # 被 trim marker 剥离的空白（保留在流中，保证 token 流无损覆盖源）。
    Trimmed
    # 整个注释 `<# ... #>`（含定界符）；渲染忽略。
    Comment
    # `<%!` 转义形式，渲染输出字面 `<%`。
    CodeEscape

    # ── 定界 token ──
    [constructor]
    CodeOpen { trim: TemplateTrim }
    [constructor]
    CodeClose { trim: TemplateTrim }

    # ── 代码区 token ──
    # 代码区内的空白（trivia，保留不丢）。
    CodeWhitespace
    Identifier
    Number
    String

    # 字面量关键字。
    LiteralTrue
    LiteralFalse
    LiteralNull

    # 语句与修饰关键字。语句关键字在表达式位置出现即语法错误。
    KeywordIf
    KeywordElse
    KeywordEnd
    KeywordLoop
    KeywordIn
    KeywordBreak
    KeywordContinue
    KeywordIs
    KeywordNot
    KeywordExtends
    KeywordBlock
    KeywordSuper
    KeywordInclude
    KeywordWith
    KeywordOnly
    KeywordWithout
    KeywordContext
    KeywordPartial
    KeywordMacro
    KeywordCall
    KeywordFrom
    KeywordImport
    KeywordAs

    # 运算符与标点。`Pipe` 仅指 `|>`；单独的 `|` 不是管道，归入 Illegal。
    Pipe
    Or
    And
    EqualEqual
    BangEqual
    LessEqual
    GreaterEqual
    Less
    Greater
    Plus
    Minus
    Star
    Slash
    Percent
    Bang
    Dot
    Comma
    Assign
    ParenOpen
    ParenClose
    BracketOpen
    BracketClose
    BraceOpen
    BraceClose
    Colon

    # 非法码位单元（词法恢复：产出后继续扫描）。
    Illegal

    # ── CST 容器节点类 ──
    NodeRoot
    NodeInterpolation
    NodeIf
    NodeElseIf
    NodeElse
    NodeLoop
    NodeBreak
    NodeContinue
    NodeExtends
    NodeBlock
    NodeSuper
    NodeInclude
    NodePartial
    NodeMacro
    NodeCall
    NodeImport
    # 保留的恢复容器：分类失败或不属于任何语句形的标签内容。
    NodeUnsupported
    NodeExpressionBinary
    NodeExpressionUnary
    NodeExpressionPipe
    NodeExpressionTest
    NodeExpressionCall
    NodeExpressionMember
    NodeExpressionIndex
    NodeExpressionObject
    NodeExpressionObjectEntry
    NodeExpressionGroup
}

# 带负载变体的谓词（unite 相等比较只适用于无负载变体）。
micro template_kind_is_code_open(kind: TemplateTokenKind) -> bool {
    match kind {
        case CodeOpen(payload):
            return true
        else:
            return false
    }
}
