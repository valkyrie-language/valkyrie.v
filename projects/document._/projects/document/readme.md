# document

`document.*` 核心：文档树、元数据、引用系统、资源与失败模型（纯模型，无 IO）。

## 定位

- block/inline 树：标题、段落、列表（有序/无序/嵌套）、表格、代码块、引用块、脚注、分隔线、图片；
  每个节点带 id/class/属性
- 元数据：title/author/date/labels/front matter，与正文分离
- 引用系统：章节与脚注自动编号、交叉引用、TOC、参考文献（bib 条目 + 引用键）
- 资源：图片/字体/附件的身份、去重、相对路径与 base 解析（纯函数；读文件/网络是 host capability，不进本包）
- 失败模型：模型校验 + 结构化 `DocumentError`；渲染/布局侧硬失败走错误通道，
  解析侧（产品包）走 `std.data` 的错误容许三态

## 边界

- 不拥有格式解析：归 `std.data.*` 与产品包（notedown / tex 等）
- 不拥有渲染目标实现与布局：归 `document.render` / `document.layout`
- 产品级解析器必须把结果映射进本模型，不得各自造树

## 当前状态

骨架落位，模型按核心合同逐块开工。
