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
        return self._items.length()
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
        # `⁅ ⁆` 是 `Cardinal` 自动取值（裸 `T`）；循环上界由序数守卫保证在界内，越界不可达。
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
        # 序数守卫已保证 `ordinal - 1` 与循环下标在界内，`⁅ ⁆` 自动取值不会越界。
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
        return self._items.length()
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

        return self.get(size as isize)
    }

    # glue 需要裸元素；`get` 返回 `Option<T>` 不能复用。
    [host_contract]
    [library_glue(at)]
    micro at(self, ordinal: usize): T {
        # 与 `get` 同口径：1 基序数，越界结构化失败（位置缺失在 glue 路径上不可恢复）。
        return self[(ordinal as isize)].unwrap()
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

# 0 基索引读写合同：`⁅ ⁆` / `⁅ ⁆=` 与同源的 `get_cardinal` / `set_cardinal`；
# 序数语义（1 基）由 `Ordinal` 委托本合同实现。元素个数由 `length` 承担，与本合同无关。
imply ArrayList<T>: std::operator::Cardinal {
    type Element = T;

    # 0 基索引自动取值；越界结构化失败（合同语义见 `std::operator::Cardinal`）。
    suffix `⁅ ⁆`(self, offset: usize): T {
        if offset >= self.length() {
            std::types::panic("Cardinal ⁅ ⁆ 越界：offset 超出元素个数")
        }

        return std::collection::array::get(self._items, offset)
    }

    # 0 基索引写入，只改元素不改元素个数；越界结构化失败，不许静默丢弃写入。
    suffix `⁅ ⁆=`(mut self, offset: usize, value: T): unit {
        if offset >= self.length() {
            std::types::panic("Cardinal ⁅ ⁆= 越界：offset 超出元素个数")
        }

        std::collection::array::set(self._items, offset, value)
    }

    # 与 `⁅ ⁆` 同源：命名方法形态，互为委托，不维护第二套索引访问逻辑。
    micro get_cardinal(self, offset: usize): T {
        return self⁅offset⁆
    }

    # 与 `⁅ ⁆=` 同源：命名方法形态，互为委托。
    micro set_cardinal(mut self, offset: usize, value: T): unit {
        self⁅offset⁆ = value
    }
}

# 1 基序数读写合同：算子 `[ ]` / `[ ]=` 与同源的命名 `get` / `set` 全部由本 impl 提供。
# `Index` 取 `isize`：负数落入越界判定，读返回 `None`；写越界结构化失败。
# 实际访问一律落到 `Cardinal`（0 基偏移 `ordinal - 1`），本 impl 不重复存储访问逻辑。
# 类型自有 `usize` glue 方法 `at` 保留在固有 impl，同源委托算子。
imply ArrayList<T>: std::operator::Ordinal {
    type Index = isize;
    type Element = T;

    # 序数 1 基；越界读返回 `None`（位置缺失是可恢复常态）。
    suffix `[ ]`(self, ordinal: isize): Option<T> {
        if ordinal < 1 || ordinal > self.length() as isize {
            return None
        }

        return Some(self.get_cardinal((ordinal - 1) as usize))
    }

    # 越界写结构化失败，不许静默丢弃写入。
    suffix `[ ]=`(mut self, ordinal: isize, value: T): unit {
        if ordinal < 1 || ordinal > self.length() as isize {
            std::types::panic("Ordinal [ ]= 越界：序数超出 [1, 元素个数]")
        }

        self.set_cardinal((ordinal - 1) as usize, value)
    }

    # 与 `[ ]` 同源：命名方法形态，互为委托。
    micro get(self, ordinal: isize): Option<T> {
        return self[ordinal]
    }

    # 与 `[ ]=` 同源：命名方法形态，互为委托。
    micro set(mut self, ordinal: isize, value: T): unit {
        self[ordinal] = value
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

        let value: T = self._list.get((self._index + 1) as isize).unwrap()
        self._index = self._index + 1
        return Some(value)
    }
}
