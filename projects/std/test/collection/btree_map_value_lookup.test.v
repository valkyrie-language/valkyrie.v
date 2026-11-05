namespace std.collection.test;

using std.collection::BTreeMap;

# 按值查键：ceiling 取最小的 `key >= value`，floor 取最大的 `key <= value`，
# 边界值包含在解内。

[test]
micro `test btree map ceiling key`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)
    map.insert(1, 10)
    map.insert(3, 30)
    map.insert(5, 50)

    if map.ceiling_key(0).unwrap() != 1 {
        panic("ceiling_key below minimum test failed")
    }

    if map.ceiling_key(1).unwrap() != 1 {
        panic("ceiling_key exact minimum test failed")
    }

    if map.ceiling_key(2).unwrap() != 3 {
        panic("ceiling_key between keys test failed")
    }

    if map.ceiling_key(3).unwrap() != 3 {
        panic("ceiling_key exact middle test failed")
    }

    # 反例：没有不小于 value 的键时返回 None，不回落到首键。
    if map.ceiling_key(6).is_some() {
        panic("ceiling_key above maximum test failed")
    }
}

[test]
micro `test btree map floor key`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)
    map.insert(1, 10)
    map.insert(3, 30)
    map.insert(5, 50)

    if map.floor_key(6).unwrap() != 5 {
        panic("floor_key above maximum test failed")
    }

    if map.floor_key(5).unwrap() != 5 {
        panic("floor_key exact maximum test failed")
    }

    if map.floor_key(4).unwrap() != 3 {
        panic("floor_key between keys test failed")
    }

    if map.floor_key(3).unwrap() != 3 {
        panic("floor_key exact middle test failed")
    }

    # 反例：没有不大于 value 的键时返回 None，不回落到末键。
    if map.floor_key(0).is_some() {
        panic("floor_key below minimum test failed")
    }
}

# 反例：空树两个入口都必须返回 None。
[test]
micro `test btree map value lookup empty`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)

    if map.ceiling_key(1).is_some() {
        panic("empty ceiling_key test failed")
    }

    if map.floor_key(1).is_some() {
        panic("empty floor_key test failed")
    }
}
