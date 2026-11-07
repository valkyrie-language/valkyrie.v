namespace std.collection;

# 不变量：`BTreeNode.size` 必须等于该节点子树内实际键总数。
# 叶子 = `keys.length()`；内部节点 = 各孩子规模之和（路由副本键不重复计数）。

private micro subtree_key_count(node: BTreeNode<i64, i64>) -> usize {
    if node.leaf {
        return node.keys.length()
    }

    let mut total: usize = 0
    let mut cursor: usize = 0
    while cursor < node.children.length() {
        total = total + subtree_key_count(node.children.get((cursor + 1) as isize).unwrap())
        cursor = cursor + 1
    }

    return total
}

private micro check_size_invariant(node: BTreeNode<i64, i64>): unit {
    let actual: usize = subtree_key_count(node)
    if node.size != actual {
        panic("BTreeMap size invariant broken")
    }

    if node.leaf {
        return
    }

    let mut cursor: usize = 0
    while cursor < node.children.length() {
        check_size_invariant(node.children.get((cursor + 1) as isize).unwrap())
        cursor = cursor + 1
    }
}

private micro check_tree_size_invariant(map: BTreeMap<i64, i64>): unit {
    if map._root.is_none() {
        return
    }

    let root: BTreeNode<i64, i64> = map._root.unwrap()
    if root.size != map._length {
        panic("BTreeMap root size must equal length")
    }

    check_size_invariant(root)
}

# 确定性伪随机序列（LCG），随机增删后逐节点校验 size。
[test]
micro `test btree map size invariant under random mutations`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)
    let mut state: u64 = 13849
    let mut step: usize = 0
    while step < 240 {
        state = (state * 25173 + 13849) % 65536
        let pick: usize = (state % 64) as usize
        let key: i64 = pick as i64

        if state % 2 == 0 {
            map.insert(key, key * 10)
        }
        else {
            map.remove(key)
        }

        # 每次变更后都做一次全树校验，覆盖根分裂、内部节点分裂与叶子分裂路径。
        check_tree_size_invariant(map)
        step = step + 1
    }

    # 收尾再按秩逐点核对，确保 size 不只是自洽，且与真实排名一致。
    let mut rank: usize = 0
    let mut expected: usize = 0
    while expected < 64 {
        let expected_key: i64 = expected as i64
        if map.get(expected_key).is_some() {
            if map.nth_key(rank).unwrap() != expected_key {
                panic("BTreeMap rank mismatch after random mutations")
            }
            rank = rank + 1
        }

        expected = expected + 1
    }

    if map.length() != rank {
        panic("BTreeMap length mismatch after random mutations")
    }

    if map.nth_key(rank).is_some() {
        panic("BTreeMap nth_key must return None at length after random mutations")
    }
}

# 分裂后内部节点规模必须按子树合计，路由副本键不重复计数。
[test]
micro `test btree map split keeps subtree sizes`() {
    let map: BTreeMap<i64, i64> = BTreeMap::new(0)
    let mut key: i64 = 0
    while key < 40 {
        map.insert(key, key)
        check_tree_size_invariant(map)
        key = key + 1
    }

    if map.length() != 40 {
        panic("BTreeMap sequential insert length failed")
    }

    if map.nth_key(39).unwrap() != 39 {
        panic("BTreeMap sequential insert tail rank failed")
    }
}
