namespace std.collection.test;

using std.collection::{ArrayList, sort, merge_sort, quick_sort};

# 公开比较器入口：`merge_sort` 稳定，`quick_sort` 不稳定；两者都按 `cmp` 升序
# 语义（负数表示前者先出）。

[test]
micro `test merge sort public comparator`() {
    let list: ArrayList<i64> = ArrayList::new(0)
    list.push(3)
    list.push(1)
    list.push(2)
    list.push(2)

    merge_sort(list, micro(a: i64, b: i64) -> i32 {
        return (a - b) as i32
    })

    if list.length() != 4 {
        panic("merge_sort length test failed")
    }

    if list.get(1).unwrap() != 1 {
        panic("merge_sort first element test failed")
    }

    if list.get(2).unwrap() != 2 || list.get(3).unwrap() != 2 {
        panic("merge_sort duplicate stability test failed")
    }

    if list.get(4).unwrap() != 3 {
        panic("merge_sort last element test failed")
    }
}

[test]
micro `test quick sort public comparator`() {
    let list: ArrayList<i64> = ArrayList::new(0)
    list.push(3)
    list.push(1)
    list.push(2)

    quick_sort(list, micro(a: i64, b: i64) -> i32 {
        return (b - a) as i32
    })

    if list.get(1).unwrap() != 3 {
        panic("quick_sort descending first element test failed")
    }

    if list.get(2).unwrap() != 2 {
        panic("quick_sort descending middle element test failed")
    }

    if list.get(3).unwrap() != 1 {
        panic("quick_sort descending last element test failed")
    }
}

[test]
micro `test sort fixed array`() {
    let mut values: [i64] = [3, 1, 2]

    sort(values)

    if values⁅0⁆ != 1 || values⁅1⁆ != 2 || values⁅2⁆ != 3 {
        panic("sort fixed array test failed")
    }
}

# 稳定性：重复键（key 在第 2 位）必须保持输入相对次序。
[test]
micro `test merge sort stability with duplicate keys`() {
    let items: ArrayList<ArrayList<i64>> = ArrayList::new(0)

    let first: ArrayList<i64> = ArrayList::new(0)
    first.push(2)
    first.push(0)
    items.push(first)

    let second: ArrayList<i64> = ArrayList::new(0)
    second.push(1)
    second.push(1)
    items.push(second)

    let third: ArrayList<i64> = ArrayList::new(0)
    third.push(2)
    third.push(2)
    items.push(third)

    let fourth: ArrayList<i64> = ArrayList::new(0)
    fourth.push(1)
    fourth.push(3)
    items.push(fourth)

    merge_sort(items, micro(a: ArrayList<i64>, b: ArrayList<i64>) -> i32 {
        return (a.get(2).unwrap() - b.get(2).unwrap()) as i32
    })

    if items.get(1).unwrap().get(2).unwrap() != 1 {
        panic("merge_sort stability first tag test failed")
    }

    if items.get(2).unwrap().get(2).unwrap() != 3 {
        panic("merge_sort stability second tag test failed")
    }

    if items.get(3).unwrap().get(2).unwrap() != 0 {
        panic("merge_sort stability third tag test failed")
    }

    if items.get(4).unwrap().get(2).unwrap() != 2 {
        panic("merge_sort stability fourth tag test failed")
    }
}

# 反例：空输入是合法边界，不得返回元素或越界。
[test]
micro `test sort empty fixed array`() {
    let mut values: [i64] = []

    sort(values)

    if values.length() != 0 {
        panic("sort empty fixed array test failed")
    }
}
