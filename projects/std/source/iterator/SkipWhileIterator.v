namespace std.iterator;

structure SkipWhileIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
    _skipped: bool
    _peek: Option<T>
    _peeked: bool
}

imply SkipWhileIterator<T, I>: Iterator {
    type Item = T;

    # 跳过前缀阶段逐项消费底层 `next` 的真实结果：底层提前结束就如实结束。
    # 谓词对每个元素恰好执行一次；一旦谓词失败，前缀跳过完成，此后直通底层。
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

        if !self._skipped {
            while true {
                let item: Option<T> = self._iter.next()
                if item.is_none() {
                    self._skipped = true
                    return None
                }

                let value: T = item.unwrap()
                if !self._predicate(value) {
                    self._skipped = true
                    return Some(value)
                }
            }
        }

        return self._iter.next()
    }

    # 幂等观察：缓存空时沿唯一推进路径扫到「首个未通过谓词的元素」或底层耗尽，
    # 结果存入一格缓存；谓词每元素恰好执行一次，重复调用命中缓存。
    micro has_next(mut self): bool
        where I: Iterator<Item = T>
    {
        if !self._peeked {
            if !self._skipped {
                while true {
                    let item: Option<T> = self._iter.next()
                    if item.is_none() {
                        self._skipped = true
                        self._peeked = true
                        return false
                    }

                    let value: T = item.unwrap()
                    if !self._predicate(value) {
                        self._skipped = true
                        self._peek = Some(value)
                        self._peeked = true
                        return true
                    }
                }
            }

            self._peek = self._iter.next()
            self._peeked = true
        }

        return self._peek.is_some()
    }
}
