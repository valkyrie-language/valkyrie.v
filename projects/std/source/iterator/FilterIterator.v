namespace std.iterator;

structure FilterIterator<T, I> {
    _iter: I
    _predicate: micro(T) -> bool
}

imply FilterIterator<T, I>: Iterator {
    type Item = T;

    # 谓词每元素恰好执行一次：推进与判定都只发生在 `next` 这一条路径上，
    # 不存在「先探测再取值」的第二次判定。
    micro next(mut self): Option<T>
        where I: Iterator<Item = T>
    {
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
}
