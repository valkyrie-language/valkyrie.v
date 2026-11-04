namespace std.collection.test;

using std.collection::{ArrayList, sort, sort_unstable};

# `sort` / `sort_unstable` 单参入口：序来自元素的 `Comparable` 实现，
# 调用方不传比较器，也不编码排序键。

[test]
micro `test sort integers ascending`() {
    let list: ArrayList<i64> = ArrayList::new(0)
    list.push(5)
    list.push(1)
    list.push(4)
    list.push(1)
    list.push(3)

    sort(list)

    if list.length() != 5 {
        panic("sort length test failed")
    }

    if list.get(1).unwrap() != 1 {
        panic("sort first element test failed")
    }

    if list.get(2).unwrap() != 1 {
        panic("sort duplicate element test failed")
    }

    if list.get(3).unwrap() != 3 {
        panic("sort middle element test failed")
    }

    if list.get(4).unwrap() != 4 {
        panic("sort fourth element test failed")
    }

    if list.get(5).unwrap() != 5 {
        panic("sort last element test failed")
    }
}

[test]
micro `test sort short lists keep elements`() {
    let empty: ArrayList<i64> = ArrayList::new(0)
    sort(empty)
    if empty.length() != 0 {
        panic("sort empty list test failed")
    }

    let single: ArrayList<i64> = ArrayList::new(0)
    single.push(7)
    sort(single)
    if single.length() != 1 || single.get(1).unwrap() != 7 {
        panic("sort single element test failed")
    }
}

[test]
micro `test sort unstable integers ascending`() {
    let list: ArrayList<i64> = ArrayList::new(0)
    list.push(9)
    list.push(2)
    list.push(7)
    list.push(2)
    list.push(0)

    sort_unstable(list)

    if list.length() != 5 {
        panic("sort unstable length test failed")
    }

    if list.get(1).unwrap() != 0 {
        panic("sort unstable first element test failed")
    }

    if list.get(2).unwrap() != 2 {
        panic("sort unstable second element test failed")
    }

    if list.get(3).unwrap() != 2 {
        panic("sort unstable duplicate element test failed")
    }

    if list.get(4).unwrap() != 7 {
        panic("sort unstable fourth element test failed")
    }

    if list.get(5).unwrap() != 9 {
        panic("sort unstable last element test failed")
    }
}
