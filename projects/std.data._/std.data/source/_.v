namespace std.data;

using std.types::{Option};

# std.data — 格式无关的公共抽象层。
#
# 本包只承载"所有格式都成立"的约定：输入源（文本/字节）、设置、缓存、
# 三段产物形态（lexer -> token stream、parser -> CST、builder -> AST）与错误结构。
# 任何具体格式的知识（换行/注释规则、字节序、对齐、容器结构）一律不许进入本包：
# 文本特有的落在 `std.data.text.<format>`，二进制特有的落在 `std.data.binary.<format>`，
# 字节编解码能力（大小端读写、LEB128、bit 读取）落在 `std.data.binary.codec`。
#
# 三层接口为签名约定（V 无 trait 对象），各格式包按统一签名导出入口：
#   <format>_lex(source, settings, cache)   -> DataOutcome<[DataToken<K>]>
#   <format>_parse(tokens, settings, cache) -> DataOutcome<DataCstNode<K>>
#   <format>_build(cst, settings)           -> DataOutcome<A>
# 其中 K 是格式自己的 token/CST kind（`unite`），A 是格式自己的 AST root。
