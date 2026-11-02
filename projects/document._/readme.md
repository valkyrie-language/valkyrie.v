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

- `notedown`：文档语义 IR（Block / Inline / DocumentGraph / 校验）已入树，markdown → IR 链路待接 `std.data` 三段管线
- `panduck` / `pandark` / `vutex`：骨架落位（`legion.von` + 边界文档），代码按各自 readme 的边界说明逐块开工

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
