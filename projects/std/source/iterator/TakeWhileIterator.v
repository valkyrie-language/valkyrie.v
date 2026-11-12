namespace std.iterator;

structure TakeWhileIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
    _done: bool
}

imply TakeWhileIterator<T, I>: Iterator {
    type Item = T;

    # 谓词失败的元素被消费且不产出——这是 `take_while` 的语义事实；此后本迭代器
    # 不再触碰底层。结束与否由底层 `next` 的 `Option` 决定，不预先探测。
    micro next(mut self): Option<T>
        where I: Iterator<Item = T>
    {
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
}
