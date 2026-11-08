namespace std.collection;

# std.collection: sort - 排序入口
#
# 稳定性是入口名属性，不是可声明的布尔参数：
#   - `merge_sort(list, cmp)`：稳定的比较器入口，原地排序；
#   - `quick_sort(list, cmp)`：显式不稳定的比较器入口，原地排序；
#   - `sort` / `sort_unstable`：自然序入口，默认稳定 / 显式不稳定；
#   - `sorted_by`：稳定的比较器入口，返回新 `ArrayList`，不改动入参。
# `merge_sort_range` / `quick_sort_range` 只作为私有区间实现，由公开入口委托
# 调用，不再暴露 4/5 参形态。
# 定长 `[T]` 的 `sort` / `sort_by` 走同一套稳定实现：先取快照到 `ArrayList`，排好后再写回。
# `Array<T>` 暂不提供 `sort` 入口；需要排序时先把元素物化为 `ArrayList<T>`，
# 再调用上面的公开入口。
# 比较只有一条实现路径：`micro(T, T) -> i32`，负数表示前者先出，零保持原
# 相对次序（稳定），正数表示后者先出。`sort` / `sort_unstable` 由元素自身的
# `Comparable` 派生该比较器，不复制第二套排序实现。
# 长度由 `ArrayList` 自身提供，归并缓冲按需在局部 `ArrayList` 中分配。

# 小段阈值：短区间统一走插入排序，作为两种算法的共同基例。
# 插入排序天然稳定，因此 `sort` 与 `sorted_by` 的稳定性在基例上不被破坏。
private micro insertion_sort<T>(mut list: ArrayList<T>, left: usize, right: usize, cmp: micro(T, T) -> i32): unit {
    if left >= right {
        return
    }

    let mut i: usize = left + 1
    while i <= right {
        let current: T = list.get((i + 1) as isize).unwrap()
        let mut j: usize = i
        while j > left {
            let previous: T = list.get(j as isize).unwrap()
            if is_less_or_equal(previous, current, cmp) {
                break
            }
            list.set((j + 1) as isize, previous)
            j = j - 1
        }
        list.set((j + 1) as isize, current)
        i = i + 1
    }
}

# 比较器消费：`Unordered` 不在比较器协议里；`sort` 的 `Comparable` 到
# 比较器的转换在 `natural_order` 里保持结构化失败，不做静默降级。
private micro is_less<T>(a: T, b: T, cmp: micro(T, T) -> i32): bool {
    return cmp(a, b) < 0
}

private micro is_less_or_equal<T>(a: T, b: T, cmp: micro(T, T) -> i32): bool {
    return cmp(a, b) <= 0
}

