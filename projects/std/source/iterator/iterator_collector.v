namespace std.iterator;

micro collect<I, T, C>(self: I) -> C
    where I: Iterator<Item = T>, C: FromIterator<Item = T>
{
    return C::from_iterator(self)
}

micro collect_array<I, T>(self: I) -> [T]
    where I: Iterator<Item = T>
{
    # 定长数组只能整体落成：先经 `ArrayList` 原地追加累积，再一次性冻结拷贝。
    let mut buffer: std.collection.ArrayList<T> = std.collection.ArrayList::new(0)
    let mut iter: I = self
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            break
        }

        buffer.push(item.unwrap())
    }

    return buffer.to_array()
}

micro collect_array_list<I, T>(self: I) -> std.collection.ArrayList<T>
    where I: Iterator<Item = T>
{
    let mut result: std.collection.ArrayList<T> = std.collection.ArrayList::new(0)
    let mut iter: I = self
    while true {
        let item: Option<T> = iter.next()
        if item.is_none() {
            break
        }

        result.push(item.unwrap())
    }

    return result
}
