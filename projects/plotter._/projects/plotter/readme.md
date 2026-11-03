# plotter

Valkyrie 绘图/图表的统一后端：方言导入 → 唯一中间表示 → 可插拔渲染后端。

## 快速开始

```v
let svg = dataframe_from_xy(["nyar", "clr"], [1.8, 0.4])
    |> plot()
    |> aes("x", "y")
    |> geom_col()
    |> labs("Bench", "Target", "ms")
    |> theme_minimal()
    |> render_svg()
```

## 分层

| 层   | 路径                | 内容                                                     |
|:-----|:--------------------|:---------------------------------------------------------|
| L1   | `source/semantic`   | DataFrame / 美学映射 / 几何图层 / PlotSpec / GraphModel  |
| L2   | `source/layout`     | 标度 / 坐标系 / 分面 / 统计解析 / 图布局调用             |
| L3   | `source/scene`      | 唯一中间表示：已解析的几何、样式、文本、图层顺序、裁剪   |
| L4   | `source/backend`    | SVG 等渲染后端，只消费 L3                               |
| 前端 | `source/format`     | 各方言导入适配器，只产出 L3                             |

层间只通过合同通信；方言知识只存在于 `source/format`；渲染细节只在 `source/backend`。

## 文档

- [外部接入契约](documentation/pages/zh-hans/contract.md)

## UI 壳

见同 workspace 的 `asgard.plotter`（`Plot` / `PlotCard` / `PlotGrid`）。
