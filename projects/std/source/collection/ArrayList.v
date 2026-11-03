namespace std.collection;

# ArrayList：可变长序列（Vec 形态）。
#
# 表示：`_items` 是容量载体（定长数组，其长度即容量），`_length` 是逻辑长度；
# 逻辑部分永远是载体的前缀。`push` 为 `mut self` 原地追加：容量未满时直接写槽
# （O(1)），满时按倍增扩容（摊还 O(1)）。`clear` 只重置逻辑长度、保留载体。
# 只有 `ArrayList` 承载可变序列语义；定长 `[T]` 不提供 push/pop/reserve/clear。
class ArrayList<T> {
    _items: [T]
    _length: usize
}

imply ArrayList<T> {
    [host_contract]
    micro new(capacity: usize): Self {
        return ArrayList { _items: std::collection::array::new::<T>(capacity), _length: 0 }
    }

    # 容量（载体长度）。
    [host_contract]
    micro capacity(self): usize {
        return self._items.length
    }

    # 原地追加：容量内直写，满时倍增扩容。O(1) 摊还。
    [host_contract]
    micro push(mut self, value: T): unit {
        if self._length >= self._items.length {
            self.reserve_grow()
        }

        self._items⁅self._length⁆ = value
        self._length = self._length + 1
    }

    # 扩容到至少 `self._length + additional` 的容量（只增不减；已满足时不动）。
    micro reserve(mut self, additional: usize): unit {
        let required: usize = self._length + additional
        if required <= self._items.length {
            return
        }

        self.grow_to(required)
    }

    # 清空逻辑内容，保留载体（后续 push 复用既有容量）。
    [host_contract]
    micro clear(mut self): unit {
        self._length = 0
    }

    micro pop(mut self): Option<T> {
        let size: usize = self._length
        if size == 0 {
            return None
        }

        let removed: T = self._items⁅size - 1⁆
        self._length = size - 1
        return Some(removed)
    }

    # 序数 1 基插入：`ordinal == 1` 即插到最前。越界（`ordinal == 0` 或
    # `ordinal > length + 1`）为无操作。
    [host_contract]
    micro insert(mut self, ordinal: usize, value: T): unit {
        let size: usize = self._length
        if ordinal == 0 || ordinal > size + 1 {
            return
        }

        if size >= self._items.length {
            self.reserve_grow()
        }

        # 从尾部开始右移一格，为 ordinal - 1 处腾槽。
        let mut cursor: usize = size
        while cursor >= ordinal {
            self._items⁅cursor⁆ = self._items⁅cursor - 1⁆
            cursor = cursor - 1
        }

        self._items⁅ordinal - 1⁆ = value
        self._length = size + 1
    }

    # 序数 1 基移除：返回被移除元素，后续元素左移一格。越界返回 `None`。
    [host_contract]
    micro remove(mut self, ordinal: usize): Option<T> {
        let size: usize = self._length
        if ordinal == 0 || ordinal > size {
            return None
        }

        let removed: T = self._items⁅ordinal - 1⁆
        let mut cursor: usize = ordinal
        while cursor < size {
            self._items⁅cursor - 1⁆ = self._items⁅cursor⁆
            cursor = cursor + 1
        }

        self._length = size - 1
        return Some(removed)
    }

    [host_contract]
    micro length(self): usize {
        return self._length
    }

    micro is_empty(self): bool {
        return self._length == 0
    }

    micro first(self): Option<T> {
        return self.get(1)
    }

    micro last(self): Option<T> {
        let size: usize = self._length
        if size == 0 {
            return None
        }

        return self.get(size as isize)
    }

    # 下标 `[ ]` 即裸值读取，1 基序数，越界结构化失败。
    [host_contract]
    micro at(self, ordinal: usize): T {
        # 与 `get` 同口径：1 基序数，越界结构化失败（位置缺失在调用点不可恢复）。
        return self[ordinal as isize]
    }

    [host_contract]
    micro contains(self, value: T): bool
        where T: Equal
    {
        let mut index: usize = 0
        while index < self._length {
            if self._items⁅index⁆ == value {
                return true
            }

            index = index + 1
        }

        return false
    }

    # 零拷贝视图：逻辑内容的只读窗口（`[0, length)`）。
    # 视图与列表共享底层存储；本列表随后扩容重分配时，旧视图仍指向旧存储。
    micro view(self): ArrayView<T> {
        return ArrayView { _source: self._items, _offset: 0, _length: self._length }
    }

    # 冻结为定长 `[T]`：按逻辑长度精确分配并逐项复制。
    # 这是显式的最终化拷贝（一次性），与逐 push 复制整表无关。
    micro to_array(self): [T] {
        let mut frozen: [T] = std::collection::array::new::<T>(self._length)
        let mut index: usize = 0
        while index < self._length {
            frozen⁅index⁆ = self._items⁅index⁆
            index = index + 1
        }

        return frozen
    }

    # 倍增扩容：空载体从 4 起步，否则翻倍；`required` 之下不够时直接取 `required`。
    micro reserve_grow(mut self): unit {
        let capacity: usize = self._items.length
        let required: usize = self._length + 1
        let mut next: usize = capacity * 2
        if capacity == 0 {
            next = 4
        }
        if next < required {
            next = required
        }
        self.grow_to(next)
    }

    # 扩容到恰好 `next` 的载体：分配 + 逐项搬迁 + 换载体。
    micro grow_to(mut self, next: usize): unit {
        let mut grown: [T] = std::collection::array::new::<T>(next)
        let mut index: usize = 0
        while index < self._length {
            grown⁅index⁆ = self._items⁅index⁆
            index = index + 1
        }

        self._items = grown
    }
}

