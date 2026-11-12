namespace std.iterator;

# 终结操作：全部以消费 `next` 的真实 `Option` 结果为唯一推进与结束事实。

micro for_each<I, T>(self: I, f: micro(T) -> unit): unit
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            return
        }

        f(item.unwrap())
    }
}

micro fold<I, T, U>(self: I, initial: U, f: micro(U, T) -> U): U
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut result: U = initial
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            return result
        }

        result = f(result, item.unwrap())
    }
}

micro reduce<I, T, U>(self: I, initial: U, f: micro(U, T) -> U): U
    where I: Iterator<Item = T>
{
    return fold(self, initial, f)
}

micro any<I, T>(self: I, pred: micro(T) -> bool): bool
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            return false
        }

        if pred(item.unwrap()) {
            return true
        }
    }
}

micro all<I, T>(self: I, pred: micro(T) -> bool): bool
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            return true
        }

        if !pred(item.unwrap()) {
            return false
        }
    }
}

micro find<I, T>(self: I, pred: micro(T) -> bool): Option<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            return None
        }

        if pred(item.unwrap()) {
            return item
        }
    }
}

micro first<I, T>(self: I): Option<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    return iter.next()
}

micro last<I, T>(self: I): Option<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut result: Option<T> = None
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            return result
        }

        result = item
    }
}

micro nth<I, T>(self: I, index: usize): Option<T>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut current: usize = 0
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            return None
        }

        if current == index {
            return item
        }

        current = current + 1
    }
}

micro position<I, T>(self: I, pred: micro(T) -> bool): Option<usize>
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut index: usize = 0
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            return None
        }

        if pred(item.unwrap()) {
            return Some(index)
        }

        index = index + 1
    }
}

micro contains<I, T>(self: I, value: T): bool
    where I: Iterator<Item = T>, T: Equal
{
    let mut iter: I = self
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            return false
        }

        if item.unwrap() == value {
            return true
        }
    }
}

micro count<I, T>(self: I): usize
    where I: Iterator<Item = T>
{
    let mut iter: I = self
    let mut result: usize = 0
    while iter.next().is_some() {
        result = result + 1
    }

    return result
}

# 数值终端：空迭代器返回 `None`；序判定直接消费 `std::operator::Ordering`
# （经 `Comparable` 的派生算子），不在这里做数值转译。
# `sum` / `product` 需要加法/乘法合同，std 尚无对应 operator，暂不提供。

micro max<I, T>(self: I): Option<T>
    where I: Iterator<Item = T>, T: std::operator::Comparable
{
    let mut iter: I = self
    let first: Option<T> = iter.next()
    if first.is_none() {
        return None
    }

    let mut best: T = first.unwrap()
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            break
        }

        let value: T = item.unwrap()
        if best < value {
            best = value
        }
    }

    return Some(best)
}

micro min<I, T>(self: I): Option<T>
    where I: Iterator<Item = T>, T: std::operator::Comparable
{
    let mut iter: I = self
    let first: Option<T> = iter.next()
    if first.is_none() {
        return None
    }

    let mut best: T = first.unwrap()
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            break
        }

        let value: T = item.unwrap()
        if value < best {
            best = value
        }
    }

    return Some(best)
}
