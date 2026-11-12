namespace std.iterator;

structure SkipWhileIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
    _skipped: bool
}

imply SkipWhileIterator<T, I>: Iterator {
    type Item = T;

    # 跳过前缀阶段逐项消费底层 `next` 的真实结果：底层提前结束就如实结束。
    # 谓词对每个元素恰好执行一次；一旦谓词失败，前缀跳过完成，此后直通底层。
    micro next(mut self): Option<T>
        where I: Iterator<Item = T>
    {
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
}