# `Comparable` 到比较器的唯一转换点：`Unordered` 在排序里是结构化失败。
# 非私有：比较器闭包（`sort` / `BinaryHeap` 的自然序入口）需要按名调用它。
micro natural_order<T>(a: T, b: T): i32
    where T: std::operator::Comparable
{
    match a.compare(b) {
        case Less:
            -1
        case Equal:
            0
        case Greater:
            1
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

    merge_sort(list, micro(a: T, b: T) -> i32 {
        if a < b {
            return -1
        }

        if a > b {
            return 1
        }

        return 0
    })
}

# 稳定入口：按调用方比较器原地排序（相等元素保持原相对次序）。
micro merge_sort<T>(mut list: ArrayList<T>, cmp: micro(T, T) -> i32): unit {
    let length: usize = list.length()
    if length < 2 {
        return
    }

    merge_sort_range(list, 0, length - 1, cmp)
}

# 定长 `[T]` 的快照 / 写回：自然序 `sort` 与比较器 `sort_by` 共用同一条路径。
private micro array_to_list<T>(values: [T]) -> ArrayList<T> {
    let mut buffer: ArrayList<T> = ArrayList::new(values.length())
    let mut index: usize = 0
    while index < values.length() {
        buffer.push(values⁅index⁆)
        index = index + 1
    }

    return buffer
}

private micro list_to_array<T>(list: ArrayList<T>, mut values: [T]): unit {
    let mut index: usize = 0
    while index < values.length() {
        values⁅index⁆ = list.get((index + 1) as isize).unwrap()
        index = index + 1
    }
}

# 定长 `[T]` 的稳定自然序排序：快照到 `ArrayList`，复用归并实现后写回。
micro sort<T>(mut values: [T]): unit
    where T: std::operator::Comparable
{
    if values.length() < 2 {
        return
    }

    let mut buffer: ArrayList<T> = array_to_list(values)
    sort(buffer)
    list_to_array(buffer, values)
}

# 定长 `[T]` 的稳定比较器排序：与自然序 `sort` 共用快照 / 写回路径。
micro sort_by<T>(mut values: [T], cmp: micro(T, T) -> i32): unit {
    if values.length() < 2 {
        return
    }

    let mut buffer: ArrayList<T> = array_to_list(values)
    merge_sort(buffer, cmp)
    list_to_array(buffer, values)
}


# 稳定入口：按调用方比较器排序，返回排好序的新 `ArrayList`；入参保持原序。
# 比较器语义与内部实现一致：负数 / 零 / 正数，零不交换相对次序。
micro sorted_by<T>(items: ArrayList<T>, cmp: micro(T, T) -> i32): ArrayList<T> {
    let mut copy: ArrayList<T> = ArrayList::new(items.length())
    let mut index: usize = 0
    while index < items.length() {
        copy.push(items.get((index + 1) as isize).unwrap())
        index = index + 1
    }

    merge_sort(copy, cmp)
    return copy
}

# 私有：归并排序（稳定）。相等时先取左段，保证相对次序。
private micro merge_sort_range<T>(mut list: ArrayList<T>, left: usize, right: usize, cmp: micro(T, T) -> i32): unit {
    if left >= right {
        return
    }

    if right - left < 16 {
        insertion_sort(list, left, right, cmp)
        return
    }

    let mid: usize = left + (right - left) / 2
    merge_sort_range(list, left, mid, cmp)
    merge_sort_range(list, mid + 1, right, cmp)
    merge(list, left, mid, right, cmp)
}

# 私有：归并。缓冲在局部 `ArrayList` 中分配，返回类型不涉及 `LiteralSequence`。
private micro merge<T>(mut list: ArrayList<T>, left: usize, mid: usize, right: usize, cmp: micro(T, T) -> i32): unit {
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
        if is_less_or_equal(left_value, right_value, cmp) {
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
    quick_sort(list, micro(a: T, b: T) -> i32 {
        if a < b {
            return -1
        }

        if a > b {
            return 1
        }

        return 0
    })
}

# 不稳定入口：按调用方比较器原地排序（相等元素不保证原相对次序）。
micro quick_sort<T>(mut list: ArrayList<T>, cmp: micro(T, T) -> i32): unit {
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

    quick_sort_range(list, 0, length - 1, depth * 2, cmp)
}

# 私有：快排。短区间走插入基例，深度耗尽走堆排序回退。
private micro quick_sort_range<T>(mut list: ArrayList<T>, left: usize, right: usize, depth: usize, cmp: micro(T, T) -> i32): unit {
    if left >= right {
        return
    }

    if right - left < 16 {
        insertion_sort(list, left, right, cmp)
        return
    }

    if depth == 0 {
        heap_sort(list, left, right, cmp)
        return
    }

    let pivot_index: usize = partition(list, left, right, cmp)
    if pivot_index > left {
        quick_sort_range(list, left, pivot_index - 1, depth - 1, cmp)
    }
    if pivot_index < right {
        quick_sort_range(list, pivot_index + 1, right, depth - 1, cmp)
    }
}

private micro partition<T>(mut list: ArrayList<T>, left: usize, right: usize, cmp: micro(T, T) -> i32): usize {
    let pivot: T = list.get((right + 1) as isize).unwrap()
    let mut i: usize = left
    let mut j: usize = left
    while j < right {
        let current: T = list.get((j + 1) as isize).unwrap()
        if is_less(current, pivot, cmp) {
            swap(list, i, j)
            i = i + 1
        }
        j = j + 1
    }
    swap(list, i, right)
    return i
}

# 私有：堆排序（不稳定回退）。区间为 `[left, right]` 闭区间。
private micro heap_sort<T>(mut list: ArrayList<T>, left: usize, right: usize, cmp: micro(T, T) -> i32): unit {
    let count: usize = right - left + 1

    let mut i: usize = count / 2
    while i > 0 {
        i = i - 1
        sift_down(list, left, i, count, cmp)
    }

    let mut end: usize = count - 1
    while end > 0 {
        swap(list, left, left + end)
        sift_down(list, left, 0, end, cmp)
        end = end - 1
    }
}

private micro sift_down<T>(mut list: ArrayList<T>, base: usize, root: usize, count: usize, cmp: micro(T, T) -> i32): unit {
    let mut current: usize = root
    while current * 2 + 1 < count {
        let mut child: usize = current * 2 + 1
        if child + 1 < count {
            let left_value: T = list.get((base + child + 1) as isize).unwrap()
            let right_value: T = list.get((base + child + 2) as isize).unwrap()
            if is_less(left_value, right_value, cmp) {
                child = child + 1
            }
        }

        let parent_value: T = list.get((base + current + 1) as isize).unwrap()
        let child_value: T = list.get((base + child + 1) as isize).unwrap()
        if is_less(parent_value, child_value, cmp) {
            swap(list, base + current, base + child)
            current = child
        }
        else {
            return
        }
    }
}
