# std.data.text

`std.data` 文本格式的公共模型层：承载跨格式共享、但本身不含任何具体格式知识的文本语义结构。

## 当前内容

- **公共模板 AST 模型**（`source/ast.v`）：文本、注释、插值、条件、循环、break/continue、
  partial 槽（块占位）与缺席/污染占位节点；表达式以 arena 承载（`TemplateDocument.expressions`
  + `usize` 句柄，原因见下注）。`std.data.text.<dialect>` 各方言包的 builder 段统一产出本模型；
  方言确需独有节点时在公共模型上扩展，不各自 fork。

## 边界

- 本包只有数据模型，没有解析也没有渲染：lexer/parser/builder 三段归 `std.data.text.<dialect>`，
  渲染/求值归 `template.*` 渲染生态。
- 表达式 arena 的原因：V 侧已证实的递归 unite 形态只到"经数组递归"（`DataCstNode`/`VonValue`
  先例），直接递归 payload 在 CLR 自举侧被规避（`std.data.text.valkyrie` 的 flat term shell 注释）；
  arena 是确定、可序列化的等价承载，不是语义裁剪。若编译器后续支持直接递归 payload，
  本模型可整体迁回树形，接口由消费方同步升级。
