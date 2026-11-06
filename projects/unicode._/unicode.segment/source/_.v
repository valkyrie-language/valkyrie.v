# unicode.segment: Unicode 文本分段（字素簇/词/句边界）——包声明，无可用入口

namespace! unicode.segment;

# 本包只提供包声明，不导出任何分段入口。
# 未提供的能力：字素簇边界、词边界、句边界；`char` 为 u16，非 BMP 码点无法表达。
