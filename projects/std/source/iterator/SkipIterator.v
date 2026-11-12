namespace std.iterator;

structure SkipIterator<T, I> {
    _iter: I
    _count: usize
    _skipped: usize
}

imply SkipIterator<T, I>: Iterator {
    type Item = T;

    # 跳过阶段逐项消费底层 `next`：底层提前结束就如实结束，不猜测还有元素。
    micro next(mut self): Option<T>
        where I: Iterator<Item = T>
    {
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
}
