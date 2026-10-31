# notedown 文档处理与渲染框架 workspace

`notedown._` 承载文档语义 IR 与格式导入导出能力，是 `panduck` / `pandark` / `vutex` 等下游产品的事实底座。

## 核心分层

- **IR**：文档图、关系、资产；线格式合同 `notedown-ir/v1`
- **Formats**：Markdown / DOC / DOCX / EPUB / PDF / HTML 导入导出
- **下游编排**：`panduck` 负责转换编排，渲染与消费侧由 `pandark` / `vutex` 承接

## 边界约束

- notedown 只拥有文档语义 IR 与格式合同，不做排版引擎，也不下沉为具体产品 glue
- 与 Rust 侧 `notedown` 栈同构建设：V 侧与 Rust 侧消费同一 IR/格式合同，不得另立平行事实
