namespace std.collection.test;

using std.collection::BTreeSet;

[test]
micro `test btree set ceiling floor bounds`() {
    let set: BTreeSet<i64> = BTreeSet::new()
    set.insert(10)
    set.insert(20)
    set.insert(30)
    set.insert(40)
    set.insert(50)
    set.insert(60)
    set.insert(70)

    let ceiling_middle = set.ceiling(45)
    if ceiling_middle.is_none() || ceiling_middle.unwrap() != 50 {
        panic("BTreeSet.ceiling 中间值测试失败")
    }

    let floor_middle = set.floor(45)
    if floor_middle.is_none() || floor_middle.unwrap() != 40 {
        panic("BTreeSet.floor 中间值测试失败")
    }

    let ceiling_exact = set.ceiling(30)
    if ceiling_exact.is_none() || ceiling_exact.unwrap() != 30 {
        panic("BTreeSet.ceiling 精确命中测试失败")
    }

    let floor_exact = set.floor(30)
    if floor_exact.is_none() || floor_exact.unwrap() != 30 {
        panic("BTreeSet.floor 精确命中测试失败")
    }

    let ceiling_below = set.ceiling(0)
    if ceiling_below.is_none() || ceiling_below.unwrap() != 10 {
        panic("BTreeSet.ceiling 下界外测试失败")
    }

    if set.floor(0).is_some() {
        panic("BTreeSet.floor 下界外应返回 None")
    }

    if set.ceiling(100).is_some() {
        panic("BTreeSet.ceiling 上界外应返回 None")
    }

    let floor_above = set.floor(100)
    if floor_above.is_none() || floor_above.unwrap() != 70 {
        panic("BTreeSet.floor 上界外测试失败")
    }
}

[test]
micro `test btree set empty bounds`() {
    let set: BTreeSet<i64> = BTreeSet::new()
    if set.ceiling(1).is_some() || set.floor(1).is_some() {
        panic("空 BTreeSet 的 floor/ceiling 应返回 None")
    }
}
