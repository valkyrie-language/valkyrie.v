namespace std.iterator;

structure FilterMapIterator<T, U, I> {
    _iter: I
    _mapper: micro(T) -> Option<U>
}

imply FilterMapIterator<T, U, I>: Iterator {
    type Item = U;

    # 映射函数可以把剩余元素全部变成 `None`：结束与否由「底层 `next` 返回
    # `None`」判定，而不是由底层是否还能推进判定。逐项映射，映射出的 `None`
    # 被跳过，`Some` 直接交出。
    micro next(mut self): Option<U>
        where I: Iterator<Item = T>
    {
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
}
