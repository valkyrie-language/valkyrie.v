# document._

`document._` 是文档处理与渲染框架 `notedown` 的顶层 workspace。

## 定位

- 文档语义 IR：文档图、关系、资产与校验
- 格式导入导出：Markdown / DOC / DOCX / EPUB / PDF / HTML
- 文档语义 IR 与其线格式合同由本仓设计与维护

## 下游

- `panduck`：文档转换编排
- `pandark` / `vutex`：渲染与消费侧产品

## 当前状态

- `document`：核心模型（Block/Inline、元数据、引用、资源）+ `document_validate` + 编号/TOC pass 已落地
- `document.layout`：盒模型内核（度量/基线/断行/拍平/缩放）+ `paginate` 页面层已落地
- `document.render`：HTML / 纯文本 / Markdown 三目标渲染管线已落地
- `document.vector`：SVG 矢量文本发射原语已落地
- `document.plotter`：flowchart / sequence 布局与 SVG 发射已落地
- `document.mermaid`：mermaid 子集（flowchart、sequence）解析已落地
- `vutex`：TeX 数学子集（`\frac`/`\sqrt`/上下标/希腊字母/运算符）→ 盒 → SVG 已落地
- `notedown`：文档语义 IR（Block / Inline / DocumentGraph / 校验）已入树，markdown → IR 链路待接 `std.data` 三段管线
- `panduck` / `pandark`：骨架落位（`legion.von` + 边界文档）

## 边界约束

- `notedown` 的 `source/ir/`（Block / Inline / DocumentGraph）与核心文档树语义重复；
  核心模型落地后改挂核心并退役重复面，产品侧只做"解析进模型"一端
- `panduck` / `pandark`（转换编排与页面抽取产品位）在核心模型稳定前不扩展新功能；`vutex` 数学子集排版已先行落地
- 产品级解析器必须把结果映射进核心模型，不许各自造树、不许各自渲染

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)；设计文档：[核心合同](documentation/pages/zh-hans/core-contract.md)、[conformance 用例表](documentation/pages/zh-hans/conformance-matrix.md)、[notedown 迁移映射](documentation/pages/zh-hans/notedown-migration.md)