# 0 基索引读写合同：`⁅ ⁆` / `⁅ ⁆=` 与同源的 `get_cardinal` / `set_cardinal`；
# 序数语义（1 基）由 `Ordinal` 委托本合同实现。计数由 `length` 承担。
# 读写都只对逻辑长度（`[0, _length)`）开放，容量余量不对索引暴露。
imply ArrayList<T>: std::operator::Cardinal {
    type Element = T;

    # 0 基索引自动取值；越界结构化失败（合同语义见 `std::operator::Cardinal`）。
    suffix `⁅ ⁆`(self, offset: usize): T {
        if offset >= self._length {
            std::types::panic("Cardinal ⁅ ⁆ 越界：offset 超出元素个数")
        }

        return self._items⁅offset⁆
    }

    # 0 基索引写入，只改元素不改元素个数；越界结构化失败，不许静默丢弃写入。
    suffix `⁅ ⁆=`(mut self, offset: usize, value: T): unit {
        if offset >= self._length {
            std::types::panic("Cardinal ⁅ ⁆= 越界：offset 超出元素个数")
        }

        self._items⁅offset⁆ = value
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
# 主访问返回裸 `T`，越界结构化失败；可恢复形态走 `get`（越界返回 `None`）。
# `Index` 取 `isize`：负数落入越界判定。实际访问一律落到 `Cardinal`
# （0 基偏移 `ordinal - 1`），本 impl 不重复存储访问逻辑。
# 类型自有 `usize` glue 方法 `at` 保留在固有 impl，同源委托算子。
imply ArrayList<T>: std::operator::Ordinal {
    type Index = isize;
    type Element = T;

    # 序数 1 基，裸值读取；越界结构化失败。
    suffix `[ ]`(self, ordinal: isize): T {
        if ordinal < 1 || ordinal > self._length as isize {
            std::types::panic("Ordinal [ ] 越界：序数超出 [1, 元素个数]")
        }

        return self.get_cardinal((ordinal - 1) as usize)
    }

    # 越界写结构化失败，不许静默丢弃写入。
    suffix `[ ]=`(mut self, ordinal: isize, value: T): unit {
        if ordinal < 1 || ordinal > self._length as isize {
            std::types::panic("Ordinal [ ]= 越界：序数超出 [1, 元素个数]")
        }

        self.set_cardinal((ordinal - 1) as usize, value)
    }

    # 命名读路径：可恢复形态，越界返回 `None`（位置缺失由调用方处理）。
    micro get(self, ordinal: isize): Option<T> {
        if ordinal < 1 || ordinal > self._length as isize {
            return None
        }

        return Some(self.get_cardinal((ordinal - 1) as usize))
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
        while iter.has_next() {
            let item: T = iter.next().unwrap()
            result.push(item)
        }

        return result
    }
}

imply ArrayListIterator<T>: std::iterator::Iterator {
    type Item = T;

    micro has_next(self) -> bool {
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
