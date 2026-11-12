namespace std.iterator;

structure SkipIterator<T, I> {
    _iter: I
    _count: usize
    _skipped: usize
    _peek: Option<T>
    _peeked: bool
}

imply SkipIterator<T, I>: Iterator {
    type Item = T;

    # 跳过阶段逐项消费底层 `next`：底层提前结束就如实结束，不猜测还有元素。
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

        while self._skipped < self._count {
            let dropped: Option<T> = self._iter.next()
            if dropped.is_none() {
                self._skipped = self._count
                return None
            }

            self._skipped = self._skipped + 1
        }

        return self._iter.next()
    }

    # 幂等观察：缓存空时沿唯一推进路径完成跳过阶段并取下一个元素，
    # 结果存入一格缓存；重复调用命中缓存，底层不会被多消费。
    micro has_next(mut self): bool
        where I: Iterator<Item = T>
    {
        if !self._peeked {
            while self._skipped < self._count {
                let dropped: Option<T> = self._iter.next()
                if dropped.is_none() {
                    self._skipped = self._count
                    self._peeked = true
                    return false
                }

                self._skipped = self._skipped + 1
            }

            self._peek = self._iter.next()
            self._peeked = true
        }

        return self._peek.is_some()
    }
}
