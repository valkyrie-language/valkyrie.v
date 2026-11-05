namespace std.types;

# 整数区间的迭代语义：半开 `..`、闭区间 `InclusiveRange`、空区间、最大值上界、
# 嵌套与有符号端点。全部走 `IntoIterator` / `Iterator` 的 `has_next` / `next` 义务路径。
# 闭区间当前经 `inclusive_range(start, end)` 构造（`..=` 的表达式形态暂不可写）。

[test]
micro `test half open range 0..5 sums to 10`() {
    let n: usize = 5
    let mut count: usize = 0
    let mut total: usize = 0
    loop value in 0..n {
        count = count + 1
        total = total + value
    }
    if count != 5 {
        std::types::panic("0..5 必须迭代 5 次")
    }
    if total != 10 {
        std::types::panic("0..5 的迭代和必须是 10")
    }
}

[test]
micro `test unsigned u32 range`() {
    let zero: u32 = 0
    let n: u32 = 5
    let mut total: u32 = 0
    loop value in zero..n {
        total = total + value
    }
    if total != 10 as u32 {
        std::types::panic("u32 的 0..5 和必须是 10")
    }

    let mut inclusive_total: u32 = 0
    loop value in u32_inclusive_range(zero, n) {
        inclusive_total = inclusive_total + value
    }
    if inclusive_total != 15 as u32 {
        std::types::panic("u32 的 0..=5 和必须是 15")
    }
}

[test]
micro `test inclusive range 0..=5 sums to 15`() {
    let zero: usize = 0
    let n: usize = 5
    let mut count: usize = 0
    let mut total: usize = 0
    loop value in inclusive_range(zero, n) {
        count = count + 1
        total = total + value
    }
    if count != 6 {
        std::types::panic("0..=5 必须迭代 6 次")
    }
    if total != 15 {
        std::types::panic("0..=5 的迭代和必须是 15")
    }
}

[test]
micro `test empty ranges iterate zero times`() {
    let lo: usize = 3
    let mut empty_half_open: usize = 0
    loop value in lo..lo {
        empty_half_open = empty_half_open + 1
    }
    if empty_half_open != 0 {
        std::types::panic("3..3 必须零次迭代")
    }

    let hi: usize = 5
    let mut descending_half_open: usize = 0
    loop value in hi..lo {
        descending_half_open = descending_half_open + 1
    }
    if descending_half_open != 0 {
        std::types::panic("5..3 必须零次迭代")
    }

    let mut descending_inclusive: usize = 0
    loop value in inclusive_range(hi, lo) {
        descending_inclusive = descending_inclusive + 1
    }
    if descending_inclusive != 0 {
        std::types::panic("5..=3 必须零次迭代，不 panic")
    }
}

[test]
micro `test inclusive single element iterates once`() {
    let single: usize = 3
    let mut count: usize = 0
    loop value in inclusive_range(single, single) {
        if value != single {
            std::types::panic("3..=3 的元素必须是 3")
        }
        count = count + 1
    }
    if count != 1 {
        std::types::panic("3..=3 必须一次迭代")
    }
}

[test]
micro `test inclusive upper bound at usize max iterates once`() {
    # 全 1 掩码以 hi/lo 组合表达：编译器对超 i64 上限的十六进制字面量溢栈。
    let max: usize = ((0xFFFFFFFF as usize) << 32) | (0xFFFFFFFF as usize)
    let mut count: usize = 0
    let mut seen: usize = 0
    loop value in inclusive_range(max, max) {
        seen = value
        count = count + 1
    }
    if count != 1 {
        std::types::panic("usize_max..=usize_max 必须一次迭代")
    }
    if seen != max {
        std::types::panic("usize_max 上界迭代值必须是 usize_max")
    }

    let mut empty: usize = 0
    loop value in max..max {
        empty = empty + 1
    }
    if empty != 0 {
        std::types::panic("usize_max..usize_max 必须零次迭代")
    }
}

[test]
micro `test nested ranges iterate nine times`() {
    let outer: usize = 3
    let mut count: usize = 0
    let mut total: usize = 0
    loop i in 0..outer {
        loop j in 0..outer {
            count = count + 1
            total = total + i + j
        }
    }
    if count != 9 {
        std::types::panic("嵌套 0..3 × 0..3 必须 9 次")
    }
    if total != 18 {
        std::types::panic("嵌套 0..3 × 0..3 的 i+j 和必须是 18")
    }
}

[test]
micro `test range iterator protocol stops after exhaustion`() {
    let n: usize = 3
    let mut iter = 0..n
    if !iter.has_next() {
        std::types::panic("0..3 起始必须有下一个")
    }

    let mut steps: usize = 0
    while iter.has_next() {
        let item: Option<usize> = iter.next()
        if item.is_none() {
            std::types::panic("has_next 为真时 next 必须返回值")
        }
        steps = steps + 1
    }
    if steps != 3 {
        std::types::panic("0..3 必须有 3 个元素")
    }
    if iter.has_next() {
        std::types::panic("取尽后 has_next 必须为假")
    }
}

[test]
micro `test signed i32 range endpoints`() {
    let start: i32 = -2
    let end: i32 = 3
    let mut count: i32 = 0
    let mut total: i32 = 0
    loop value in start..end {
        count = count + 1
        total = total + value
    }
    if count != 5 {
        std::types::panic("i32 的 -2..3 必须迭代 5 次")
    }
    if total != 0 {
        std::types::panic("i32 的 -2..3 和必须是 0")
    }

    let mut inclusive_total: i32 = 0
    loop value in i32_inclusive_range(start, end) {
        inclusive_total = inclusive_total + value
    }
    if inclusive_total != 3 {
        std::types::panic("i32 的 -2..=3 和必须是 3")
    }
}

[test]
micro `test signed i64 inclusive range`() {
    let start: i64 = 1
    let end: i64 = 4
    let mut total: i64 = 0
    loop value in i64_inclusive_range(start, end) {
        total = total + value
    }
    if total != 10 {
        std::types::panic("i64 的 1..=4 和必须是 10")
    }
}
