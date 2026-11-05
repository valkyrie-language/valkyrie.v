namespace unicode.case;

# 1→多表查找。数据在 `generated_special_case.v`（`SpecialCasing.txt` 无条件项，脚本生成）。
# 每条记录固定 5 个槽位「源码点、长度、码点0、码点1、码点2」，按源码点严格递增。
# 返回记录起点下标；未命中返回 `entries.length()`（调用方据此判断）。
# 条件项（Final_Sigma 等）不进表，由 `case_text.v` 按上下文处理。

micro special_find(entries: [char], code: u32) -> usize {
    let mut low: usize = 0
    let mut high: usize = entries.length() / 5
    while low < high {
        let mid: usize = (low + high) / 2
        let source: u32 = entries⁅mid * 5⁆ as u32
        if source < code {
            low = mid + 1
        }
        else if source > code {
            high = mid
        }
        else {
            return mid * 5
        }
    }

    return entries.length()
}
