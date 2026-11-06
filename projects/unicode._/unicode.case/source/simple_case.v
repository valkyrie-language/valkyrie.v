namespace unicode.case;

# Unicode 默认全映射、locale 无关（不做土耳其语 `I→ı`）。
# simple 映射数据与分派器由 `generated_simple_case.v` 提供：BMP 全量、按块切分。
# 非 BMP（UTF-8 4 字节）超出 u16 `char` 的表示范围，直接不支持，原样保留。
#
# 表布局：每对「源码点、目标码点」占 2 个槽位，按源码点严格递增，可二分。
# `pairs` 用 `[char]` 存储：`char` 是语言内建类型，调用方按需 `as u32` 读取。
micro simple_pair_lookup(pairs: [char], code: u32) -> char {
    let mut low: usize = 0
    let mut high: usize = pairs.length() / 2
    while low < high {
        let mid: usize = (low + high) / 2
        let source: u32 = pairs⁅mid * 2⁆ as u32
        if source < code {
            low = mid + 1
        }
        else if source > code {
            high = mid
        }
        else {
            return pairs⁅mid * 2 + 1⁆
        }
    }

    return code as char
}
