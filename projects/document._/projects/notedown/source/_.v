namespace notedown;

# notedown — 文档语义 IR（Valkyrie 实现）
#
# IR 表达文档语义而非解析器语法：链接的目标与显示内容分离，
# block 通过稳定 NodeId 在 DocumentGraph 中寻址。
#
# Markdown 解析本体归 std.data.*（lexer/CST/parser/builder/AST），
# notedown 作为消费方把 std.data AST 映射为本文档 IR。
