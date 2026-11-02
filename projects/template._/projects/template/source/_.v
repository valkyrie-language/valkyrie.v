namespace template;

using std.types::{Option};

# template — Valkyrie 模板语言核心包。
#
# 模板是文本格式：定界符外为文本，`<% %>` 内为代码（插值与语句共用），
# `<# #>` 为注释。解析严格走 std.data 三段合同：
#
#   template_lex(source, settings)          -> DataOutcome<[DataToken<TemplateTokenKind>]>
#   template_parse(tokens, settings)        -> DataOutcome<DataCstNode<TemplateTokenKind>>
#   template_build(cst, source, settings)   -> DataOutcome<TemplateDocument>
#
# 渲染为纯内存求值：template_render(document, context, settings) -> DataOutcome<utf8>。
# 词素不复制进 token，按 span 从源切回（无损）；三段各自错误容许，
# 产出永远携带部分结果与诊断集合（DataOutcome 无 Fail 形态）。
#
# 边界：本包不读文件、不访问网络、不取当前时间；loader、自定义定界符开放、
# date/slug 过滤器、继承与宏表面属后续块，见包 readme 的缺口登记。
