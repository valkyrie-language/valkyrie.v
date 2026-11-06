namespace std.iterator;

# 逆序迭代器：缓冲源迭代器的全部产出，再按尾到头逐项交出。
# 缓冲在构造期完成（`rev`），`has_next(self)` 只做只读游标判断。
structure ReverseIterator<T> {
    _buffer: std.collection.ArrayList<T>
    _index: usize
}

imply ReverseIterator<T>: Iterator {
    type Item = T;

    micro has_next(self): bool {
        return self._index > 0
    }

    micro next(mut self): Option<T> {
        if self._index == 0 {
            return None
        }

        self._index = self._index - 1
        return self._buffer.get((self._index + 1) as isize)
    }
}

# 逆序适配入口：即时消费源迭代器，拒绝惰性填充。
# `has_next(self)` 是只读接收者，不能在探测阶段持久扩容缓冲，因此先排空再产出。
# 作为自由函数而非 trait 默认成员：默认成员里用关联类型 `Item` 构造泛型容器
# 目前无法通过类型检查。
micro rev<I, T>(source: I) -> ReverseIterator<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = source
    let mut buffer: std::collection::ArrayList<T> = std::collection::ArrayList::new(0)
    while iter.has_next() {
        buffer.push(iter.next().unwrap())
    }

    return ReverseIterator {
        _buffer: buffer,
        _index: buffer.length(),
    }
}
