# plotter

Valkyrie 绘图/图表的统一后端：方言导入 → 唯一中间表示 → 可插拔渲染后端。

## 快速开始

```v
let data: DataFrame = dataframe_from_xy(["nyar", "clr"], [1.8, 0.4])
let spec: PlotSpec = plot(data)
let mapped: PlotSpec = aes(spec, "x", "y")
let glyphs: PlotSpec = geom_col(mapped)
let titled: PlotSpec = labs(glyphs, "Bench", "Target", "ms")
let svg: utf8 = render_svg(theme_minimal(titled))
```

## 分层

| 层   | 路径                | 内容                                                     |
|:-----|:--------------------|:---------------------------------------------------------|
| L1   | `source/semantic`   | DataFrame / 美学映射 / 几何图层 / PlotSpec / GraphModel  |
| L2   | `source/layout`     | 标度 / 坐标系 / 分面 / 统计解析 / 图布局调用             |
| L3   | `source/scene`      | 唯一中间表示：已解析的几何、样式、文本、图层顺序、裁剪   |
| L4   | `source/backend`    | SVG 等渲染后端，只消费 L3                               |
| 前端 | `source/format`     | 各方言导入适配器，只产出 L3                             |

### L1 语义层

持有数据与图元模型，两个家族分离：统计家族是 `DataFrame` + `AesMapping` +
`GeomLayer` + `PlotSpec`；图结构家族是 `GraphModel`（带属性的 nodes/edges）。
本层不含坐标、不含像素、不认识任何方言或输出格式。调用方（含全部导入适配器）
通过本层表达"要画什么"，而不是"画成什么样"。

### L2 布局层

把 L1 翻译成坐标。统计侧负责标度训练、坐标映射、分面；图结构侧把节点/边交给
`std.collection.graph` 与 `std.math.graph_theory` 的布局能力，本层不实现任何布局
算法：能力缺席时返回结构化的 `GraphLayoutUnavailable`，由适配器转成诊断。

### L3 场景层

前后端唯一接缝。场景只有已解析的像素空间内容：尺寸、背景、图层；图层顺序即
绘制顺序，`clip` 是可选裁剪矩形。场景不含数据列、标度、美学映射或方言结构。

### L4 后端层

把场景发射成目标文本或字节。每个后端只读 `Scene`；一个后端表达不了场景要素时
必须结构化失败，不得静默丢弃或改写。

## 接缝规则

1. L3 是唯一接缝：任何跨层需求都必须先在场景里获得位置，否则视为越界。
2. 方言知识只存在于导入适配器；L1 及以上不得出现方言名、版本或方言专属默认值。
3. 后端不得针对某方言特判，也不得从场景之外读取任何信息。
4. 适配器只允许产出 L1 语义或 L3 场景，不允许直接拼装输出文本。
5. 不支持即失败：任一层都不能用"行为近似"的私有实现补齐下游缺口。

## L3 当前图元集

| 图元     | 使用字段                          | 样式字段                                  |
|:---------|:----------------------------------|:------------------------------------------|
| `rect`   | `x` `y` `width` `height`          | `fill` `stroke` `stroke_width` `opacity`  |
| `line`   | `x` `y` `x2` `y2`                 | `stroke` `stroke_width` `opacity`         |
| `path`   | `path`                            | `fill` `stroke` `stroke_width` `opacity`  |
| `circle` | `x` `y` `radius`                  | `fill` `stroke` `stroke_width` `opacity`  |
| `text`   | `x` `y` `text`                    | `fill` `font_family` `font_size` `text_anchor` |

图元集合是后端的最低公共分母：新增图元必须先进入 L3，再逐个后端决定支持或失败。

## 新增一种方言

1. 在 `source/format/<方言>/` 建目录，只放该方言的语法识别与到 L1 的映射。
2. 映射目标是 L1 语义（`PlotSpec` 或 `GraphModel`），随后经 L2 解析为 L3；适配器
   不直接生成坐标或像素。
3. 方言里的每个可表达构造都要落到语义模型；落不下去的构造记 `Unsupported`，
   不得填默认值假装支持。
4. 图布局模式映射到 `GraphLayoutMode`；算法缺席时保留 `capability` 坐标原样上报，
   不在适配器里自写算法。
5. 适配器不改动 L1/L2/L3/L4 的公共类型。确实缺能力时先补合同，再写适配器。
6. 失败闭合：源里出现任一不支持构造即整份失败，不返回部分场景。
7. 测试覆盖每个受支持图形类型一条正例，以及一条"不支持构造必须失败"的反例；
   完成后更新下方能力矩阵中该方言一列。

## 新增一种后端

