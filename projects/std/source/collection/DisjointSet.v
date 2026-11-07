namespace std.collection;

class DisjointSet<T> {
    _parent: HashMap<T, T>
    _rank: HashMap<T, usize>
    _count: usize
}

imply DisjointSet<T> {
    micro new(): Self {
        return Self {
            _parent: HashMap::new(16),
            _rank: HashMap::new(16),
            _count: 0,
        }
    }

    micro add(mut self, value: T): bool
        where T: Equal & Hash
    {
        if self._parent.contains_key(value) {
            return false
        }

        self._parent.insert(value, value)
        self._rank.insert(value, 0)
        self._count = self._count + 1
        return true
    }

    micro contains(self, value: T): bool
        where T: Equal & Hash
    {
        return self._parent.contains_key(value)
    }

    micro find(mut self, value: T): Option<T>
        where T: Equal & Hash
    {
        if !self.contains(value) {
            return None
        }

        return Some(self.find_root(value))
    }

    micro union(mut self, left: T, right: T): bool
        where T: Equal & Hash
    {
        self.add(left)
        self.add(right)

        let left_root: T = self.find_root(left)
        let right_root: T = self.find_root(right)
        if left_root == right_root {
            return false
        }

        let left_rank: usize = self._rank.get(left_root).unwrap()
        let right_rank: usize = self._rank.get(right_root).unwrap()

        # 每个分支自带 `return`：分支尾值不再汇入同一 `Option` 汇合点
        # （`_parent.insert` 返回 `Option<T>`，`_rank.insert` 返回 `Option<usize>`）。
        if left_rank < right_rank {
            self._parent.insert(left_root, right_root)
            self._count = self._count - 1
            return true
        }

        if left_rank > right_rank {
            self._parent.insert(right_root, left_root)
            self._count = self._count - 1
            return true
        }

        self._parent.insert(right_root, left_root)
        self._rank.insert(left_root, left_rank + 1)
        self._count = self._count - 1
        return true
    }

    micro connected(mut self, left: T, right: T): bool
        where T: Equal & Hash
    {
        if !self.contains(left) || !self.contains(right) {
            return false
        }

        return self.find_root(left) == self.find_root(right)
    }

    micro length(self): usize {
        return self._parent.length()
    }

    micro group_count(self): usize {
        return self._count
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro clear(mut self): unit {
        self._parent.clear()
        self._rank.clear()
        self._count = 0
    }

    micro elements(self): ArrayList<T> {
        return self._parent.keys()
    }

    micro find_root(mut self, value: T): T
        where T: Equal & Hash
    {
        let parent: T = self._parent.get(value).unwrap()
        if parent == value {
            return value
        }

        let root: T = self.find_root(parent)
        self._parent.insert(value, root)
        return root
    }

    # 返回与 `root` 同组的全部成员（含 `root` 自身）；`root` 不在集合中时
    # 结构化失败。成员顺序不保证（底层哈希键序），需要有序时由调用方排序。
    micro group_members(mut self, root: T): ArrayList<T>
        where T: Equal & Hash
    {
        if !self.contains(root) {
            std::types::panic("DisjointSet.group_members 越界：root 不在集合中")
        }

        let canonical: T = self.find_root(root)
        let values: ArrayList<T> = self._parent.keys()
        let mut result: ArrayList<T> = ArrayList::new(0)
        let mut index: usize = 0
        while index < values.length() {
            let value: T = values.get((index + 1) as isize).unwrap()
            if self.find_root(value) == canonical {
                result.push(value)
            }

            index = index + 1
        }

        return result
    }

    # 返回与 `root` 同组的成员个数（含 `root` 自身）；`root` 不在集合中时
    # 结构化失败。与 `group_members` 同源（`find_root` 归一），只计数不建表。
    micro group_sizes(mut self, root: T) -> usize
        where T: Equal & Hash
    {
        if !self.contains(root) {
            std::types::panic("DisjointSet.group_sizes 越界：root 不在集合中")
        }

        let canonical: T = self.find_root(root)
        let values: ArrayList<T> = self._parent.keys()
        let mut total: usize = 0
        let mut index: usize = 0
        while index < values.length() {
            if self.find_root(values.get((index + 1) as isize).unwrap()) == canonical {
                total = total + 1
            }

            index = index + 1
        }

        return total
    }

    # 一次返回全部分量的规模表：键为分量根，值为该分量的成员个数（含根自身）。
    # 语义等价于对每个根逐个调用 `group_sizes`，但只遍历一遍元素并按根累计，
    # 复杂度为 O(元素数) 次 `find_root`（含路径压缩），不是「分量数 × 元素数」。
    micro group_size_table(mut self): HashMap<T, usize>
        where T: Equal & Hash
    {
        let values: ArrayList<T> = self._parent.keys()
        let mut sizes: HashMap<T, usize> = HashMap::new(self._parent.length())
        let mut index: usize = 0
        while index < values.length() {
            let root: T = self.find_root(values.get((index + 1) as isize).unwrap())
            if sizes.contains_key(root) {
                sizes.insert(root, sizes.get(root).unwrap() + 1)
            } else {
                sizes.insert(root, 1)
            }

            index = index + 1
        }

        return sizes
    }
}
