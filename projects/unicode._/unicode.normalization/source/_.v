# unicode.normalization: Unicode 归一化（NFC/NFD/NFKC/NFKD）——本轮只搭骨架，未实现

namespace! unicode.normalization;

# 状态：未实现。本包不导出任何可用入口，不要调用。
#
# 已定义的缺口（按 UAX #15，全部未落地）：
#   - `UnicodeData.txt` 的分解映射（字段 5 = canonical、字段 5 后的兼容标记）
#   - `Canonical_Combining_Class` 排序（字段 3），稳定排序未落地
#   - `Composition_Exclusion.txt`、`DerivedNormalizationProps.txt` 的 Full_Composition_Exclusion
#   - Hangul 算法分解/合成（U+AC00..U+D7A3 的算术规则）
#   - 非 BMP 码点的分解与组合涉及 u16 `char` 之外的码点，需要扩展文本表示。
#
# 归一化是字符身份层面的变换，半截实现会静默产出错误文本，因此本轮不做任何部分实现。
