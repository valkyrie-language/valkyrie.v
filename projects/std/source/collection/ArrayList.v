namespace std.collection;

# ArrayList：可变长序列（Vec 形态）。
#
# 表示：容量与有效性分离——`_storage` 是带初始化前沿的容量存储
# （`ArrayStorage`），`_length` 是逻辑长度；逻辑部分是有效元素区的前缀，
# 且始终不超过初始化前沿。`push` 为 `mut self` 原地追加：容量未满时在前沿
# 落子（O(1)），满时按倍增扩容（摊还 O(1)）。`clear` 只重置逻辑长度、保留
# 存储。扩容拿到的是容量槽位而非伪有效 `T`：新载体逐项显式初始化后才对读开放。
# 只有 `ArrayList` 承载可变序列语义；定长 `[T]` 不提供 push/pop/reserve/clear。
class ArrayList<T> {
    _storage: ArrayStorage<T>
    _length: usize
}

imply ArrayList<T> {
    [host_contract]
    micro new(capacity: usize): Self {
        return ArrayList { _storage: ArrayStorage::with_capacity(capacity), _length: 0 }
    }

    # 拼接：返回新列表，元素按 `self` 后 `other` 的顺序复制，两端均不被改写。
    infix `++`(self, other: ArrayList<T>): ArrayList<T> {
        let left: usize = self._length
        let right: usize = other._length
        let mut merged: ArrayList<T> = ArrayList::new(left + right)
        let mut index: usize = 0
        while index < left {
            merged.push(self._storage.get(index).unwrap())
            index = index + 1
        }

        let mut offset: usize = 0
        while offset < right {
            merged.push(other._storage.get(offset).unwrap())
            offset = offset + 1
        }

        return merged
    }

    # 容量（存储槽位总数）。
    [host_contract]
    micro capacity(self): usize {
        return self._storage.capacity()
    }

    # 原地追加：容量内前沿落子，满时倍增扩容。O(1) 摊还。
    [host_contract]
    micro push(mut self, value: T): unit {
        if self._length >= self._storage.capacity() {
            self.reserve_grow()
        }

        self._storage.place(self._length, value)
        self._length = self._length + 1
    }

    # 扩容到至少 `self._length + additional` 的容量（只增不减；已满足时不动）。
    micro reserve(mut self, additional: usize): unit {
        let required: usize = self._length + additional
        if required <= self._storage.capacity() {
            return
        }

        self.grow_to(required)
    }

    # 清空逻辑内容，保留存储（后续 push 复用既有容量）。
    [host_contract]
    micro clear(mut self): unit {
        self._length = 0
    }

    micro pop(mut self): Option<T> {
        let size: usize = self._length
        if size == 0 {
            return None
        }

        let removed: T = self._storage.get(size - 1).unwrap()
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

        if size >= self._storage.capacity() {
            self.reserve_grow()
        }

        # 从尾部开始逐格右移，为 ordinal - 1 处腾位；尾格落进前沿槽即完成初始化。
        let mut cursor: usize = size
        while cursor >= ordinal {
            let moved: T = self._storage.get(cursor - 1).unwrap()
            self._storage.place(cursor, moved)
            cursor = cursor - 1
        }

        self._storage.place(ordinal - 1, value)
        self._length = size + 1
    }

    # 序数 1 基移除：返回被移除元素，后续元素左移一格。越界返回 `None`。
    [host_contract]
    micro remove(mut self, ordinal: usize): Option<T> {
        let size: usize = self._length
        if ordinal == 0 || ordinal > size {
            return None
        }

        let removed: T = self._storage.get(ordinal - 1).unwrap()
        let mut cursor: usize = ordinal - 1
        while cursor < size - 1 {
            let moved: T = self._storage.get(cursor + 1).unwrap()
            self._storage.set(cursor, moved)
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

    # 原地反序：首尾成对交换，O(n/2)。空表不进入循环；单元素自换一次为无操作。
    # 只改逻辑区 `[0, _length)`，容量余量不参与。
    micro reverse(mut self): unit {
        let mut left: usize = 0
        let mut right: usize = self._length
        while left < right {
            right = right - 1
            let kept: T = self._storage.get(left).unwrap()
            let other: T = self._storage.get(right).unwrap()
            self._storage.set(left, other)
            self._storage.set(right, kept)
            left = left + 1
        }
    }

    # 集合族统一的回调式遍历 API；与 `IntoIterator`/`for-in` 是两件事：
    # 这里只按现有 `loop` 协议遍历本列表，不新增遍历协议，也不改变迭代顺序。
    micro iter(self, f: micro(T) -> unit) -> unit {
        loop item in self {
            f(item)
        }
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
            if self._storage.get(index).unwrap() == value {
                return true
            }

            index = index + 1
        }

        return false
    }

    # 零拷贝视图：逻辑内容的只读窗口（`[0, length)`）。
    # 视图与列表共享底层存储；本列表随后扩容重分配时，旧视图仍指向旧存储。
    micro view(self): ArrayView<T> {
        return self._storage.window(self._length)
    }

    # 冻结为定长 `[T]`：按逻辑长度精确取得容量载体并逐项显式初始化后终局化。
    # 这是显式的最终化拷贝（一次性），与逐 push 复制整表无关。
    micro to_array(self): [T] {
        let mut carrier: ArrayStorage<T> = ArrayStorage::with_capacity(self._length)
        let mut index: usize = 0
        while index < self._length {
            carrier.place(index, self._storage.get(index).unwrap())
            index = index + 1
        }

        return carrier.finalize()
    }

    # 倍增扩容：空载体从 4 起步，否则翻倍；`required` 之下不够时直接取 `required`。
    micro reserve_grow(mut self): unit {
        let capacity: usize = self._storage.capacity()
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

    # 扩容到恰好 `next` 的容量：取新载体 + 逐项搬迁初始化 + 换载体。
    # 逻辑区之外的旧槽位不搬迁——新载体上它们保持未初始化，读取被前沿挡住。
    micro grow_to(mut self, next: usize): unit {
        let mut grown: ArrayStorage<T> = ArrayStorage::with_capacity(next)
        let mut index: usize = 0
        while index < self._length {
            grown.place(index, self._storage.get(index).unwrap())
            index = index + 1
        }

        self._storage = grown
    }
}

# 0 基索引读写合同：`⁅ ⁆` / `⁅ ⁆=` 与同源的 `get_cardinal` / `set_cardinal`；
# 序数语义（1 基）由 `Ordinal` 委托本合同实现。计数由 `length` 承担。
# 读写都只对逻辑长度（`[0, _length)`）开放，容量余量不对索引暴露。
imply ArrayList<T>: std::operator::Cardinal {
    type Element = T;
    type Index = usize;

    # 0 基索引自动取值；越界结构化失败（合同语义见 `std::operator::Cardinal`）。
    suffix `⁅ ⁆`(self, offset: usize): T {
        if offset >= self._length {
            std::types::panic("Cardinal ⁅ ⁆ 越界：offset 超出元素个数")
        }

        return self._storage.get(offset).unwrap()
    }

    # 0 基索引写入，只改元素不改元素个数；越界结构化失败，不许静默丢弃写入。
    suffix `⁅ ⁆=`(mut self, offset: usize, value: T): unit {
        if offset >= self._length {
            std::types::panic("Cardinal ⁅ ⁆= 越界：offset 超出元素个数")
        }

        self._storage.set(offset, value)
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
        while true {
            let item: Option<T> = iter.next()
            if item.is_none() {
                break
            }

            result.push(item.unwrap())
        }

        return result
    }
}

imply ArrayListIterator<T>: std::iterator::Iterator {
    type Item = T;

    micro next(mut self): Option<T> {
        if self._index >= self._list.length() {
            return None
        }

        let value: T = self._list.get((self._index + 1) as isize).unwrap()
        self._index = self._index + 1
        return Some(value)
    }
}
