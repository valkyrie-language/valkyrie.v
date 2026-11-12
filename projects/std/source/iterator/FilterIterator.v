namespace std.iterator;

structure FilterIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
    _peek: Option<T>
    _peeked: bool
}

imply FilterIterator<T, I>: Iterator {
    type Item = T;

    # 谓词每元素恰好执行一次：推进与判定只发生在缓存未命中的那一条路径上，
    # 判定通过的元素存入一格缓存；不存在「先探测再取值」的第二次判定。
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

        while true {
            let item: Option<T> = self._iter.next()
            if item.is_none() {
                return None
            }

            let value: T = item.unwrap()
            if self._predicate(value) {
                return Some(value)
            }
        }
    }

    # 幂等观察：缓存空时沿唯一推进路径扫到底层 `None` 或首个通过谓词的元素，
    # 结果存入一格缓存；重复调用命中缓存，谓词不会二次执行。
    micro has_next(mut self): bool
        where I: Iterator<Item = T>
    {
        if !self._peeked {
            while true {
                let item: Option<T> = self._iter.next()
                if item.is_none() {
                    self._peeked = true
                    return false
                }

                let value: T = item.unwrap()
                if self._predicate(value) {
                    self._peek = Some(value)
                    self._peeked = true
                    return true
                }
            }
        }

        return self._peek.is_some()
    }
}
