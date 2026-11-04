namespace std.collection.test;

# 序数合同（1 基）：`[ ]` 是裸值形态，`ordinal <= 0` 或超出元素个数结构化失败；
# 可恢复读路径是 `get`（越界返回 `None`）。测试框架没有 expected-panic 断言能力，
# 因此越界分类只由 `get` 覆盖，`[ ]` 只覆盖界内读写与回读。

[test]
micro `test array ordinal read in bounds`() {
    let values: [i32] = [10, 20, 30]

    let first: i32 = values[1]
    if first != 10 {
        panic("array ordinal first element failed")
    }

    let middle: i32 = values[2]
    if middle != 20 {
        panic("array ordinal middle element failed")
    }

    let last: i32 = values[3]
    if last != 30 {
        panic("array ordinal last element failed")
    }
}

[test]
micro `test array ordinal missing positions`() {
    let values: [i32] = [10, 20, 30]
    let zero: isize = 0
    let beyond: isize = 4
    let negative: isize = -1

    # 0 / 负数 / 超出元素个数都是越界读；可恢复路径 `get` 返回 `None`。
    if values.get(zero).is_some() {
        panic("array ordinal zero position failed")
    }

    if values.get(negative).is_some() {
        panic("array ordinal negative position failed")
    }

    if values.get(beyond).is_some() {
        panic("array ordinal beyond position failed")
    }

    let empty: [i32] = []
    let empty_read: Option<i32> = empty.get(1)
    if empty_read.is_some() {
        panic("array ordinal empty read failed")
    }
}

[test]
micro `test array ordinal write and readback`() {
    let mut values: [i32] = [1, 2, 3]

    values[2] = 20

    let written: i32 = values[2]
    if written != 20 {
        panic("array ordinal write readback failed")
    }

    let untouched: i32 = values[1]
    if untouched != 1 {
        panic("array ordinal write untouched failed")
    }

    if values.length() != 3 {
        panic("array ordinal write count failed")
    }
}

[test]
micro `test array list ordinal read and write`() {
    let list: ArrayList<i32> = ArrayList::new(0)
    list.push(10)
    list.push(20)
    list.push(30)

    let first: i32 = list[1]
    if first != 10 {
        panic("array list ordinal first failed")
    }

    let last: i32 = list[3]
    if last != 30 {
        panic("array list ordinal last failed")
    }

    let zero: isize = 0
    if list.get(zero).is_some() {
        panic("array list ordinal zero position failed")
    }

    list[2] = 99
    let written: i32 = list[2]
    if written != 99 {
        panic("array list ordinal write readback failed")
    }

    if list.length() != 3 {
        panic("array list ordinal write count failed")
    }
}

[test]
micro `test hash map ordinal utf8 key`() {
    let map: HashMap<utf8, i32> = HashMap::new(0)
    let first_key: utf8 = "alpha"
    let second_key: utf8 = "beta"
    let missing_key: utf8 = "gamma"

    # 键即索引：`Index = K`，与 `isize` / `usize` 无关。
    map[first_key] = 1
    map[second_key] = 2

    let first: i32 = map[first_key]
    if first != 1 {
        panic("hash map ordinal utf8 first key failed")
    }

    let second: i32 = map[second_key]
    if second != 2 {
        panic("hash map ordinal utf8 second key failed")
    }

    # 缺失键在主访问上是裸值 + 结构化失败；存在性判定走可恢复的 `get`。
    let missing: Option<i32> = map.get(missing_key)
    if missing.is_some() {
        panic("hash map ordinal utf8 missing key failed")
    }

    if map.length() != 2 {
        panic("hash map ordinal utf8 length failed")
    }
}
