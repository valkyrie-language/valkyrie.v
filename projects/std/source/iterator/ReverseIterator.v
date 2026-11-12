namespace std.iterator;

# 逆序迭代器：缓冲源迭代器的全部产出，再按尾到头逐项交出。
# 单向源无法从尾部起推进，逆序只能以先排空为代价；缓冲在构造期一次完成，
# `next` 只做只读游标回退。
structure ReverseIterator<T> {
    _buffer: std.collection.ArrayList<T>
    _index: usize
}

imply ReverseIterator<T>: Iterator {
    type Item = T;

    micro next(mut self): Option<T> {
        if self._index == 0 {
            return None
        }

        self._index = self._index - 1
        return self._buffer.get((self._index + 1) as isize)
    }

    # 幂等观察：产出已全部物化进缓冲，`next` 的结局只由游标决定——
    # 纯计算直接判定，不触碰缓冲、不推进游标，重复调用答案不变。
    micro has_next(mut self): bool {
        return self._index != 0
    }
}

# 逆序适配入口：即时消费源迭代器，拒绝惰性填充。
# 作为自由函数而非 trait 默认成员：逆序需要物化全部产出，这是入口的领域代价，
# 不伪装成零成本的适配器。
micro reverse<I, T>(source: I) -> ReverseIterator<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = source
    let mut buffer: std::collection::ArrayList<T> = std::collection::ArrayList::new(0)
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            break
        }

        buffer.push(item.unwrap())
    }

    return ReverseIterator {
        _buffer: buffer,
        _index: buffer.length(),
    }
}
