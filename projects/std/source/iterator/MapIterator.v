namespace std.iterator;

structure MapIterator<T, U, I> {
    _iter: I
    _mapper: micro(T) -> U
    _peek: Option<U>
    _peeked: bool
}

imply MapIterator<T, U, I>: Iterator {
    type Item = U;

    # 底层 `next` 的 `Option` 就是全部事实：`None` 即结束，`Some` 才映射。
    # mapper 每元素恰好执行一次：映射结果存入一格缓存，`next` 只交出。
    micro next(mut self): Option<U>
        where I: Iterator<Item = T>
    {
        if self._peeked {
            self._peeked = false
            let cached: Option<U> = self._peek
            let empty: Option<U> = None
            self._peek = empty
            return cached
        }

        let item: Option<T> = self._iter.next()
        if item.is_none() {
            return None
        }

        return Some(self._mapper(item.unwrap()))
    }

    # 幂等观察：缓存空时恰好推进底层一次并完成映射，结果存入一格缓存；
    # 重复调用命中缓存，mapper 不会二次执行。
    micro has_next(mut self): bool
        where I: Iterator<Item = T>
    {
        if !self._peeked {
            let item: Option<T> = self._iter.next()
            if item.is_some() {
                self._peek = Some(self._mapper(item.unwrap()))
            }

            self._peeked = true
        }

        return self._peek.is_some()
    }
}
