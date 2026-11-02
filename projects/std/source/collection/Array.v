namespace std.collection;

[clr("System.Runtime", "System.Array")]
[jvm("java.lang.Object[]")]
class Array<T> {
    _address: usize,
    _length: usize,
    _typing: Phantom<T>
}

imply Array<T> {
    [host_contract]
    micro length(self): usize {
        return std::collection::array::length(self)
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    micro first(self): Option<T> {
        return self.get(1)
    }

    micro last(self): Option<T> {
        let item_count: usize = self.length()
        if item_count == 0 {
            return None
        }

        return self.get(item_count as isize)
    }

    micro contains(self, value: T): bool
        where T: Equal
    {
        let mut i: usize = 1
        while i <= self.length() {
            if self.get(i as isize).unwrap() == value {
                return true
            }

            i = i + 1
        }

        return false
    }
}

# 0 基索引读写合同：`⁅ ⁆` / `⁅ ⁆=` 与同源的 `get_cardinal` / `set_cardinal`；
# 序数语义（1 基）由 `Ordinal` 委托本合同实现。元素个数由 `length` 承担，与本合同无关。
imply Array<T>: std::operator::Cardinal {
    type Element = T;

    # 0 基索引自动取值；越界结构化失败（合同语义见 `std::operator::Cardinal`）。
    suffix `⁅ ⁆`(self, offset: usize): T {
        if offset >= self.length() {
            std::types::panic("Cardinal ⁅ ⁆ 越界：offset 超出元素个数")
        }

        return std::collection::array::get(self, offset)
    }

    # 0 基索引写入，只改元素不改元素个数；越界结构化失败，不许静默丢弃写入。
    suffix `⁅ ⁆=`(mut self, offset: usize, value: T): unit {
        if offset >= self.length() {
            std::types::panic("Cardinal ⁅ ⁆= 越界：offset 超出元素个数")
        }

        std::collection::array::set(self, offset, value)
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
imply Array<T>: std::operator::Ordinal {
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

# 函数式追加：`result = push(result, item)`，必须写回返回值。push 按声明签名走普通调用链
# （Invoke），默认体是真实实现：经 `std.collection.array` 合同分配新数组并逐项拷贝。
# 分配、元素初始化、长度溢出（`old_len + 1` 达 usize 上限）、泛型元素表示与 GC、
# 失败与资源责任全部由 `std::collection::array::new` 的目标 provider 承担；
# 缺 provider 时结构化失败闭合，不得空体成功或链接豁免。
[host_contract]
micro push<T>(array: Array<T>, value: T): Array<T> {
    let old_len: usize = std::collection::array::length(array)
    let new_array: [T] = std::collection::array::new::<T>(old_len + 1)
    let mut i: usize = 0
    while i < old_len {
        # 合同 `get`/`set` 均为 0 基下标，拷贝循环同口径。
        std::collection::array::set(new_array, i, std::collection::array::get(array, i))
        i = i + 1
    }

    std::collection::array::set(new_array, old_len, value)
    return new_array
}

# 函数式插入：在 1 基序数 `ordinal` 前插入 `value` 并返回新数组，调用方必须写回返回值。
# 越界（`ordinal == 0` 或 `ordinal > length + 1`）返回原数组，即 `ArrayList.insert`
# no-op 分支的函数式等价。
micro insert<T>(array: Array<T>, ordinal: usize, value: T): Array<T> {
    let size: usize = std::collection::array::length(array)
    if ordinal == 0 || ordinal > size + 1 {
        return array
    }

    # 纯 V 构造路径：函数式 `push` 重建（与 `ArrayList.insert` 同形）。序数 1 基、`⁅ ⁆` 0 基。
    let mut items: [T] = []
    let mut index: usize = 0
    while index < ordinal - 1 {
        items = push(items, std::collection::array::get(array, index))
        index = index + 1
    }

    items = push(items, value)
    while index < size {
        items = push(items, std::collection::array::get(array, index))
        index = index + 1
    }

    return items
}

# 越界（`ordinal == 0` 或 `ordinal > length`）返回 `None`；否则返回 1 基序数 `ordinal`
# 处的元素。合同局限：返回类型 `Option<T>` 无法同时写回收缩后的数组，本函数不移除元素、
# 不改变数组长度；需要真正收缩的调用方必须使用 `ArrayList.remove`。
micro remove<T>(array: Array<T>, ordinal: usize): Option<T> {
    let size: usize = std::collection::array::length(array)
    if ordinal == 0 || ordinal > size {
        return None
    }

    return Some(std::collection::array::get(array, ordinal - 1))
}

structure ArrayIterator<T> {
    _array: Array<T>
    _index: usize
}

imply Array<T>: std::iterator::IntoIterator {
    type Item = T;
    type Iter = ArrayIterator<T>;

    micro into_iterator(self): ArrayIterator<T> {
        return ArrayIterator::<T> {
            _array: self,
            _index: 0,
        }
    }
}

imply Array<T>: std::iterator::FromIterator {
    type Item = T;

    micro from_iterator<I>(iter: I) -> Self
        where I: std::iterator::Iterator<Item = T>
    {
        let mut result: [T] = []
        loop item in iter {
            # `push` 是函数式追加（返回新数组）；丢弃返回值会让 `result` 始终为空，必须写回。
            result = push(result, item)
        }

        return result
    }
}

imply ArrayIterator<T>: std::iterator::Iterator {
    type Item = T;

    micro has_next(self): bool {
        return self._index < self._array.length()
    }

    micro next(mut self): Option<T> {
        if !self.has_next() {
            return None
        }

        let value: T = self._array.get((self._index + 1) as isize).unwrap()
        self._index = self._index + 1
        return Some(value)
    }
}
