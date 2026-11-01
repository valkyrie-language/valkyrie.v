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

    [host_contract]
    micro `get`(self, ordinal: usize): Option<T> {
        if ordinal == 0 || ordinal > self.length() {
            return None
        }

        # 对外序数是 1 基（`first()` 取 1、`last()` 取 length），`std::collection::array::get` 是 0 基下标，必须减一。
        return Some(std::collection::array::get(self, ordinal - 1))
    }

    [host_contract]
    micro `set`(mut self, ordinal: usize, value: T): unit {
        if ordinal == 0 || ordinal > self.length() {
            return
        }

        # 默认体必须语义正确：对外序数 1 基，`std::collection::array::set` 是 0 基下标写入（与 `std::collection::array::get` 同形）。
        # target provider 只能特化本合同，不能以空体替代实现。
        std::collection::array::set(self, ordinal - 1, value)
    }

    micro first(self): Option<T> {
        return self.get(1)
    }

    micro last(self): Option<T> {
        let item_count: usize = self.length()
        if item_count == 0 {
            return None
        }

        return self.get(item_count)
    }

    micro contains(self, value: T): bool
        where T: Equal
    {
        let mut i: usize = 1
        while i <= self.length() {
            if self.get(i).unwrap() == value {
                return true
            }

            i = i + 1
        }

        return false
    }

    # Names must match HIR sugar (`suffix [ ]` / `suffix ⁅ ⁆`).
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

        let value: T = self._array.get(self._index + 1).unwrap()
        self._index = self._index + 1
        return Some(value)
    }
}
