namespace std.data.text.dejavu;

using std.types::{Option};

# std.data.text.dejavu — dejavu 模板方言的三段实现。
#
# dejavu 是文本模板格式：定界符外为文本，`<% %>` 内为代码（插值与语句共用），
# `<# #>` 为注释。解析严格走 std.data 三段合同：
#
#   template_lex(source, settings)          -> DataOutcome<[DataToken<TemplateTokenKind>]>
#   template_parse(tokens, settings)        -> DataOutcome<DataCstNode<TemplateTokenKind>>
#   template_build(cst, source, settings)   -> DataOutcome<TemplateDocument>
#
# 词素不复制进 token，按 span 从源切回（无损）；三段各自错误容许，
# 产出永远携带部分结果与诊断集合（DataOutcome 无 Fail 形态）。
# builder 产物是 `std.data.text` 的公共模板 AST；渲染不在本包。
