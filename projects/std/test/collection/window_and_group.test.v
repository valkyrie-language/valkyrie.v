namespace std.collection.test;

using std.collection::{ArrayView, array_view};
using std.collection::DisjointSet;

# `array_view(source, offset, count)` 是越界即失败的三参窗口；有效窗口读写
# 直接落到源数组。

[test]
micro `test array view window read write`() {
    let mut values: [i64] = [10, 20, 30, 40]
    let window: ArrayView<i64> = array_view(values, 1, 2)

    if window.length() != 2 {
        panic("array_view window length test failed")
    }

    if window⁅0⁆ != 20 || window⁅1⁆ != 30 {
        panic("array_view window read test failed")
    }

    window⁅0⁆ = 99

    if values⁅1⁆ != 99 {
        panic("array_view window write-through test failed")
    }
}

# 边界：零长度窗口合法且为空；长度不得越过源。
[test]
micro `test array view zero length window`() {
    let values: [i64] = [10, 20, 30]
    let window: ArrayView<i64> = array_view(values, 3, 0)

    if window.length() != 0 || !window.is_empty() {
        panic("array_view zero length window test failed")
    }
}

# `group_members(root)` 返回与 root 同组的全部成员（含 root 自身）。
[test]
micro `test disjoint set group members`() {
    let sets: DisjointSet<i64> = DisjointSet::new()
    sets.union(0, 1)
    sets.union(1, 2)
    sets.union(3, 4)

    let first: ArrayList<i64> = sets.group_members(0)
    if first.length() != 3 {
        panic("group_members first group length test failed")
    }

    if !first.contains(0) || !first.contains(1) || !first.contains(2) {
        panic("group_members first group membership test failed")
    }

    if first.contains(3) || first.contains(4) {
        panic("group_members first group leaked test failed")
    }

    let second: ArrayList<i64> = sets.group_members(3)
    if second.length() != 2 || !second.contains(3) || !second.contains(4) {
        panic("group_members second group test failed")
    }
}

# 边界：未与任何元素合并时，组内只有 root 自身。
[test]
micro `test disjoint set singleton group`() {
    let sets: DisjointSet<i64> = DisjointSet::new()
    sets.add(7)

    let members: ArrayList<i64> = sets.group_members(7)
    if members.length() != 1 || !members.contains(7) {
        panic("group_members singleton test failed")
    }
}
