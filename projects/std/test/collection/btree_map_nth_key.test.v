namespace std.collection.test;

using std.collection::BTreeMap;

# 按秩取键：`nth_key(k)` 返回第 k 小（0 基）的键。
# 键唯一，所以秩就是去重排序后的位置；越界一律返回 `None`，不回落首键/末键。

[test]
micro `test btree map nth key empty`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)

    if map.nth_key(0).is_some() {
        panic("empty nth_key must return None")
    }
}

[test]
micro `test btree map nth key out of range`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)
    map.insert(10, 100)
    map.insert(20, 200)
    map.insert(30, 300)

    # 反例：秩等于规模、远超规模都必须结构化失败。
    if map.nth_key(3).is_some() {
        panic("nth_key at length must return None")
    }

    if map.nth_key(99).is_some() {
        panic("nth_key beyond length must return None")
    }
}

[test]
micro `test btree map nth key ordered ranks`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)
    # 乱序插入 0..31，覆盖叶子分裂、内部节点分裂与根分裂后的多层结构。
    let order: [i64] = [16, 8, 24, 4, 12, 20, 28, 2, 6, 10, 14, 18, 22, 26, 30, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 0]
    let mut index: usize = 0
    while index < order.length() {
        map.insert(order⁅index⁆, order⁅index⁆ * 10)
        index = index + 1
    }

    if map.length() != 32 {
        panic("nth_key ordered length failed")
    }

    let mut rank: usize = 0
    while rank < 32 {
        if map.nth_key(rank).unwrap() != rank as i64 {
            panic("nth_key ordered rank mismatch")
        }

        rank = rank + 1
    }

    if map.nth_key(32).is_some() {
        panic("nth_key at length must return None after inserts")
    }
}

[test]
micro `test btree map nth key duplicate insert`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)
    map.insert(2, 20)
    map.insert(1, 10)
    map.insert(3, 30)

    # 已有键重插只改值，不改变规模与秩。
    map.insert(2, 200)
    if map.length() != 3 {
        panic("duplicate insert changed length")
    }

    if map.nth_key(0).unwrap() != 1 || map.nth_key(1).unwrap() != 2 || map.nth_key(2).unwrap() != 3 {
        panic("duplicate insert changed ranks")
    }

    if map.get(2).unwrap() != 200 {
        panic("duplicate insert must update value")
    }
}

[test]
micro `test btree map nth key after remove`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)
    let mut value: i64 = 0
    while value < 20 {
        map.insert(value, value)
        value = value + 1
    }

    # 逐步删除，每次断言剩余序列的秩与规模（`remove` 重建树，秩仍需逐点正确）。
    map.remove(7)
    if map.length() != 19 {
        panic("nth_key remove length failed after 7")
    }
    if map.nth_key(6).unwrap() != 6 || map.nth_key(7).unwrap() != 8 || map.nth_key(18).unwrap() != 19 {
        panic("nth_key remove rank failed after 7")
    }
    if map.nth_key(19).is_some() {
        panic("nth_key at new length must return None after 7")
    }

    map.remove(0)
    if map.length() != 18 {
        panic("nth_key remove length failed after 0")
    }
    if map.nth_key(0).unwrap() != 1 || map.nth_key(17).unwrap() != 19 {
        panic("nth_key remove rank failed after 0")
    }

    map.remove(19)
    if map.length() != 17 {
        panic("nth_key remove length failed after 19")
    }
    if map.nth_key(16).unwrap() != 18 || map.nth_key(17).is_some() {
        panic("nth_key remove rank failed after 19")
    }

    map.remove(10)
    if map.length() != 16 {
        panic("nth_key remove length failed after 10")
    }
    # 剩余 1,2,3,4,5,6,8,9,11,12,13,14,15,16,17,18：秩 8 是 11。
    if map.nth_key(0).unwrap() != 1 || map.nth_key(8).unwrap() != 11 || map.nth_key(15).unwrap() != 18 {
        panic("nth_key remove rank failed after 10")
    }

    map.remove(3)
    if map.length() != 15 {
        panic("nth_key remove length failed after 3")
    }
    # 剩余 1,2,4,5,6,8,9,11..18：秩 4 是 6，秩 5 是 8。
    if map.nth_key(4).unwrap() != 6 || map.nth_key(5).unwrap() != 8 || map.nth_key(14).unwrap() != 18 {
        panic("nth_key remove rank failed after 3")
    }
    if map.nth_key(15).is_some() {
        panic("nth_key at new length must return None after 3")
    }
}
