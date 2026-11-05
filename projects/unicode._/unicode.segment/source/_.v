# unicode.segment: Unicode 文本分段（字素簇/词/句边界）——本轮只搭骨架，未实现

namespace! unicode.segment;

# 状态：未实现。本包不导出任何可用入口，不要调用。
#
# 已定义的缺口（按 UAX #29，全部未落地）：
#   - 字素簇边界（Grapheme_Cluster_Break + Extended_Pictographic + U+200D 连接规则）
#   - 词边界（Word_Break，含 WB3c/WB4/WB6/WB7 与 `Case_Ignorable` 交互）
#   - 句边界（Sentence_Break）
#
# 落地前必须先补齐的前置条件：
#   - `unicode.types` 增加上述属性表（UCD 16.0.0 生成）
#   - 本语言 `char` 是 u16，非 BMP 码点（含大部分 emoji 扩展）无法表达，
#     字素簇规则涉及非 BMP 时必须先扩展文本表示，否则只能给出截断结论。
