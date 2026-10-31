# notedown._

`notedown._` 是文档处理与渲染框架 `notedown` 的顶层 workspace。

## 定位

- 文档语义 IR：文档图、关系、资产与校验
- 格式导入导出：Markdown / DOC / DOCX / EPUB / PDF / HTML
- 与 Rust 侧 `notedown` 栈同构，共享 `notedown-ir/v1` 线格式合同

## 下游

- `panduck`：文档转换编排
- `pandark` / `vutex`：渲染与消费侧产品

## 当前状态

规划中，先完成 workspace 与文档骨架。

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
