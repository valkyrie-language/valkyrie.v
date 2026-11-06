# unicode.width: Unicode 显示宽度（East Asian Width）——包声明，无可用入口

namespace! unicode.width;

# 本包只提供包声明，不导出任何宽度查询入口。
# 未提供的能力：EastAsianWidth 分类表、码点宽度（0/1/2）查询、组合标记宽度。
# `char` 为 u16，宽度结论只可能覆盖 BMP。
