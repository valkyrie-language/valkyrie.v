namespace std.collection.test;

using std.collection::{BTreeMap, BTreeSet, HashMap, HashSet};

# 索引语义：HashMap / HashSet / BTreeMap / BTreeSet 的 `[ ]`（Ordinal，1 基语义）
# 索引类型是**键 K**，不是位置偏移。map/set 没有 0 基偏移语义，
# 因此不提供 `Cardinal`（`⁅ ⁆` 上不存在入口，反例见 `negative/cardinal_on_map_set.v`）。
# 缺键：`[ ]` 是裸值形态、结构化失败；可恢复路径是 `get`（`Option`）。
# `length()` 恒为**条目数**，与任何索引空间无关。

[test]
micro `test hash map ordinal key read write delete`() {
    let map: HashMap<i64, i64> = HashMap::new(0)
    map[1] = 10
    map[2] = 20

    let first: i64 = map[1]
    if first != 10 {
        panic("hash map ordinal key read failed")
    }

    # 已有键写入只覆盖值，不改变条目数。
    map[1] = 11
    let rewritten: i64 = map[1]
    if rewritten != 11 {
        panic("hash map ordinal key rewrite failed")
    }

    if map.length() != 2 {
        panic("hash map ordinal length must count entries")
    }

    # 缺键：可恢复路径是 `None`；主访问按合同结构化失败（无 expected-panic 能力，这里只验可恢复路径）。
    let missing: Option<i64> = map.get(3)
    if missing.is_some() {
        panic("hash map ordinal missing key must be None")
    }

    let removed: Option<i64> = map.remove(2)
    if removed.unwrap() != 20 {
        panic("hash map ordinal delete failed")
    }

    if map.length() != 1 {
        panic("hash map ordinal length after delete failed")
    }
}

[test]
micro `test hash set ordinal key read write delete`() {
    let set: HashSet<i64> = HashSet::new()
    set[5] = 5
    set[7] = 7

    # 集合里键即元素：`[ ]` 按元素取出存储值。
    let stored: i64 = set[7]
    if stored != 7 {
        panic("hash set ordinal key read failed")
    }

    # 重复写入同一键不改变条目数。
    set[5] = 5
    if set.length() != 2 {
        panic("hash set ordinal length must count entries")
    }

    let missing: Option<i64> = set.get(9)
    if missing.is_some() {
        panic("hash set ordinal missing key must be None")
    }

    let removed: bool = set.remove(5)
    if !removed {
        panic("hash set ordinal delete failed")
    }

    if set.length() != 1 {
        panic("hash set ordinal length after delete failed")
    }
}

[test]
micro `test btree map ordinal key read write delete`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)
    map[3] = 30
    map[1] = 10

    let value: i64 = map[3]
    if value != 30 {
        panic("btree map ordinal key read failed")
    }

    map[3] = 300
    let rewritten: i64 = map[3]
    if rewritten != 300 {
        panic("btree map ordinal key rewrite failed")
    }

    if map.length() != 2 {
        panic("btree map ordinal length must count entries")
    }

    let missing: Option<i64> = map.get(2)
    if missing.is_some() {
        panic("btree map ordinal missing key must be None")
    }

    let removed: Option<i64> = map.remove(1)
    if removed.unwrap() != 10 {
        panic("btree map ordinal delete failed")
    }

    if map.length() != 1 {
        panic("btree map ordinal length after delete failed")
    }
}

[test]
micro `test btree set ordinal key read write delete`() {
    let set: BTreeSet<i64> = BTreeSet::new()
    set[20] = 20
    set[10] = 10

    let stored: i64 = set[20]
    if stored != 20 {
        panic("btree set ordinal key read failed")
    }

    # 重复写入同一键不改变条目数。
    set[10] = 10
    if set.length() != 2 {
        panic("btree set ordinal length must count entries")
    }

    let missing: Option<i64> = set.get(15)
    if missing.is_some() {
        panic("btree set ordinal missing key must be None")
    }

    # 本用例覆盖 `BTreeSet` 的序数读、写与计数路径。

    let remaining: i64 = set[10]
    if remaining != 10 {
        panic("btree set ordinal survivor failed")
    }
}
