namespace std.data.text.tex;

# 词法与 CST 节点类同一 unite（三段合同：`DataCstNode<TexTokenKind>` 与
# token 共用一个 kind 类型）。前半 token 类，后半 `Node*` 为 CST 容器类。
# 词素不复制进 kind，按 span 从源切回；span 单位是码点偏移（半开区间）。
[tag(TexTokenKindTag)]
unite TexTokenKind {
    # ── token 类 ──
    # 字母/数字/运算符单字符。
    Symbol
    # 结构命令（词法段按命令名分流，parser 不看词素）。
    FracCommand
    SqrtCommand
    # 其余 `\` + 连续 ASCII 字母（span 含 `\`；语义归 builder）。
    Command
    OpenBrace
    CloseBrace
    Sup
    Sub
    # 空白 trivia（保留在流中，token 流无损覆盖源）。
    Space
    # 非法单元（span 保留原文）。
    Illegal

    # ── CST 容器类 ──
    NodeRoot
    NodeRow
    NodeGroup
    NodeFrac
    NodeSqrt
    NodeScripts
    NodeAtom
}
