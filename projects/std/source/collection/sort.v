namespace std.collection;

# std.collection: sort - 排序入口
#
# 稳定性是入口名属性，不是可声明的布尔参数：
#   - `sort`：稳定入口（归并 + 插入基例），默认；
#   - `sort_unstable`：唯一显式不稳定入口（快排 + 堆回退 + 插入基例）。
# `quick_sort` / `merge_sort` 只作为私有实现，不再是公开入口。
# 比较只要求 `T: Comparable`（不引入 `Iterable` / `Sequence` 等额外抽象）；
# 长度由 `ArrayList` 自身提供，归并缓冲按需在局部 `ArrayList` 中分配。

# 小段阈值：短区间统一走插入排序，作为两种算法的共同基例。
# 插入排序天然稳定，因此 `sort` 的稳定性在基例上不被破坏。
private micro insertion_sort<T>(mut list: ArrayList<T>, left: usize, right: usize): unit
    where T: std::operator::Comparable
{
    if left >= right {
        return
    }

    let mut i: usize = left + 1
    while i <= right {
        let current: T = list.get((i + 1) as isize).unwrap()
        let mut j: usize = i
        while j > left {
            let previous: T = list.get(j as isize).unwrap()
            if is_less_or_equal(previous, current) {
                break
            }
            list.set((j + 1) as isize, previous)
            j = j - 1
        }
        list.set((j + 1) as isize, current)
        i = i + 1
    }
}

# 比较包装：`Unordered` 在排序里是结构化失败，不做静默降级。
private micro is_less<T>(a: T, b: T): bool
    where T: std::operator::Comparable
{
    match a.compare(b) {
        case Less:
            true
        case Equal:
            false
        case Greater:
            false
        case Unordered:
            std::types::panic("sort: 比较消费到 Unordered")
    }
}

private micro is_less_or_equal<T>(a: T, b: T): bool
    where T: std::operator::Comparable
{
    match a.compare(b) {
        case Less:
            true
        case Equal:
            true
        case Greater:
            false
        case Unordered:
            std::types::panic("sort: 比较消费到 Unordered")
    }
}

private micro swap<T>(mut list: ArrayList<T>, a: usize, b: usize): unit {
    if a == b {
        return
    }

    let tmp: T = list.get((a + 1) as isize).unwrap()
    let other: T = list.get((b + 1) as isize).unwrap()
    list.set((a + 1) as isize, other)
    list.set((b + 1) as isize, tmp)
}

# ---- 稳定入口：归并排序 ----

micro sort<T>(mut list: ArrayList<T>): unit
    where T: std::operator::Comparable
{
    let length: usize = list.length()
    if length < 2 {
        return
    }

    merge_sort(list, 0, length - 1)
}

# 私有：归并排序（稳定）。相等时先取左段，保证相对次序。
private micro merge_sort<T>(mut list: ArrayList<T>, left: usize, right: usize): unit
    where T: std::operator::Comparable
{
    if left >= right {
        return
    }

    if right - left < 16 {
        insertion_sort(list, left, right)
        return
    }

    let mid: usize = left + (right - left) / 2
    merge_sort(list, left, mid)
    merge_sort(list, mid + 1, right)
    merge(list, left, mid, right)
}

# 私有：归并。缓冲在局部 `ArrayList` 中分配，返回类型不涉及 `LiteralSequence`。
private micro merge<T>(mut list: ArrayList<T>, left: usize, mid: usize, right: usize): unit
    where T: std::operator::Comparable
{
    let mut buffer: ArrayList<T> = ArrayList::new(0)
    let mut i: usize = left
    while i <= right {
        buffer.push(list.get((i + 1) as isize).unwrap())
        i = i + 1
    }

    let left_count: usize = mid - left + 1
    let mut a: usize = 0
    let mut b: usize = left_count
    let mut k: usize = left
    while a < left_count && b < buffer.length() {
        let left_value: T = buffer.get((a + 1) as isize).unwrap()
        let right_value: T = buffer.get((b + 1) as isize).unwrap()
        if is_less_or_equal(left_value, right_value) {
            list.set((k + 1) as isize, left_value)
            a = a + 1
        }
        else {
            list.set((k + 1) as isize, right_value)
            b = b + 1
        }
        k = k + 1
    }

    while a < left_count {
        list.set((k + 1) as isize, buffer.get((a + 1) as isize).unwrap())
        a = a + 1
        k = k + 1
    }

    while b < buffer.length() {
        list.set((k + 1) as isize, buffer.get((b + 1) as isize).unwrap())
        b = b + 1
        k = k + 1
    }
}

# ---- 不稳定入口：快排 + 堆回退 ----

micro sort_unstable<T>(mut list: ArrayList<T>): unit
    where T: std::operator::Comparable
{
    let length: usize = list.length()
    if length < 2 {
        return
    }

    # 深度预算 = 2 * floor(log2(length))；耗尽后退化为堆排序，避免恶意划分退化。
    let mut depth: usize = 0
    let mut span: usize = length
    while span > 1 {
        span = span / 2
        depth = depth + 1
    }

    quick_sort(list, 0, length - 1, depth * 2)
}

# 私有：快排。短区间走插入基例，深度耗尽走堆排序回退。
private micro quick_sort<T>(mut list: ArrayList<T>, left: usize, right: usize, depth: usize): unit
    where T: std::operator::Comparable
{
    if left >= right {
        return
    }

    if right - left < 16 {
        insertion_sort(list, left, right)
        return
    }

    if depth == 0 {
        heap_sort(list, left, right)
        return
    }

    let pivot_index: usize = partition(list, left, right)
    if pivot_index > left {
        quick_sort(list, left, pivot_index - 1, depth - 1)
    }
    if pivot_index < right {
        quick_sort(list, pivot_index + 1, right, depth - 1)
    }
}

private micro partition<T>(mut list: ArrayList<T>, left: usize, right: usize): usize
    where T: std::operator::Comparable
{
    let pivot: T = list.get((right + 1) as isize).unwrap()
    let mut i: usize = left
    let mut j: usize = left
    while j < right {
        let current: T = list.get((j + 1) as isize).unwrap()
        if is_less(current, pivot) {
            swap(list, i, j)
            i = i + 1
        }
        j = j + 1
    }
    swap(list, i, right)
    return i
}

# 私有：堆排序（不稳定回退）。区间为 `[left, right]` 闭区间。
private micro heap_sort<T>(mut list: ArrayList<T>, left: usize, right: usize): unit
    where T: std::operator::Comparable
{
    let count: usize = right - left + 1

    let mut i: usize = count / 2
    while i > 0 {
        i = i - 1
        sift_down(list, left, i, count)
    }

    let mut end: usize = count - 1
    while end > 0 {
        swap(list, left, left + end)
        sift_down(list, left, 0, end)
        end = end - 1
    }
}

private micro sift_down<T>(mut list: ArrayList<T>, base: usize, root: usize, count: usize): unit
    where T: std::operator::Comparable
{
    let mut current: usize = root
    while current * 2 + 1 < count {
        let mut child: usize = current * 2 + 1
        if child + 1 < count {
            let left_value: T = list.get((base + child + 1) as isize).unwrap()
            let right_value: T = list.get((base + child + 2) as isize).unwrap()
            if is_less(left_value, right_value) {
                child = child + 1
            }
        }

        let parent_value: T = list.get((base + current + 1) as isize).unwrap()
        let child_value: T = list.get((base + child + 1) as isize).unwrap()
        if is_less(parent_value, child_value) {
            swap(list, base + current, base + child)
            current = child
        }
        else {
            return
        }
    }
}
