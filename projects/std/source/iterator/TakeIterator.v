namespace std.iterator;

structure TakeIterator<T, I> {
    _iter: I
    _count: usize
    _taken: usize
}

imply TakeIterator<T, I>: Iterator {
    type Item = T;

    # 配额耗尽即结束；配额未耗尽时，结束与否完全由底层 `next` 的 `Option` 决定。
    micro next(mut self): Option<T>
        where I: Iterator<Item = T>
    {
        if self._taken >= self._count {
            return None
        }

        let item: Option<T> = self._iter.next()
        if item.is_none() {
            return None
        }

        self._taken = self._taken + 1
        return item
    }
}
