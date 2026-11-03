# animator._

`animator._` 是 2D 角色动画运行时的顶层 workspace，不是单一产品。

## 组成

- `projects/animator`：Valkyrie 2D 角色动画运行时 —— 格式中立的通用模型、时间轴采样、绘制列表抽象，面向 Live2D（Cubism）、Spine、Flash（SWF）等格式提供适配器合同

## 边界

- 不绑定具体渲染后端；宿主绘制由调用方按绘制合同实现
- 格式解析器按适配器合同接入，未接入的格式一律加载期失败闭合

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
