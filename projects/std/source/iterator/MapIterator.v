namespace std.iterator;

structure MapIterator<T, U, I> {
    _iter: I
    _mapper: micro(T) -> U
}

imply MapIterator<T, U, I>: Iterator {
    type Item = U;

    # 底层 `next` 的 `Option` 就是全部事实：`None` 即结束，`Some` 才映射。
    micro next(mut self): Option<U>
        where I: Iterator<Item = T>
    {
        let item: Option<T> = self._iter.next()
        if item.is_none() {
            return None
        }

        return Some(self._mapper(item.unwrap()))
    }
}
