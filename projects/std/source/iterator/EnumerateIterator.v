namespace std.iterator;

# 枚举项：1 基序号 + 原值。序号由本迭代器自己维护，与底层推进同步。
structure EnumerateItem<T> {
    ordinal: usize
    value: T
}

structure EnumerateIterator<T, I> {
    _iter: I
    _ordinal: usize
}

imply EnumerateIterator<T, I>: Iterator {
    type Item = EnumerateItem<T>;

    # 序号只在底层真实产出一个元素时前进；底层 `None` 即结束。
    micro next(mut self): Option<EnumerateItem<T>>
        where I: Iterator<Item = T>
    {
        let item: Option<T> = self._iter.next()
        if item.is_none() {
            return None
        }

        let ordinal: usize = self._ordinal
        self._ordinal = self._ordinal + 1
        return Some { value: EnumerateItem { ordinal: ordinal, value: item.unwrap() } }
    }
}
