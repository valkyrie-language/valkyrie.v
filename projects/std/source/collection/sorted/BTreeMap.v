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
        self._root = None
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
    }

    micro split_child(self, parent: BTreeNode<K, V>, child_index: usize): unit {
        let child: BTreeNode<K, V> = parent.children.get((child_index + 1) as isize).unwrap()
        let right: BTreeNode<K, V> = BTreeNode {
            leaf: child.leaf,
            keys: ArrayList::new(4),
            values: ArrayList::new(4),
            children: ArrayList::new(4),
            next: None,
        }

        if child.leaf {
            while child.keys.length() > 1 {
                right.keys.push(child.keys.remove(2).unwrap())
                right.values.push(child.values.remove(2).unwrap())
            }

            right.next = child.next
            child.next = Some(right)

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