1. 在 `source/backend/<后端>.v` 实现 `Scene → 目标文本/字节`。
2. 只读 `Scene` 字段；不得引入 `PlotSpec`、`GraphModel`、方言名或方言 id。
3. 场景中表达不了的要素返回结构化失败（错误通道），不得空输出或静默丢弃。
4. 保持图层的顺序与裁剪语义，不重新解释样式与锚点。
5. 后端之间不共享私有约定；新增后端不得修改其它后端的行为。
6. 测试用固定场景做快照，并额外覆盖"该后端不支持某图元时必须失败"。
7. 完成后更新上方分层表与下方能力矩阵的后端说明。

## 方言能力矩阵（初稿）

本表描述各格式**语法本身**能表达哪些图形类型，供适配器映射前判断可否落地；
不代表本库已提供对应导入能力。

- `支持`：该格式语法直接表达该图形类型
- `不支持`：该格式语法不提供该图形类型
- `未验证`：尚未对照该格式当前版本规范逐项核对

| 图形类型         | Mermaid     | PlantUML | DOT      | Vega-Lite | ggplot2    | Mathematica    | matplotlib      |
|:-----------------|:------------|:---------|:---------|:----------|:-----------|:---------------|:----------------|
| 柱形/条形        | 未验证      | 不支持   | 不支持   | 支持      | 支持       | 支持           | 支持            |
| 折线             | 未验证      | 不支持   | 不支持   | 支持      | 支持       | 支持           | 支持            |
| 散点             | 不支持      | 不支持   | 不支持   | 支持      | 支持       | 支持           | 支持            |
| 面积             | 不支持      | 不支持   | 不支持   | 支持      | 支持       | 支持           | 支持            |
| 直方图           | 不支持      | 不支持   | 不支持   | 支持      | 支持       | 支持           | 支持            |
| 箱线图           | 不支持      | 不支持   | 不支持   | 支持      | 支持       | 支持           | 支持            |
| 饼图/环图        | 未验证      | 不支持   | 不支持   | 支持      | 未验证     | 支持           | 支持            |
| 热图/矩阵        | 不支持      | 不支持   | 不支持   | 支持      | 支持       | 支持           | 支持            |
| 节点-边图        | 支持        | 支持     | 支持     | 未验证    | 不支持     | 支持           | 不支持          |
| 树/层级          | 未验证      | 支持     | 支持     | 不支持    | 不支持     | 支持           | 不支持          |
| 文本标注/注释    | 支持        | 支持     | 支持     | 支持      | 支持       | 支持           | 支持            |
| 参考线           | 不支持      | 不支持   | 不支持   | 支持      | 支持       | 支持           | 支持            |
| 分面/子图        | 不支持      | 不支持   | 未验证   | 支持      | 支持       | 未验证         | 支持            |
| 极坐标/对数坐标  | 不支持      | 不支持   | 不支持   | 支持      | 支持       | 支持           | 支持            |
| 交互             | 不支持      | 不支持   | 不支持   | 支持      | 不支持     | 未验证         | 不支持          |

## 导入适配器合同签名（草案）

每个适配器只做一件事：方言源码 → L3 场景，或结构化失败。

```v
namespace plotter.format;

enums ImportErrorKind {
    Syntax
    Unsupported
    MissingCapability
}

structure ImportError {
    dialect: utf8
    line: usize
    column: usize
    construct: utf8
    kind: ImportErrorKind
}

structure ImportOutcome {
    scene: Option<Scene>
    errors: [ImportError]
}

micro import_mermaid(source: utf8, width: f64, height: f64) -> ImportOutcome
micro import_plantuml(source: utf8, width: f64, height: f64) -> ImportOutcome
micro import_dot(source: utf8, width: f64, height: f64) -> ImportOutcome
micro import_vega_lite(source: utf8, width: f64, height: f64) -> ImportOutcome
micro import_ggplot_expr(source: utf8, width: f64, height: f64) -> ImportOutcome
micro import_mathematica(source: utf8, width: f64, height: f64) -> ImportOutcome
micro import_matplotlib_like(source: utf8, width: f64, height: f64) -> ImportOutcome
```

`scene` 与 `errors` 互斥：成功时 `scene` 为 `Some` 且 `errors` 为空；失败时
`scene` 为 `None`，`errors` 至少一条。部分成功不是合法结果。

失败闭合示例（示意，非现行实现输出）：

```v
ImportOutcome {
    scene: None,
    errors: [
        ImportError {
            dialect: "mermaid",
            line: 3,
            column: 1,
            construct: "pie.showData",
            kind: Unsupported
        }
    ]
}
```

签名是草案，落地时以 `source/format/` 的实际编译结果为准。

## 文档

- [外部接入契约](documentation/pages/zh-hans/contract.md)

## UI 壳

见同 workspace 的 `asgard.plotter`（`Plot` / `PlotCard` / `PlotGrid`）。
