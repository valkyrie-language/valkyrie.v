namespace std.iterator;

# 预看迭代器：协议里没有预探测义务，预看是缓存出来的能力。
#
# 语义合同：
# - 至多缓存一个元素。`peek` 从底层迭代器多取一步并原地存下，重复 `peek`
#   命中缓存、不再推进底层；
# - `next` 先交缓存、再走底层，与未包装时产出序列逐项一致；
# - 底层返回 `None` 即记为耗尽，此后不再触碰底层。
structure Peekable<T, I> {
    _iter: I
    _peeked: Option<T>
    _exhausted: bool
}

imply Peekable<T, I>: Iterator {
    type Item = T;

    micro next(mut self): Option<T>
        where I: Iterator<Item = T>
    {
        if self._peeked.is_some() {
            let item: Option<T> = self._peeked
            let empty: Option<T> = None
            self._peeked = empty
            return item
        }

        if self._exhausted {
            return None
        }

        let pulled: Option<T> = self._iter.next()
        if pulled.is_none() {
            self._exhausted = true
        }

        return pulled
    }

    # 预看下一个元素：不消费，至多让底层前进一步。
    micro peek(mut self): Option<T>
        where I: Iterator<Item = T>
    {
        if self._peeked.is_some() {
            return self._peeked
        }

        if self._exhausted {
            return None
        }

        let pulled: Option<T> = self._iter.next()
        if pulled.is_some() {
            self._peeked = pulled
        }
        else {
            self._exhausted = true
        }

        return pulled
    }
}
