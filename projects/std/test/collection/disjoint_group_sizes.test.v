namespace std.collection.test;

using std.collection::DisjointSet;

[test]
micro `test disjoint set group sizes`() {
    let sets: DisjointSet<i64> = DisjointSet::new()
    sets.union(0, 1)
    sets.union(1, 2)
    sets.union(3, 4)
    sets.add(9)

    if sets.group_sizes(0) != 3 || sets.group_sizes(2) != 3 {
        panic("group_sizes 首组规模测试失败")
    }

    if sets.group_sizes(3) != 2 || sets.group_sizes(4) != 2 {
        panic("group_sizes 次组规模测试失败")
    }

    if sets.group_sizes(9) != 1 {
        panic("group_sizes 单例规模测试失败")
    }

    if sets.group_sizes(0) != sets.group_members(0).length() {
        panic("group_sizes 与 group_members 同源一致性测试失败")
    }
}

[test]
micro `test disjoint set group sizes disjoint`() {
    let sets: DisjointSet<i64> = DisjointSet::new()
    sets.union(0, 1)
    sets.add(7)

    if sets.group_sizes(7) != 1 {
        panic("group_sizes 独立分量规模测试失败")
    }

    if sets.group_sizes(0) == sets.group_sizes(7) && sets.connected(0, 7) {
        panic("group_sizes 不相连分量不应合并")
    }
}
