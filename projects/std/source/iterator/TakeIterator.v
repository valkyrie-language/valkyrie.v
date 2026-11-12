namespace std.iterator;

structure TakeIterator<T, I> {
    _iter: I
    _count: usize
    _taken: usize
    _peek: Option<T>
    _peeked: bool
}

imply TakeIterator<T, I>: Iterator {
    type Item = T;

    # 配额耗尽即结束；配额未耗尽时，结束与否完全由底层 `next` 的 `Option` 决定。
    # 一格缓存有值时先交缓存，不再触碰底层。
    micro next(mut self): Option<T>
        where I: Iterator<Item = T>
    {
        if self._peeked {
            self._peeked = false
            let cached: Option<T> = self._peek
            let empty: Option<T> = None
            self._peek = empty
            return cached
        }

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

    # 幂等观察：缓存空时沿唯一推进路径取下一个元素，产出即计入配额并存入缓存；
    # 重复调用命中缓存，配额与底层消费都不会双份。
    micro has_next(mut self): bool
        where I: Iterator<Item = T>
    {
        if !self._peeked {
            if self._taken >= self._count {
                self._peeked = true
                return false
            }

            self._peek = self._iter.next()
            if self._peek.is_some() {
                self._taken = self._taken + 1
            }

            self._peeked = true
        }

        return self._peek.is_some()
    }
}
