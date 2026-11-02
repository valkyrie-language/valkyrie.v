namespace std.data;

# 三段独立 trait：lexer -> token stream、parser -> CST、builder -> AST。
#
# 错误容许合同（三段共同遵守）：
# - 不首错返回：输出总是携带部分结果与诊断集合（`DataOutcome<T>` 无 `Fail` 形态）。
# - 各阶段自己做恢复：lexer 对非法单元产 Illegal 类 token 并继续；
#   parser 按格式声明的同步点/安全边界跳到下一可恢复位置，被丢弃内容挂入
#   `Poison`（字节不丢），结构应有而源缺席处插入 `Missing`；
#   builder 对含 `Missing`/`Poison` 的子树如实映射，不擅自修补语义。
# - 严重程度只标注（`DataSeverity`），是否继续由后续阶段判断；
#   不得用 `corpusDefect` 式笼统类别掩盖具体诊断码。
#
# 绑定关系：
# - 三段各自声明关联类型，trait 层不做任何"必须相等"的约束。
# - 具体格式包实现时，习惯上把三段的 `Settings` 绑到同一具体类型（如 `MarkdownSettings`），
#   这是实现选择、不是合同；包内文档写清"本格式共用同一设置类型"即可。
# - CST 类型唯一来源是 `DataCstNode<Self::TokenKind>`：`Parser` 产出它、`Builder` 消费它，
#   只要两段 impl 绑定同一个 `TokenKind` 具体类型，CST 类型自然同一，无需跨 trait 约束。
# - 缓存只出现在真正有缓存需求的段（通常是 lexer，必要时 parser），不为对称给三段都塞。
#
# 非整数索引类型的设计核对（成立）：
# - CST 节点句柄：`DataCstNode<K>` 以不可变树承载，寻址即 `children` 数组下标（usize），
#   不需要额外句柄类型；
# - 文本偏移：`DataSpan` 的源单元在文本格式为字符下标（usize）、二进制格式为字节偏移
#   （usize），公共层不解释单位语义；
# - 字节级位置（含位级）由 `std.data.binary.codec` 的 `DataBitPosition` 承载，不进公共层。
# 结论：索引语义全部是 usize 的有序偏移，不存在需要非整数索引类型的场景。

# 词法段：源 -> token 流。token 不复制词素，按 span 从源切回（无损）。
# 恢复语义：非法源单元产出格式侧的 Illegal/Error 类 token 并继续扫描，
# 同时登记诊断；不得停在第一个非法单元，也不得静默吞掉它。
trait Lexer {
    type TokenKind;
    type Settings;
    type Cache;

    micro lex(self, source: DataSource, settings: Settings, cache: Cache) -> DataOutcome<[DataToken<TokenKind>]>
}

# 语法段：token 流 -> CST。CST 保全部 token 与容器层次（trivia 不丢、可回写），
# 不做语义裁剪。
# 恢复语义：按格式声明的同步点跳到安全边界，丢弃内容挂 `Poison`，
# 未闭合结构以 `Missing` 占位闭合；深度超限记 `Error` 诊断并对超深子树
# 挂 `Poison`，不得崩溃。
trait Parser {
    type TokenKind;
    type Settings;

    micro parse(self, tokens: [DataToken<TokenKind>], settings: Settings) -> DataOutcome<DataCstNode<TokenKind>>
}

# 语义段：CST -> AST。唯一允许做语法到语义结构映射的一层。
# 恢复语义：对 `Missing`/`Poison` 子树如实映射为 AST 侧的缺席/污染占位
# （或按格式定义降级），诊断透传并可补充；不得静默丢弃损坏子树。
trait Builder {
    type TokenKind;
    type Ast;
    type Settings;

    micro build(self, node: DataCstNode<TokenKind>, settings: Settings) -> DataOutcome<Ast>
}
