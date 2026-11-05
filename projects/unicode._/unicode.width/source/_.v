# unicode.width: Unicode 显示宽度（East Asian Width）——本轮只搭骨架，未实现

namespace! unicode.width;

# 状态：未实现。本包不导出任何可用入口，不要调用。
#
# 已定义的缺口（按 UAX #11，全部未落地）：
#   - EastAsianWidth.txt 的 `Na`/`N`/`A`/`W`/`F`/`H` 分类表
#   - 码点宽度（0/1/2）查询；`A`（Ambiguous）按 locale 变化的取舍本轮不裁决
#   - 组合标记宽度 0 需要 `Grapheme_Extend` 类属性，与 `unicode.segment` 同源缺口
#
# 落地前必须先补齐的前置条件：
#   - `unicode.types` 增加 East_Asian_Width 属性表（UCD 16.0.0 生成）
#   - 非 BMP 码点（`char` 是 u16）无法表达，宽度结论只能覆盖 BMP。
