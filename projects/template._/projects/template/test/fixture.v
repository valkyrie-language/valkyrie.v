namespace template;

using std.diagnostic::{Diagnostic, diagnostic_code};
using std.data::{DataOutcome, data_outcome_diagnostics, data_outcome_value_or};
using std.data.text::{BlockNode, Call, ExtendsNode, Identifier, ImportNode, IncludeNode, InterpolationNode, LiteralNumber, LiteralString, MacroNode, ObjectLiteral, PartialNode, SuperNode, TemplateDocument, TemplateExpression, TemplateImportName, TemplateNode, TemplateObjectEntry, TemplateParameter, TextNode};

# 全链路样例：多文件模板（extends + block + super + include + partial + macro +
# import）渲染为 HTML。装配期把五个文档的表达式 arena 按条目偏移合并成
# 一个，任一文档的句柄重映射错位都会直接改变输出文本——本样例即探针。
#
# 目录（每文档表达式 arena 均非空者才有偏移意义，base 为空 arena 作对照）：
#   forms  宏 input(name)；card  partial title, level = 2；item  片段；
#   base   骨架（空 arena）；page  extends base + import forms + 三块包含。

[test]
micro test_fixture_full_chain_renders_html() -> unit {
    let forms: TemplateCatalogEntry = catalog_entry("forms", [
        MacroNode { name: "input", parameters: [TemplateParameter { name: "name", default: null }], body: [literal_text_node("<input name="), interpolation(0), literal_text_node(">")] }
    ], [identifier("name")])
    let card: TemplateCatalogEntry = catalog_entry("card", [
        PartialNode {
            parameters: [TemplateParameter { name: "title", default: null }, TemplateParameter { name: "level", default: 1 }],
            body: [literal_text_node("<section><h2>"), interpolation(0), literal_text_node("</h2><p>lv"), interpolation(1), literal_text_node("</p></section>")]
        }
    ], [identifier("title"), literal_number(2.0)])
    let item: TemplateCatalogEntry = catalog_entry("item", [
        literal_text_node("<li>"), interpolation(0), literal_text_node("</li>")
    ], [identifier("item_name")])
    let base: TemplateCatalogEntry = catalog_entry("base", [
        literal_text_node("<html><body>"),
        BlockNode { name: "content", body: [literal_text_node("BASE")] },
        literal_text_node("</body></html>")
    ], [])
    let page: TemplateCatalogEntry = catalog_entry("page", [
        ImportNode { path: 0, names: [TemplateImportName { name: "input", alias: "text_input" }] },
        ExtendsNode { parent: 1 },
        BlockNode { name: "content", body: [
            literal_text_node("page>"),
            SuperNode,
            literal_text_node("|"),
            IncludeNode { path: 2, with_expression: null, only: false },
            literal_text_node("|"),
            IncludeNode { path: 3, with_expression: 4, only: true },
            literal_text_node("|"),
            interpolation(6)
        ] }
    ], [
        literal_string("forms"),
        literal_string("base"),
        literal_string("item"),
        literal_string("card"),
        ObjectLiteral { entries: [TemplateObjectEntry { key: "title", value: 5 }] },
        literal_string("CARD"),
        Call { callee: 7, arguments: [8] },
        identifier("text_input"),
        literal_string("email")
    ])
    let catalog: TemplateCatalog = catalog_of([forms, card, item, base, page])
    let context: TemplateValue = template_object([template_field("item_name", template_text("ITEM"))])
    let expected: utf8 = "<html><body>page>BASE|<li>ITEM</li>|<section><h2>CARD</h2><p>lv2</p></section>|<input name=email></body></html>"
    if render_catalog_ok("page", catalog, context) != expected {
        panic("full-chain fixture output mismatch")
    }
}
