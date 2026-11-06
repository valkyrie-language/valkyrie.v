# unicode.normalization: Unicode 归一化（NFC/NFD/NFKC/NFKD）——包声明，无可用入口

namespace! unicode.normalization;

# 本包只提供包声明，不导出任何归一化入口。
# 未提供的能力：分解映射、规范组合类排序、组合排除、Hangul 算法分解与合成。
# 归一化是字符身份层面的变换，半截实现会产出错误文本，因此这里不做部分实现。
