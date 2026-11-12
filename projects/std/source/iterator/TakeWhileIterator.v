namespace std.iterator;

structure TakeWhileIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
    _done: bool
    _peek: Option<T>
    _peeked: bool
}

imply TakeWhileIterator<T, I>: Iterator {
    type Item = T;

    # 谓词失败的元素被消费且不产出——这是 `take_while` 的语义事实；此后本迭代器
    # 不再触碰底层。结束与否由底层 `next` 的 `Option` 决定。
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

        if self._done {
            return None
        }

        let item: Option<T> = self._iter.next()
        if item.is_none() {
            return None
        }

        let value: T = item.unwrap()
        if self._predicate(value) {
            return Some(value)
        }

        self._done = true
        return None
    }

    # 幂等观察：缓存空时沿唯一推进路径取下一个元素并按谓词裁决，
    # 通过则存入一格缓存；谓词失败置 done 且不触碰底层，每元素恰好执行一次。
    micro has_next(mut self): bool
        where I: Iterator<Item = T>
    {
        if !self._peeked {
            if self._done {
                self._peeked = true
                return false
            }

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

            self._done = true
            self._peeked = true
            return false
        }

        return self._peek.is_some()
    }
}
