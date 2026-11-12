namespace std.collection;

structure BTreeMapEntry<K, V> {
    key: K
    value: V
}

class BTreeNode<K, V> {
    leaf: bool
    keys: ArrayList<K>
    values: ArrayList<V>
    children: ArrayList<BTreeNode<K, V>>
    next: Option<BTreeNode<K, V>>
    # 子树键总数（秩查询用）：叶子等于 `keys.length()`，内部节点等于各子树规模之和。
    # 内部节点的键是子叶已含键的路由副本，不重复计入。
    size: usize
}

class BTreeMap<K, V> {
    _root: Option<BTreeNode<K, V>>
    _length: usize
}

imply BTreeMap<K, V> {
    micro new(capacity: usize): Self {
        return Self {
            _root: None,
            _length: 0,
        }
    }

    micro `get`(self, key: K): Option<V>
        where K: Equal & std::operator::Comparable
    {
        if self._root.is_none() {
            return None
        }

        return self.search_node(self._root.unwrap(), key)
    }

    micro insert(mut self, key: K, value: V): Option<V>
        where K: Equal & std::operator::Comparable
    {
        if self._root.is_none() {
            let root: BTreeNode<K, V> = BTreeNode {
                leaf: true,
                keys: ArrayList::new(4),
                values: ArrayList::new(4),
                children: ArrayList::new(0),
                next: None,
                size: 1,
            }
            root.keys.push(key)
            root.values.push(value)
            self._root = Some(root)
            self._length = 1
            return None
        }

        let old_option: Option<V> = self.set_existing(self._root.unwrap(), key, value)
        if old_option.is_some() {
            return old_option
        }

        let root: BTreeNode<K, V> = self._root.unwrap()
        if self.is_full(root) {
            let new_root: BTreeNode<K, V> = BTreeNode {
                leaf: false,
                keys: ArrayList::new(4),
                values: ArrayList::new(0),
                children: ArrayList::new(4),
                next: None,
                size: root.size,
            }
            new_root.children.push(root)
            self.split_child(new_root, 0)
            self._root = Some(new_root)
        }

        self.insert_non_full(self._root.unwrap(), key, value)
        self._length = self._length + 1
        return None
    }

    # 树内删除：沿下降路径定位叶子、原位摘除键值，再自底向上做借位/合并修复。
    # 复杂度 O(log n)：不收集重建树，不触碰无关子树。
    # 修复不变量：叶子与内部节点至少 1 键；内部节点 `keys[i]` 恒为子树
    # `children[i + 1]` 的首键（路由副本），删除后沿途刷新。
    micro remove(mut self, key: K): Option<V>
        where K: Equal & std::operator::Comparable
    {
        let old_option: Option<V> = self.get(key)
        if old_option.is_none() {
            return None
        }

        let root: BTreeNode<K, V> = self._root.unwrap()
        let removed: bool = self.delete_from(root, key)
        if !removed {
            return old_option
        }

        self._length = self._length - 1

        # 根收敛：空键内部根以唯一子树替代；空叶根清空整树。
        if root.leaf && root.keys.length() == 0 {
            let empty: Option<BTreeNode<K, V>> = None
            self._root = empty
        }
        if !root.leaf && root.keys.length() == 0 {
            let only: BTreeNode<K, V> = root.children.get(1 as isize).unwrap()
            let collapsed: Option<BTreeNode<K, V>> = Some(only)
            self._root = collapsed
        }

        return old_option
    }

    # 私有：沿路径下降删除。返回是否真实删除了一个键。
    # 删除只发生在叶子（内部键是路由副本）；回溯时扣减子树规模、刷新左侧
    # 路由副本，子树掏空则就地修复。
    micro delete_from(mut self, node: BTreeNode<K, V>, key: K): bool
        where K: Equal & std::operator::Comparable
    {
        if node.leaf {
            let mut cursor: usize = 0
            while cursor < node.keys.length() {
                if node.keys.get((cursor + 1) as isize).unwrap() == key {
                    node.keys.remove((cursor + 1) as isize)
                    node.values.remove((cursor + 1) as isize)
                    node.size = node.size - 1
                    return true
                }

                cursor = cursor + 1
            }

            return false
        }

        let child_index: usize = self.find_child_index(node, key)
        let child: BTreeNode<K, V> = node.children.get((child_index + 1) as isize).unwrap()
        let removed: bool = self.delete_from(child, key)
        if !removed {
            return false
        }

        node.size = node.size - 1

        # 路由副本刷新：子树首键可能因删除而改变。
        if child_index > 0 {
            node.keys.set(child_index as isize, self.first_key(child))
        }

        if child.keys.length() == 0 {
            self.rebalance_child(node, child_index)
        }

        return true
    }

    # 私有：修复掏空的孩子（`child_index` 为 0 基）。优先向兄弟借位，
    # 借不到就合并；合并使本节点掏空时，由上一层递归继续修复。
    micro rebalance_child(mut self, parent: BTreeNode<K, V>, child_index: usize): unit {
        let child: BTreeNode<K, V> = parent.children.get((child_index + 1) as isize).unwrap()

        if child_index > 0 {
            let left: BTreeNode<K, V> = parent.children.get(child_index as isize).unwrap()
            if left.keys.length() >= 2 {
                self.borrow_from_left(parent, child_index, left, child)
                return
            }

            self.merge_into_left(parent, child_index, left, child)
            return
        }

        if child_index + 1 < parent.children.length() {
            let right: BTreeNode<K, V> = parent.children.get((child_index + 2) as isize).unwrap()
            if right.keys.length() >= 2 {
                self.borrow_from_right(parent, child_index, right, child)
                return
            }

            self.merge_into_child(parent, child_index, right, child)
            return
        }
    }

    # 私有：从左兄弟借最后一格。叶子搬键值；内部节点把路由副本压下去、
    # 连同左兄弟的末子树一起接进孩子头部，副本改记孩子新首键。
    micro borrow_from_left(mut self, parent: BTreeNode<K, V>, child_index: usize, left: BTreeNode<K, V>, child: BTreeNode<K, V>): unit {
        if child.leaf {
            let last: usize = left.keys.length()
            let moved_key: K = left.keys.remove(last as isize).unwrap()
            let moved_value: V = left.values.remove(last as isize).unwrap()
            child.keys.insert(1 as isize, moved_key)
            child.values.insert(1 as isize, moved_value)
            left.size = left.size - 1
            child.size = child.size + 1
            parent.keys.set(child_index as isize, moved_key)
            return
        }

        let separator: K = parent.keys.get(child_index as isize).unwrap()
        let moved_child: BTreeNode<K, V> = left.children.remove(left.children.length() as isize).unwrap()
        child.children.insert(1 as isize, moved_child)
        child.keys.insert(1 as isize, separator)
        left.size = left.size - moved_child.size
        child.size = child.size + moved_child.size
        parent.keys.set(child_index as isize, self.first_key(moved_child))
    }

    # 私有：从右兄弟借第一格（镜像方向）。
    micro borrow_from_right(mut self, parent: BTreeNode<K, V>, child_index: usize, right: BTreeNode<K, V>, child: BTreeNode<K, V>): unit {
        if child.leaf {
            let moved_key: K = right.keys.remove(1 as isize).unwrap()
            let moved_value: V = right.values.remove(1 as isize).unwrap()
            child.keys.push(moved_key)
            child.values.push(moved_value)
            right.size = right.size - 1
            child.size = child.size + 1
            parent.keys.set((child_index + 1) as isize, self.first_key(right))
            return
        }

        let separator: K = parent.keys.get((child_index + 1) as isize).unwrap()
        let moved_child: BTreeNode<K, V> = right.children.remove(1 as isize).unwrap()
        child.children.push(moved_child)
        child.keys.push(separator)
        right.keys.remove(1 as isize)
        right.size = right.size - moved_child.size
        child.size = child.size + moved_child.size
        parent.keys.set((child_index + 1) as isize, self.first_key(right))
    }

    # 私有：掏空的孩子并入左兄弟。孩子无键可搬，叶子只需接上叶链；
    # 内部节点把路由副本压进左兄弟、唯一子树挂到尾部。最后摘除副本与孩子。
    micro merge_into_left(mut self, parent: BTreeNode<K, V>, child_index: usize, left: BTreeNode<K, V>, child: BTreeNode<K, V>): unit {
        if child.leaf {
            left.next = child.next
        }
        else {
            let separator: K = parent.keys.get(child_index as isize).unwrap()
            let only: BTreeNode<K, V> = child.children.get(1 as isize).unwrap()
            left.keys.push(separator)
            left.children.push(only)
            left.size = left.size + child.size
        }

        parent.keys.remove(child_index as isize)
        parent.children.remove((child_index + 1) as isize)
    }

    # 私有：无左兄弟时，右兄弟整体并入掏空的孩子（吸收其全部键值/子树与叶链）。
    micro merge_into_child(mut self, parent: BTreeNode<K, V>, child_index: usize, right: BTreeNode<K, V>, child: BTreeNode<K, V>): unit {
        if child.leaf {
            while right.keys.length() > 0 {
                child.keys.push(right.keys.remove(1 as isize).unwrap())
                child.values.push(right.values.remove(1 as isize).unwrap())
            }

            child.next = right.next
        }
        else {
            let separator: K = parent.keys.get((child_index + 1) as isize).unwrap()
            child.keys.push(separator)
            while right.keys.length() > 0 {
                child.keys.push(right.keys.remove(1 as isize).unwrap())
            }

            while right.children.length() > 0 {
                child.children.push(right.children.remove(1 as isize).unwrap())
            }
        }

        child.size = child.size + right.size
        parent.keys.remove((child_index + 1) as isize)
        parent.children.remove((child_index + 2) as isize)
    }

    # 私有：子树首键——路由副本刷新的唯一事实来源。
    micro first_key(self, node: BTreeNode<K, V>): K {
        return self.leftmost_leaf(node).keys.get(1 as isize).unwrap()
    }

    micro contains_key(self, key: K): bool
        where K: Equal & std::operator::Comparable
    {
        return self.get(key).is_some()
    }

    micro keys(self): ArrayList<K> {
        let mut result: ArrayList<K> = ArrayList::new(self._length)
        self.iterator(micro(key: K, value: V) -> unit {
            result.push(key)
        })
        return result
    }

    micro values(self): ArrayList<V> {
        let mut result: ArrayList<V> = ArrayList::new(self._length)
        self.iterator(micro(key: K, value: V) -> unit {
            result.push(value)
        })
        return result
    }

    micro length(self): usize {
        return self._length
    }

    micro is_empty(self): bool {
        return self._length == 0
    }

    micro clear(mut self) -> unit {
        # 显式类型局部量：`None` 直接写入 `Option` 字段在 OVM 降级时字段写形态不完整，
        # 先绑定成带类型局部量再赋值，语义不变。
        let empty: Option<BTreeNode<K, V>> = None
        self._root = empty
        self._length = 0
    }

    micro iterator(self, f: micro(K, V) -> unit) -> unit {
        if self._root.is_none() {
            return
        }

        let mut current: Option<BTreeNode<K, V>> = Some(self.leftmost_leaf(self._root.unwrap()))
        while current.is_some() {
            let leaf: BTreeNode<K, V> = current.unwrap()
            let mut cursor: usize = 0
            while cursor < leaf.keys.length() {
                f(leaf.keys.get((cursor + 1) as isize).unwrap(), leaf.values.get((cursor + 1) as isize).unwrap())
                cursor = cursor + 1
            }

            current = leaf.next
        }
    }

    # 按值查键：最小的不小于 `value` 的键（include 边界）。
    # 空树或无解返回 `None`，不伪造首键/末键。
    micro ceiling_key(self, value: K): Option<K>
        where K: std::operator::Comparable
    {
        if self._root.is_none() {
            return None
        }

        let mut current: Option<BTreeNode<K, V>> = Some(self.leftmost_leaf(self._root.unwrap()))
        while current.is_some() {
            let leaf: BTreeNode<K, V> = current.unwrap()
            let mut cursor: usize = 0
            while cursor < leaf.keys.length() {
                let key: K = leaf.keys.get((cursor + 1) as isize).unwrap()
                if key >= value {
                    return Some(key)
                }

                cursor = cursor + 1
            }

            current = leaf.next
        }

        return None
    }

    # 按值查键：最大的不大于 `value` 的键（include 边界）。
    # 空树或无解返回 `None`，不伪造首键/末键。
    micro floor_key(self, value: K): Option<K>
        where K: std::operator::Comparable
    {
        if self._root.is_none() {
            return None
        }

        let mut candidate: Option<K> = None
        let mut current: Option<BTreeNode<K, V>> = Some(self.leftmost_leaf(self._root.unwrap()))
        while current.is_some() {
            let leaf: BTreeNode<K, V> = current.unwrap()
            let mut cursor: usize = 0
            while cursor < leaf.keys.length() {
                let key: K = leaf.keys.get((cursor + 1) as isize).unwrap()
                if key > value {
                    return candidate
                }

                candidate = Some(key)
                cursor = cursor + 1
            }

            current = leaf.next
        }

        return candidate
    }

    # 按秩取键：第 `rank` 小（0 基）的键，键唯一因此秩即去重后的位置。
    # 空树或 `rank >= length()` 返回 `None`，不回落首键/末键。
    # 沿各节点记录的子树的键总数下降，单层至多 4 个孩子，单次 O(log n)。
    micro nth_key(self, rank: usize): Option<K> {
        if self._root.is_none() {
            return None
        }

        let mut node: BTreeNode<K, V> = self._root.unwrap()
        if rank >= node.size {
            return None
        }

        let mut target: usize = rank
        while !node.leaf {
            let mut cursor: usize = 0
            let mut descended: bool = false
            while cursor < node.children.length() {
                let child: BTreeNode<K, V> = node.children.get((cursor + 1) as isize).unwrap()
                if target < child.size {
                    node = child
                    descended = true
                    break
                }

                target = target - child.size
                cursor = cursor + 1
            }

            # 内部规模与排名不一致（不应发生）：结构化失败，不伪造元素。
            if !descended {
                return None
            }
        }

        return Some(node.keys.get((target + 1) as isize).unwrap())
    }

    micro search_node(self, node: BTreeNode<K, V>, key: K): Option<V>
        where K: Equal & std::operator::Comparable
    {
        if node.leaf {
            let mut cursor: usize = 0
            while cursor < node.keys.length() {
                if node.keys.get((cursor + 1) as isize).unwrap() == key {
                    return Some(node.values.get((cursor + 1) as isize).unwrap())
                }

                cursor = cursor + 1
            }

            return None
        }

        return self.search_node(node.children.get((self.find_child_index(node, key) + 1) as isize).unwrap(), key)
    }

    micro set_existing(self, node: BTreeNode<K, V>, key: K, value: V): Option<V>
        where K: Equal & std::operator::Comparable
    {
        if node.leaf {
            let mut cursor: usize = 0
            while cursor < node.keys.length() {
                if node.keys.get((cursor + 1) as isize).unwrap() == key {
                    let old: V = node.values.get((cursor + 1) as isize).unwrap()
                    node.values.set((cursor + 1) as isize, value)
                    return Some(old)
                }

                cursor = cursor + 1
            }

            return None
        }

        return self.set_existing(node.children.get((self.find_child_index(node, key) + 1) as isize).unwrap(), key, value)
    }

    micro insert_non_full(mut self, node: BTreeNode<K, V>, key: K, value: V): unit
        where K: std::operator::Comparable
    {
        if node.leaf {
            let mut insert_at: usize = 0
            while insert_at < node.keys.length() {
                if key < node.keys.get((insert_at + 1) as isize).unwrap() {
                    break
                }

                insert_at = insert_at + 1
            }

            node.keys.insert(insert_at + 1, key)
            node.values.insert(insert_at + 1, value)
            node.size = node.size + 1
            return
        }

        let mut child_index: usize = self.find_child_index(node, key)
        let child: BTreeNode<K, V> = node.children.get((child_index + 1) as isize).unwrap()
        if self.is_full(child) {
            self.split_child(node, child_index)
            if key >= node.keys.get((child_index + 1) as isize).unwrap() {
                child_index = child_index + 1
            }
        }

        self.insert_non_full(node.children.get((child_index + 1) as isize).unwrap(), key, value)
        node.size = node.size + 1
    }

    micro split_child(self, parent: BTreeNode<K, V>, child_index: usize): unit {
        let child: BTreeNode<K, V> = parent.children.get((child_index + 1) as isize).unwrap()
        let right: BTreeNode<K, V> = BTreeNode {
            leaf: child.leaf,
            keys: ArrayList::new(4),
            values: ArrayList::new(4),
            children: ArrayList::new(4),
            next: None,
            size: 0,
        }

        if child.leaf {
            while child.keys.length() > 1 {
                right.keys.push(child.keys.remove(2).unwrap())
                right.values.push(child.values.remove(2).unwrap())
            }

            right.next = child.next
            child.next = Some(right)

            # 分裂不改变父节点子树规模：左 + 右 = 分裂前的 child。
            child.size = child.keys.length()
            right.size = right.keys.length()
            parent.children.insert(child_index + 2, right)
            parent.keys.insert(child_index + 1, parent.children.get((child_index + 2) as isize).unwrap().keys.get(1 as isize).unwrap())
            return
        }

        let separator: K = child.keys.get(2 as isize).unwrap()
        right.keys.push(child.keys.remove(3).unwrap())
        child.keys.remove(2)

        while child.children.length() > 2 {
            right.children.push(child.children.remove(3).unwrap())
        }

        # 内部节点规模按子树合计，路由副本键不重复计数；左右各留两个孩子。
        child.size = child.children.get(1 as isize).unwrap().size + child.children.get(2 as isize).unwrap().size
        right.size = right.children.get(1 as isize).unwrap().size + right.children.get(2 as isize).unwrap().size
        parent.children.insert(child_index + 2, right)
        parent.keys.insert(child_index + 1, separator)
    }

    micro leftmost_leaf(self, node: BTreeNode<K, V>): BTreeNode<K, V> {
        let mut current: BTreeNode<K, V> = node
        while !current.leaf {
            current = current.children.get(1 as isize).unwrap()
        }

        return current
    }

    micro find_child_index(self, node: BTreeNode<K, V>, key: K): usize
        where K: std::operator::Comparable
    {
        let mut cursor: usize = 0
        while cursor < node.keys.length() {
            if key < node.keys.get((cursor + 1) as isize).unwrap() {
                return cursor
            }

            cursor = cursor + 1
        }

        return cursor
    }

    micro is_full(self, node: BTreeNode<K, V>): bool {
        return node.keys.length() >= 3
    }
}

# 序数合同：键即索引，`Index = K`，与 `isize` / `usize` 无关。
# map 只有按键访问语义、没有 0 基偏移计数语义，因此不实现 `Cardinal`（`⁅ ⁆` 不存在入口）。
# 读路径：`[ ]` 是裸值形态，缺键结构化失败；可恢复形态是 `get`（`Option<V>`，本类型已提供）。
# 写路径：`[ ]=` 与 `insert` 同源——缺键时新增、已有键时覆盖值。
imply BTreeMap<K, V>: std::operator::Ordinal {
    type Index = K;
    type Element = V;

    suffix `[ ]`(self, key: K): V {
        let result: Option<V> = self.get(key)
        if result.is_none() {
            std::types::panic("BTreeMap [ ] 键缺失：主访问是裸值形态")
        }
        return result.unwrap()
    }

    suffix `[ ]=`(mut self, key: K, value: V) {
        let previous: Option<V> = self.insert(key, value)
    }

    # 与 `[ ]=` 同源：命名方法形态，互为委托。
    micro set(mut self, key: K, value: V) {
        self[key] = value
    }
}
