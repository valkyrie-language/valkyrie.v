namespace std.collection;

class BTreeSetNode<T> {
    leaf: bool
    keys: ArrayList<T>
    children: ArrayList<BTreeSetNode<T>>
    next: Option<BTreeSetNode<T>>
}

class BTreeSet<T> {
    _root: Option<BTreeSetNode<T>>
    _length: usize
}

imply BTreeSet<T> {
    micro new(): Self {
        return Self {
            _root: None,
            _length: 0,
        }
    }

    micro insert(mut self, value: T): bool
        where T: Equal & std::operator::Comparable
    {
        if self._root.is_none() {
            let root: BTreeSetNode<T> = BTreeSetNode {
                leaf: true,
                keys: ArrayList::new(4),
                children: ArrayList::new(0),
                next: None,
            }
            root.keys.push(value)
            self._root = Some(root)
            self._length = 1
            return true
        }

        if self.contains(value) {
            return false
        }

        let root: BTreeSetNode<T> = self._root.unwrap()
        if self.is_full(root) {
            let new_root: BTreeSetNode<T> = BTreeSetNode {
                leaf: false,
                keys: ArrayList::new(4),
                children: ArrayList::new(4),
                next: None,
            }
            new_root.children.push(root)
            self.split_child(new_root, 0)
            self._root = Some(new_root)
        }

        self.insert_non_full(self._root.unwrap(), value)
        self._length = self._length + 1
        return true
    }

    # 树内删除：沿下降路径定位叶子、原位摘除键，再自底向上做借位/合并修复。
    # 复杂度 O(log n)：不收集重建树，不触碰无关子树。
    # 修复不变量与 `BTreeMap` 同口径：节点至少 1 键；内部节点 `keys[i]`
    # 恒为子树 `children[i + 1]` 的首键（路由副本），删除后沿途刷新。
    micro remove(mut self, value: T): bool
        where T: Equal & std::operator::Comparable
    {
        if !self.contains(value) {
            return false
        }

        let root: BTreeSetNode<T> = self._root.unwrap()
        let removed: bool = self.delete_from(root, value)
        if !removed {
            return false
        }

        self._length = self._length - 1

        # 根收敛：空键内部根以唯一子树替代；空叶根清空整树。
        if root.leaf && root.keys.length() == 0 {
            let empty: Option<BTreeSetNode<T>> = None
            self._root = empty
        }
        if !root.leaf && root.keys.length() == 0 {
            let only: BTreeSetNode<T> = root.children.get(1 as isize).unwrap()
            let collapsed: Option<BTreeSetNode<T>> = Some(only)
            self._root = collapsed
        }

        return true
    }

    # 私有：沿路径下降删除。返回是否真实删除了一个键。
    # 删除只发生在叶子（内部键是路由副本）；回溯时刷新左侧路由副本，
    # 子树掏空则就地修复。
    micro delete_from(mut self, node: BTreeSetNode<T>, value: T): bool
        where T: Equal & std::operator::Comparable
    {
        if node.leaf {
            let mut cursor: usize = 0
            while cursor < node.keys.length() {
                if node.keys.get((cursor + 1) as isize).unwrap() == value {
                    node.keys.remove((cursor + 1) as isize)
                    return true
                }

                cursor = cursor + 1
            }

            return false
        }

        let child_index: usize = self.find_child_index(node, value)
        let child: BTreeSetNode<T> = node.children.get((child_index + 1) as isize).unwrap()
        let removed: bool = self.delete_from(child, value)
        if !removed {
            return false
        }

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
    micro rebalance_child(mut self, parent: BTreeSetNode<T>, child_index: usize): unit {
        let child: BTreeSetNode<T> = parent.children.get((child_index + 1) as isize).unwrap()

        if child_index > 0 {
            let left: BTreeSetNode<T> = parent.children.get(child_index as isize).unwrap()
            if left.keys.length() >= 2 {
                self.borrow_from_left(parent, child_index, left, child)
                return
            }

            self.merge_into_left(parent, child_index, left, child)
            return
        }

        if child_index + 1 < parent.children.length() {
            let right: BTreeSetNode<T> = parent.children.get((child_index + 2) as isize).unwrap()
            if right.keys.length() >= 2 {
                self.borrow_from_right(parent, child_index, right, child)
                return
            }

            self.merge_into_child(parent, child_index, right, child)
            return
        }
    }

    # 私有：从左兄弟借最后一格。叶子搬键；内部节点把路由副本压下去、
    # 连同左兄弟的末子树一起接进孩子头部，副本改记孩子新首键。
    micro borrow_from_left(mut self, parent: BTreeSetNode<T>, child_index: usize, left: BTreeSetNode<T>, child: BTreeSetNode<T>): unit {
        if child.leaf {
            let last: usize = left.keys.length()
            let moved_key: T = left.keys.remove(last as isize).unwrap()
            child.keys.insert(1 as isize, moved_key)
            parent.keys.set(child_index as isize, moved_key)
            return
        }

        let separator: T = parent.keys.get(child_index as isize).unwrap()
        let moved_child: BTreeSetNode<T> = left.children.remove(left.children.length() as isize).unwrap()
        child.children.insert(1 as isize, moved_child)
        child.keys.insert(1 as isize, separator)
        parent.keys.set(child_index as isize, self.first_key(moved_child))
    }

    # 私有：从右兄弟借第一格（镜像方向）。
    micro borrow_from_right(mut self, parent: BTreeSetNode<T>, child_index: usize, right: BTreeSetNode<T>, child: BTreeSetNode<T>): unit {
        if child.leaf {
            let moved_key: T = right.keys.remove(1 as isize).unwrap()
            child.keys.push(moved_key)
            parent.keys.set((child_index + 1) as isize, self.first_key(right))
            return
        }

        let separator: T = parent.keys.get((child_index + 1) as isize).unwrap()
        let moved_child: BTreeSetNode<T> = right.children.remove(1 as isize).unwrap()
        child.children.push(moved_child)
        child.keys.push(separator)
        right.keys.remove(1 as isize)
        parent.keys.set((child_index + 1) as isize, self.first_key(right))
    }

    # 私有：掏空的孩子并入左兄弟。孩子无键可搬，叶子只需接上叶链；
    # 内部节点把路由副本压进左兄弟、唯一子树挂到尾部。最后摘除副本与孩子。
    micro merge_into_left(mut self, parent: BTreeSetNode<T>, child_index: usize, left: BTreeSetNode<T>, child: BTreeSetNode<T>): unit {
        if child.leaf {
            left.next = child.next
        }
        else {
            let separator: T = parent.keys.get(child_index as isize).unwrap()
            let only: BTreeSetNode<T> = child.children.get(1 as isize).unwrap()
            left.keys.push(separator)
            left.children.push(only)
        }

        parent.keys.remove(child_index as isize)
        parent.children.remove((child_index + 1) as isize)
    }

    # 私有：无左兄弟时，右兄弟整体并入掏空的孩子（吸收其全部键与叶链）。
    micro merge_into_child(mut self, parent: BTreeSetNode<T>, child_index: usize, right: BTreeSetNode<T>, child: BTreeSetNode<T>): unit {
        if child.leaf {
            while right.keys.length() > 0 {
                child.keys.push(right.keys.remove(1 as isize).unwrap())
            }

            child.next = right.next
        }
        else {
            let separator: T = parent.keys.get((child_index + 1) as isize).unwrap()
            child.keys.push(separator)
            while right.keys.length() > 0 {
                child.keys.push(right.keys.remove(1 as isize).unwrap())
            }

            while right.children.length() > 0 {
                child.children.push(right.children.remove(1 as isize).unwrap())
            }
        }

        parent.keys.remove((child_index + 1) as isize)
        parent.children.remove((child_index + 2) as isize)
    }

    # 私有：子树首键——路由副本刷新的唯一事实来源。
    micro first_key(self, node: BTreeSetNode<T>): T {
        return self.leftmost_leaf(node).keys.get(1 as isize).unwrap()
    }

    micro contains(self, value: T): bool
        where T: Equal & std::operator::Comparable
    {
        if self._root.is_none() {
            return false
        }

        return self.search_node(self._root.unwrap(), value)
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

    micro iter(self, f: micro(T) -> unit) -> unit {
        let items: ArrayList<T> = self.to_list()
        let mut index: usize = 0
        while index < items.length() {
            f(items.get((index + 1) as isize).unwrap())
            index = index + 1
        }
    }

    micro to_list(self): ArrayList<T> {
        let mut result: ArrayList<T> = ArrayList::new(self._length)
        if self._root.is_none() {
            return result
        }

        let mut current: Option<BTreeSetNode<T>> = Some(self.leftmost_leaf(self._root.unwrap()))
        while current.is_some() {
            let leaf: BTreeSetNode<T> = current.unwrap()
            let mut cursor: usize = 0
            while cursor < leaf.keys.length() {
                result.push(leaf.keys.get((cursor + 1) as isize).unwrap())
                cursor = cursor + 1
            }

            current = leaf.next
        }

        return result
    }

    micro from_list(list: ArrayList<T>): Self
        where T: Equal & std::operator::Comparable
    {
        let mut result: Self = Self::new()
        list.iter(micro(value: T) -> unit {
            result.insert(value)
        })
        return result
    }

    micro search_node(self, node: BTreeSetNode<T>, value: T): bool
        where T: Equal & std::operator::Comparable
    {
        if node.leaf {
            let mut cursor: usize = 0
            while cursor < node.keys.length() {
                if node.keys.get((cursor + 1) as isize).unwrap() == value {
                    return true
                }

                cursor = cursor + 1
            }

            return false
        }

        return self.search_node(node.children.get((self.find_child_index(node, value) + 1) as isize).unwrap(), value)
    }

    # 按键取回存储的元素（集合里键即元素）：命中返回叶子中的键，未命中 `None`。
    # 内部节点的键只是路由副本，命中判定必须在叶子完成。
    private micro lookup(self, node: BTreeSetNode<T>, value: T): Option<T>
        where T: Equal & std::operator::Comparable
    {
        if node.leaf {
            let mut cursor: usize = 0
            while cursor < node.keys.length() {
                let candidate: T = node.keys.get((cursor + 1) as isize).unwrap()
                if candidate == value {
                    return Some(candidate)
                }

                cursor = cursor + 1
            }

            return None
        }

        return self.lookup(node.children.get((self.find_child_index(node, value) + 1) as isize).unwrap(), value)
    }

    micro insert_non_full(mut self, node: BTreeSetNode<T>, value: T): unit
        where T: std::operator::Comparable
    {
        if node.leaf {
            let mut insert_at: usize = 0
            while insert_at < node.keys.length() {
                if value < node.keys.get((insert_at + 1) as isize).unwrap() {
                    break
                }

                insert_at = insert_at + 1
            }

            node.keys.insert(insert_at + 1, value)
            return
        }

        let mut child_index: usize = self.find_child_index(node, value)
        let child: BTreeSetNode<T> = node.children.get((child_index + 1) as isize).unwrap()
        if self.is_full(child) {
            self.split_child(node, child_index)
            if value >= node.keys.get((child_index + 1) as isize).unwrap() {
                child_index = child_index + 1
            }
        }

        self.insert_non_full(node.children.get((child_index + 1) as isize).unwrap(), value)
    }

    micro split_child(self, parent: BTreeSetNode<T>, child_index: usize): unit {
        let child: BTreeSetNode<T> = parent.children.get((child_index + 1) as isize).unwrap()
        let right: BTreeSetNode<T> = BTreeSetNode {
            leaf: child.leaf,
            keys: ArrayList::new(4),
            children: ArrayList::new(4),
            next: None,
        }

        if child.leaf {
            while child.keys.length() > 1 {
                right.keys.push(child.keys.remove(2).unwrap())
            }

            right.next = child.next
            child.next = Some(right)

            parent.children.insert(child_index + 2, right)
            parent.keys.insert(child_index + 1, parent.children.get((child_index + 2) as isize).unwrap().keys.get(1 as isize).unwrap())
            return
        }

        let separator: T = child.keys.get(2 as isize).unwrap()
        right.keys.push(child.keys.remove(3).unwrap())
        child.keys.remove(2)

        while child.children.length() > 2 {
            right.children.push(child.children.remove(3).unwrap())
        }

        parent.children.insert(child_index + 2, right)
        parent.keys.insert(child_index + 1, separator)
    }

    micro leftmost_leaf(self, node: BTreeSetNode<T>): BTreeSetNode<T> {
        let mut current: BTreeSetNode<T> = node
        while !current.leaf {
            current = current.children.get(1 as isize).unwrap()
        }

        return current
    }

    micro find_child_index(self, node: BTreeSetNode<T>, value: T): usize
        where T: std::operator::Comparable
    {
        let mut cursor: usize = 0
        while cursor < node.keys.length() {
            if value < node.keys.get((cursor + 1) as isize).unwrap() {
                return cursor
            }

            cursor = cursor + 1
        }

        return cursor
    }

    micro is_full(self, node: BTreeSetNode<T>): bool {
        return node.keys.length() >= 3
    }

    # 最小的 `>= value` 元素；空集或全部元素都小于 `value` 时返回 `None`。
    # 与 `BTreeMap.ceiling_key` 同口径：沿叶链顺序扫描，单次 O(n)。
    micro ceiling(self, value: T) -> Option<T>
        where T: std::operator::Comparable
    {
        if self._root.is_none() {
            return None
        }

        let mut current: Option<BTreeSetNode<T>> = Some(self.leftmost_leaf(self._root.unwrap()))
        while current.is_some() {
            let leaf: BTreeSetNode<T> = current.unwrap()
            let mut cursor: usize = 0
            while cursor < leaf.keys.length() {
                let candidate: T = leaf.keys.get((cursor + 1) as isize).unwrap()
                if candidate >= value {
                    return Some(candidate)
                }

                cursor = cursor + 1
            }

            current = leaf.next
        }

        return None
    }

    # 最大的 `<= value` 元素；空集或全部元素都大于 `value` 时返回 `None`。
    # 与 `BTreeMap.floor_key` 同口径：叶链已有序，遇到第一个大于 `value`
    # 的元素即可停止（后续只会更大）。
    micro floor(self, value: T) -> Option<T>
        where T: std::operator::Comparable
    {
        if self._root.is_none() {
            return None
        }

        let mut found: Option<T> = None
        let mut current: Option<BTreeSetNode<T>> = Some(self.leftmost_leaf(self._root.unwrap()))
        while current.is_some() {
            let leaf: BTreeSetNode<T> = current.unwrap()
            let mut cursor: usize = 0
            while cursor < leaf.keys.length() {
                let candidate: T = leaf.keys.get((cursor + 1) as isize).unwrap()
                if candidate > value {
                    return found
                }

                found = Some(candidate)
                cursor = cursor + 1
            }

            current = leaf.next
        }

        return found
    }
}

# 序数合同：键即索引，`Index = T`（集合里键与元素同型），与 `isize` / `usize` 无关。
# 集合只有按键访问语义、没有 0 基偏移计数语义，因此不实现 `Cardinal`。
# 读路径：`[ ]` 是裸值形态，缺键结构化失败；可恢复形态是 `get`（`Option<T>`）。
# 写路径：`[ ]=` 与 `insert` 同源——缺键时新增，已存在时不改变元素个数。
imply BTreeSet<T>: std::operator::Ordinal {
    type Index = T;
    type Element = T;

    suffix `[ ]`(self, value: T): T {
        let result: Option<T> = self.get(value)
        if result.is_none() {
            std::types::panic("BTreeSet [ ] 键缺失：主访问是裸值形态")
        }
        return result.unwrap()
    }

    suffix `[ ]=`(mut self, key: T, element: T) {
        let inserted: bool = self.insert(element)
    }

    micro get(self, value: T): Option<T> {
        if self._root.is_none() {
            return None
        }

        return self.lookup(self._root.unwrap(), value)
    }

    # 与 `[ ]=` 同源：键用于定位，元素即写入值。
    micro set(mut self, value: T, element: T) {
        self[value] = element
    }
}
