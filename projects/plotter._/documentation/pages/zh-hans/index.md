# plotter workspace

`plotter._` 收拢 Valkyrie 图形语法绘图能力，工程本体是 `projects/plotter`。

## 定位

- 数据（DataFrame）+ 图形语法（`plot / aes / geom / scale / coord / theme / labs`）+ 出图（`render_svg`）
- 不可变 `PlotSpec`，管道 `|>` 组合
- SVG 优先出图

## 文档

- [plotter 项目 readme](../../../projects/plotter/readme.md)
- [外部接入契约](../../../projects/plotter/documentation/pages/zh-hans/contract.md)
