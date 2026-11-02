# document.render

`document.*` 核心渲染管线：document tree → layout → 输出目标，输出侧可插拔。

## 定位

- 渲染管线：编号/引用 pass → 目标发射；目标以 trait 接入，不写死单一输出
- 内置目标：HTML、纯文本；打印向走 `document.layout` 分页后的文本页
- 硬失败：违例输入返回结构化 `DocumentError`，不 panic、不产半成品

## 边界

- 不拥有文档树与引用编号：归 `document`
- 不拥有页面测量与断页：归 `document.layout`
- HTML 之外的网页集成（asgard/ssg）是下游消费者，不进本包

## 当前状态

骨架落位。
