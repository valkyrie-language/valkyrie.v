namespace std.collection;

[clr("System.Collections", "System.Collections.Generic.List`1")]
[jvm("java.util.ArrayList")]
class ArrayList<T> {
    _items: [T]
    _capacity: usize
}

imply ArrayList<T> {
    [host_contract]
    [library_glue(construct)]
    micro new(capacity: usize): Self {
        return ArrayList { _items: [], _capacity: capacity }
    }

    [host_contract]
    micro capacity(self): usize {
        return self._items.length
    }

    [host_contract]
    [library_glue(push)]
    micro push(mut self, value: T): unit {
        # `push` 是函数式追加（`push(array, value): Array<T>`），必须把返回的新数组写回字段；
        # 丢弃返回值等于什么都没做。
        self._items = push(self._items, value)
    }

    micro pop(mut self): Option<T> {
        let size: usize = self.length()
        if size == 0 {
            return None
        }

        return self.remove(size)
    }

    [host_contract]
    micro insert(mut self, ordinal: usize, value: T): unit {
        let size: usize = self.length()
        if ordinal == 0 || ordinal > size + 1 {
            return
        }

        # 纯 V 构造路径：函数式 `push` 重建并写回（与 `Utf8Text.concat_repr` 同形），
        # 不依赖 pending 的自由 `insert` lowering。序数 1 基、`⁅ ⁆` 0 基。
        let mut items: [T] = []
        let mut index: usize = 0
        while index < ordinal - 1 {
            items = push(items, self._items⁅index⁆)
            index = index + 1
        }

        items = push(items, value)
        while index < size {
            items = push(items, self._items⁅index⁆)
            index = index + 1
        }

        self._items = items
    }

    [host_contract]
    micro remove(mut self, ordinal: usize): Option<T> {
        let size: usize = self.length()
        if ordinal == 0 || ordinal > size {
            return None
        }

        # 与 `insert` 同形的纯 V 重建路径；返回被移除元素，长度收缩一。
        let removed: T = self._items⁅ordinal - 1⁆
        let mut items: [T] = []
        let mut index: usize = 0
        while index < ordinal - 1 {
            items = push(items, self._items⁅index⁆)
            index = index + 1
        }

        index = index + 1
        while index < size {
            items = push(items, self._items⁅index⁆)
            index = index + 1
        }

        self._items = items
        return Some(removed)
    }

    [host_contract]
    micro clear(mut self): unit {
        self._items = []
    }

    [host_contract]
    [library_glue(length)]
    micro length(self): usize {
        return self._items.length
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro first(self): Option<T> {
        return self.get(1)
    }

    micro last(self): Option<T> {
        let size: usize = self.length()
        if size == 0 {
            return None
        }

        return self.get(size)
    }

    [host_contract]
    micro `get`(self, ordinal: usize): Option<T> {
        if ordinal == 0 || ordinal > self.length() {
            return None
        }

        # `__array_get` 是底层 0 基下标，ArrayList 的序数是 1 基，必须减一。
        return Some(__array_get(self._items, ordinal - 1))
    }

    # glue 需要裸元素；`get` 返回 `Option<T>` 不能复用。
    [host_contract]
    [library_glue(at)]
    micro at(self, ordinal: usize): T {
        # 与 `get` 同口径：1 基序数，底层 0 基下标。
        return __array_get(self._items, ordinal - 1)
    }

    [host_contract]
    micro `set`(mut self, ordinal: usize, value: T): unit {
        if ordinal == 0 || ordinal > self.length() {
            return
        }

        self._items::[ordinal - 1] = value
    }

    suffix `[ ]`(self, ordinal: usize): Option<T> {
        return self.get(ordinal)
    }

    suffix `[ ]=`(mut self, ordinal: usize, value: T): unit {
        self.set(ordinal, value)
    }

    suffix `⁅ ⁆`(self, cardinal: usize): Option<T> {
        return self.get(cardinal + 1)
    }

    suffix `⁅ ⁆=`(mut self, cardinal: usize, value: T): unit {
        self.set(cardinal + 1, value)
    }

    [host_contract]
    micro contains(self, value: T): bool
        where T: Equal
    {
        loop item in self._items {
            if item == value {
                return true
            }
        }

        return false
    }
}

imply ArrayList<T>: LiteralSequence<T> {
    micro with_length(n: usize): Self {
        return Self::new(n)
    }

    micro append(mut self, value: T): unit {
        self.push(value)
    }
}

structure ArrayListIterator<T> {
    _list: ArrayList<T>
    _index: usize
}

imply ArrayList<T>: std::iterator::IntoIterator {
    type Item = T;
    type Iter = ArrayListIterator<T>;

    micro into_iterator(self): ArrayListIterator<T> {
        return ArrayListIterator {
            _list: self,
            _index: 0,
        }
    }
}

imply ArrayList<T>: std::iterator::FromIterator {
    type Item = T;

    micro from_iterator<I>(iter: I) -> Self
        where I: std::iterator::Iterator<Item = T>
    {
        let mut result: Self = Self::new(0)
        loop item in iter {
            result.push(item)
        }

        return result
    }
}

imply ArrayListIterator<T>: std::iterator::Iterator {
    type Item = T;

    micro has_next(self): bool {
        return self._index < self._list.length()
    }

    micro next(mut self): Option<T> {
        if !self.has_next() {
            return None
        }

        let value: T = self._list.get(self._index + 1).unwrap()
        self._index = self._index + 1
        return Some(value)
    }
}
