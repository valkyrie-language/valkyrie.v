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

    micro remove(mut self, key: K): Option<V>
        where K: Equal & std::operator::Comparable
    {
        let old_option: Option<V> = self.get(key)
        if old_option.is_none() {
            return None
        }

        let mut entries: ArrayList<BTreeMapEntry<K, V>> = ArrayList::new(self._length)
        self.iterator(micro(entry_key: K, entry_value: V) -> unit {
            if entry_key != key {
                entries.push(BTreeMapEntry {
                    key: entry_key,
                    value: entry_value,
                })
            }
        })

        self.clear()

        let mut cursor: usize = 0
        while cursor < entries.length() {
            let entry: BTreeMapEntry<K, V> = entries.get((cursor + 1) as isize).unwrap()
            self.insert(entry.key, entry.value)
            cursor = cursor + 1
        }

        return old_option
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
