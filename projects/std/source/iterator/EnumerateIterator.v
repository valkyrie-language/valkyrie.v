namespace std.iterator;

# 枚举项：序号 + 原值。
#
# 用具名 `structure` 而不是具名元组 `(ordinal: usize, value: T)`：具名元组的标签只
# 能靠期望类型在字面量处精化，而 `next` 的泛型体在跨包构建里冻结后拿不到该精化，
# `(ordinal, value)` 会落成匿名元组，与具名声明不兼容。这里改成与声明同名的字段
# 构造，泛型与非泛型、包内与跨包都成立。
structure EnumerateItem<T> {
    ordinal: usize
    value: T
}

structure EnumerateIterator<T, I> {
    _iter: I
    _ordinal: usize
}

imply EnumerateIterator<T, I>: Iterator {
    type Item = EnumerateItem<T>;

    micro has_next(self): bool
        where I: Iterator<Item = T>
    {
        return self._iter.has_next()
    }

    micro next(mut self): Option<EnumerateItem<T>>
        where I: Iterator<Item = T>
    {
        if !self._iter.has_next() {
            let empty: Option<EnumerateItem<T>> = None
            return empty
        }

        let ordinal: usize = self._ordinal
        let value: T = self._iter.next().unwrap()
        self._ordinal = self._ordinal + 1
        return Some { value: EnumerateItem { ordinal: ordinal, value: value } }
    }
}
