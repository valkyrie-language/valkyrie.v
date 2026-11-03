namespace std.collection;

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
# 主访问返回裸 `T`，越界结构化失败；可恢复形态走 `get`（越界返回 `None`）。
# `Index` 取 `isize`：负数落入越界判定。实际访问一律落到 `Cardinal`
# （0 基偏移 `ordinal - 1`），本 impl 不重复存储访问逻辑。
imply Array<T>: std::operator::Ordinal {
    type Index = isize;
    type Element = T;

    # 序数 1 基，裸值读取；越界结构化失败。
    suffix `[ ]`(self, ordinal: isize): T {
        if ordinal < 1 || ordinal > self.length() as isize {
            std::types::panic("Ordinal [ ] 越界：序数超出 [1, 元素个数]")
        }

        return self.get_cardinal((ordinal - 1) as usize)
    }

    # 越界写结构化失败，不许静默丢弃写入。
    suffix `[ ]=`(mut self, ordinal: isize, value: T): unit {
        if ordinal < 1 || ordinal > self.length() as isize {
            std::types::panic("Ordinal [ ]= 越界：序数超出 [1, 元素个数]")
        }

        self.set_cardinal((ordinal - 1) as usize, value)
    }

    # 命名读路径：可恢复形态，越界返回 `None`（位置缺失由调用方处理）。
    micro get(self, ordinal: isize): Option<T> {
        if ordinal < 1 || ordinal > self.length() as isize {
            return None
        }

        return Some(self.get_cardinal((ordinal - 1) as usize))
    }

    # 与 `[ ]=` 同源：命名方法形态，互为委托。
    micro set(mut self, ordinal: isize, value: T): unit {
        self[ordinal] = value
    }
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
        # 定长数组只能整体落成：先经 `ArrayList` 原地追加累积，再一次性冻结拷贝。
        let mut buffer: ArrayList<T> = ArrayList::new(0)
        while iter.has_next() {
            let item: T = iter.next().unwrap()
            buffer.push(item)
        }

        return buffer.to_array()
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
