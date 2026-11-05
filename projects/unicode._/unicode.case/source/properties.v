namespace unicode.case;

# 码点属性判定所需的区间查找。数据本身在 `unicode.types`（UCD 16.0.0，脚本生成），
# 这里只放算法：该包依赖 std 才能用数组方法，底包 `unicode.types` 只提供纯数据。
# 区间表布局：偶数下标起点、奇数下标终点（含端点），按起点严格递增。

micro range_contains(ranges: [char], code: u32) -> bool {
    let mut low: usize = 0
    let mut high: usize = ranges.length() / 2
    while low < high {
        let mid: usize = (low + high) / 2
        let start: u32 = ranges⁅mid * 2⁆ as u32
        let end: u32 = ranges⁅mid * 2 + 1⁆ as u32
        if code < start {
            high = mid
        }
        else if code > end {
            low = mid + 1
        }
        else {
            return true
        }
    }

    return false
}

# Unicode `Cased` 属性：大小写映射的上下文判定用。
micro is_cased(code: u32) -> bool {
    return range_contains(unicode::types::unicode_cased_ranges(), code)
}

# Unicode `Case_Ignorable` 属性：Final_Sigma 上下文里可跳过的码点。
micro is_case_ignorable(code: u32) -> bool {
    return range_contains(unicode::types::unicode_case_ignorable_ranges(), code)
}
