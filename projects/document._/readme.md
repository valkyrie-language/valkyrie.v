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

- `document` / `document.layout` / `document.render`：`document.*` 核心（文档树、元数据、引用、资源、布局、渲染管线），骨架落位，按核心合同逐块开工
- `notedown`：文档语义 IR（Block / Inline / DocumentGraph / 校验）已入树，markdown → IR 链路待接 `std.data` 三段管线
- `panduck` / `pandark` / `vutex`：骨架落位（`legion.von` + 边界文档）

## 冻结声明（2026-11-02）

`document.*` 核心未立住之前，产品级一律冻结新功能：

- `notedown` 的 `source/ir/`（Block / Inline / DocumentGraph）与核心文档树语义重复，冻结新功能；
  核心落地后改挂核心模型并退役重复面，产品侧只做"解析进模型"一端
- `panduck` / `pandark` / `vutex`（tex 类产品位）全部冻结；tex 当前无代码，等核心稳定再迁
- 产品级解析器必须把结果映射进核心模型，不许各自造树、不许各自渲染

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
