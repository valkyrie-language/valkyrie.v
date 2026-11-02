# document.layout

`document.*` 核心布局：页面尺寸/边距、断行断页、页眉页脚、列表与表格的测量。

## 定位

- `PageSpec`：页面尺寸、边距、页眉页脚
- 断行断页：keep-with-next、表格行不拆、孤行寡行规则按块落定
- 测量：v0 字符单元（1 码点 = 1 宽、等宽假设）；真实字体测量经 provider 接入后替换，不进本包硬编码

## 边界

- 不拥有文档树：归 `document`
- 不拥有输出目标：归 `document.render`

## 当前状态

盒模型内核已落地：原子/规则/间隙/水平/垂直盒与基线位移（`box_shift`）、
缩放（`box_scale`）、贪心断行（glue 断点）、拍平（`box_place` 绝对定位）。
页面层已落地：`PageSpec`/`paginate`（可用宽度硬折叠、可用高度分页）与
`paginate_marked`（keep-with-next 标注驱动）。正反测试齐备。
