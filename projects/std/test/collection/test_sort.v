namespace std.collection.test;

using std.collection::{ArrayList, sort, sort_unstable, sorted_by};

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

# `sorted_by` 的比较器协议：负数表示前者先出，零保持原相对次序（稳定），
# 正数表示后者先出；入口返回新 `ArrayList`，不改动入参。

[test]
micro `test sorted by comparator sorts copy descending`() {
    let values: ArrayList<i64> = ArrayList::new(0)
    values.push(3)
    values.push(1)
    values.push(2)

    let ordered: ArrayList<i64> = sorted_by(values, micro(a: i64, b: i64) -> i32 {
        if a < b {
            return 1
        }
        if a > b {
            return -1
        }
        return 0
    })

    if values.length() != 3 || values.get(1).unwrap() != 3 {
        panic("sorted_by must not mutate input test failed")
    }

    if ordered.length() != 3 {
        panic("sorted_by length test failed")
    }

    if ordered.get(1).unwrap() != 3 {
        panic("sorted_by comparator first element test failed")
    }

    if ordered.get(2).unwrap() != 2 {
        panic("sorted_by comparator middle element test failed")
    }

    if ordered.get(3).unwrap() != 1 {
        panic("sorted_by comparator last element test failed")
    }
}

[test]
micro `test sorted by preserves equal key order`() {
    let values: ArrayList<i64> = ArrayList::new(0)
    values.push(23)
    values.push(21)
    values.push(12)
    values.push(22)
    values.push(11)

    let ordered: ArrayList<i64> = sorted_by(values, micro(a: i64, b: i64) -> i32 {
        let left_key: i64 = a / 10
        let right_key: i64 = b / 10
        if left_key < right_key {
            return -1
        }
        if left_key > right_key {
            return 1
        }
        return 0
    })

    # 稳定：键 1 的 12 在 11 前，键 2 的 23 / 21 / 22 依次保留。
    if ordered.get(1).unwrap() != 12 {
        panic("sorted_by stability first element test failed")
    }

    if ordered.get(2).unwrap() != 11 {
        panic("sorted_by stability second element test failed")
    }

    if ordered.get(3).unwrap() != 23 {
        panic("sorted_by stability third element test failed")
    }

    if ordered.get(4).unwrap() != 21 {
        panic("sorted_by stability fourth element test failed")
    }

    if ordered.get(5).unwrap() != 22 {
        panic("sorted_by stability fifth element test failed")
    }
}

[test]
micro `test sorted by empty and single`() {
    let empty: ArrayList<i64> = ArrayList::new(0)
    let empty_copy: ArrayList<i64> = sorted_by(empty, micro(a: i64, b: i64) -> i32 {
        return 0
    })
    if empty_copy.length() != 0 {
        panic("sorted_by empty list test failed")
    }

    let single: ArrayList<i64> = ArrayList::new(0)
    single.push(7)
    let single_copy: ArrayList<i64> = sorted_by(single, micro(a: i64, b: i64) -> i32 {
        return 0
    })
    if single_copy.length() != 1 || single_copy.get(1).unwrap() != 7 {
        panic("sorted_by single element test failed")
    }
}
