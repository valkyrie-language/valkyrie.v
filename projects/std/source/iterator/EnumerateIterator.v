namespace std.iterator;

# 枚举项：1 基序号 + 原值。序号由本迭代器自己维护，与底层推进同步。
structure EnumerateItem<T> {
    ordinal: usize
    value: T
}

structure EnumerateIterator<T, I> {
    _iter: I
    _ordinal: usize
    _peek: Option<EnumerateItem<T>>
    _peeked: bool
}

imply EnumerateIterator<T, I>: Iterator {
    type Item = EnumerateItem<T>;

    # 序号只在底层真实产出一个元素时前进；底层 `None` 即结束。
    # 一格缓存有值时先交缓存，不再触碰底层。
    micro next(mut self): Option<EnumerateItem<T>>
        where I: Iterator<Item = T>
    {
        if self._peeked {
            self._peeked = false
            let cached: Option<EnumerateItem<T>> = self._peek
            let empty: Option<EnumerateItem<T>> = None
            self._peek = empty
            return cached
        }

        let item: Option<T> = self._iter.next()
        if item.is_none() {
            return None
        }

        let ordinal: usize = self._ordinal
        self._ordinal = self._ordinal + 1
        return Some { value: EnumerateItem { ordinal: ordinal, value: item.unwrap() } }
    }

    # 幂等观察：缓存空时恰好推进底层一次，产出连同序号存入一格缓存；
    # 重复调用命中缓存，序号不再前进。
    micro has_next(mut self): bool
        where I: Iterator<Item = T>
    {
        if !self._peeked {
            let item: Option<T> = self._iter.next()
            if item.is_some() {
                let ordinal: usize = self._ordinal
                self._ordinal = self._ordinal + 1
                self._peek = Some { value: EnumerateItem { ordinal: ordinal, value: item.unwrap() } }
            }

            self._peeked = true
        }

        return self._peek.is_some()
    }
}
