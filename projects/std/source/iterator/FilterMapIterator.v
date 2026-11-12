namespace std.iterator;

structure FilterMapIterator<T, U, I> {
    _iter: I
    _mapper: micro(T) -> Option<U>
    _peek: Option<U>
    _peeked: bool
}

imply FilterMapIterator<T, U, I>: Iterator {
    type Item = U;

    # 映射函数可以把剩余元素全部变成 `None`：结束与否由「底层 `next` 返回
    # `None`」判定，而不是由底层是否还能推进判定。逐项映射，映射出的 `None`
    # 被跳过，`Some` 直接交出。mapper 每元素恰好执行一次。
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

        while true {
            let item: Option<T> = self._iter.next()
            if item.is_none() {
                return None
            }

            let mapped: Option<U> = self._mapper(item.unwrap())
            if mapped.is_some() {
                return mapped
            }
        }
    }

    # 幂等观察：缓存空时沿唯一推进路径逐项映射，直到底层耗尽或产出首个
    # `Some` 才回答；结果存入一格缓存，mapper 不会二次执行。
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

                let mapped: Option<U> = self._mapper(item.unwrap())
                if mapped.is_some() {
                    self._peek = mapped
                    self._peeked = true
                    return true
                }
            }
        }

        return self._peek.is_some()
    }
}
