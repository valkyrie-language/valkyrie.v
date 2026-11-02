# vutex

文档排版与渲染（Valkyrie 实现）。

## 定位

- 消费 `notedown` 的 `DocumentGraph`，产出 layout plan（page / block / line / table / pagination）与 presentation

## 边界

- 不重实现格式 parser，不拥有第二份文档 IR
- HTML 渲染走 asgard/ssg 路径，不在本包自造 HTML 渲染器

## 当前状态

骨架落位。
