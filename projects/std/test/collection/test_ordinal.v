namespace std.collection.test;

# 序数合同（1 基）：`[ ]` 返回 `Option`，位置缺失是可恢复常态；
# `[ ]=` 越界是契约违反，这里只覆盖界内写入与回读。

[test]
micro `test array ordinal read in bounds`() {
    let values: [i32] = [10, 20, 30]

    let first: Option<i32> = values[1]
    if first.is_none() || first.unwrap() != 10 {
        panic("array ordinal first element failed")
    }

    let middle: Option<i32> = values[2]
    if middle.is_none() || middle.unwrap() != 20 {
        panic("array ordinal middle element failed")
    }

    let last: Option<i32> = values[3]
    if last.is_none() || last.unwrap() != 30 {
        panic("array ordinal last element failed")
    }
}

[test]
micro `test array ordinal missing positions`() {
    let values: [i32] = [10, 20, 30]
    let zero: isize = 0
    let beyond: isize = 4
    let negative: isize = -1

    # 0 / 负数 / 超出元素个数都是越界读，返回 `None`。
    if values[zero].is_some() {
        panic("array ordinal zero position failed")
    }

    if values[negative].is_some() {
        panic("array ordinal negative position failed")
    }

    if values[beyond].is_some() {
        panic("array ordinal beyond position failed")
    }

    let empty: [i32] = []
    let empty_read: Option<i32> = empty[1]
    if empty_read.is_some() {
        panic("array ordinal empty read failed")
    }
}

[test]
micro `test array ordinal write and readback`() {
    let mut values: [i32] = [1, 2, 3]

    values[2] = 20

    if values[2].unwrap() != 20 {
        panic("array ordinal write readback failed")
    }

    if values[1].unwrap() != 1 {
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

    let first: Option<i32> = list[1]
    if first.is_none() || first.unwrap() != 10 {
        panic("array list ordinal first failed")
    }

    let last: Option<i32> = list[3]
    if last.is_none() || last.unwrap() != 30 {
        panic("array list ordinal last failed")
    }

    let zero: isize = 0
    if list[zero].is_some() {
        panic("array list ordinal zero position failed")
    }

    list[2] = 99
    if list[2].unwrap() != 99 {
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

    let first: Option<i32> = map[first_key]
    if first.is_none() || first.unwrap() != 1 {
        panic("hash map ordinal utf8 first key failed")
    }

    let second: Option<i32> = map[second_key]
    if second.is_none() || second.unwrap() != 2 {
        panic("hash map ordinal utf8 second key failed")
    }

    # 缺失键按键定位失败，读路径返回 `None`。
    let missing: Option<i32> = map[missing_key]
    if missing.is_some() {
        panic("hash map ordinal utf8 missing key failed")
    }

    if map.length() != 2 {
        panic("hash map ordinal utf8 length failed")
    }
}
