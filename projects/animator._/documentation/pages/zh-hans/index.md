# animator workspace

`animator._` 收拢 Valkyrie 2D 角色动画运行时能力，工程本体是 `projects/animator`。

## 定位

- 格式中立的通用模型（骨骼、网格、权重、变形目标）
- 时间轴（轨道、关键帧、插值、事件标记）采样为确定性的姿态求值
- 绘制列表与宿主绘制合同抽象，不绑定具体渲染后端
- Live2D（Cubism）、Spine、Flash（SWF）等格式经适配器解析为统一模型；未实现的格式加载期失败闭合

## 文档

- [animator 项目 readme](../../../projects/animator/readme.md)
- [对外合同](../../../projects/animator/documentation/pages/zh-hans/contract.md)
