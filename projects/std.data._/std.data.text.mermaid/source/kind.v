namespace std.data.text.mermaid;

# 词法与 CST 节点类同一 unite。前半 token 类，后半 `Node*` 为 CST 容器类。
# 词素不复制进 kind，按 span 从源切回；span 单位是码点偏移（半开区间）。
[tag(MermaidTokenKindTag)]
unite MermaidTokenKind {
    # ── token 类 ──
    # 标识符与标签文字片段（非特殊字符的连续 run；标签由 parser 按上下文拼接）。
    Text
    # 空白 trivia。
    Space
    Newline
    # `-->`（flowchart 边）。
    Arrow
    # `->>`（sequence 消息）。
    SeqArrow
    Pipe
    LBracket
    RBracket
    Colon
    # 形状与双向边：圆角 `(...)`、菱形 `{...}`、运动 `<-->`。
    LParen
    RParen
    LBrace
    RBrace
    BiArrow
    # `%`（注释引导，`%%` 由 parser 判定）。
    Percent
    # 孤立 `-`/`>` 等未成形结构字符。
    Illegal

    # ── CST 容器类 ──
    NodeDiagram
    NodeHeader
    NodeStatement
    NodeComment
}
