namespace std.adaptor.ovm.collection;

# OVM 没有独立的可变长容器宿主类型：`ArrayList` 的载体是定长数组槽
# （`array.new`/`array.length`/`array.get`/`array.set` 四个冻结 `HostOp`）。
# 本文件的 provider 以同一组宿主原语落实 `ArrayList` 合同，不在后端重写扩容/搬移
# 语义之外的东西：容量不足时仍按倍增扩容，逻辑长度只由 `_length` 决定。

[host_provider(std::collection::ArrayList::new)]
private micro array_list_host_new<T>(capacity: usize): std.collection.ArrayList<T> {
    return std.collection.ArrayList {
        _items: std::collection::array::new::<T>(capacity),
        _length: 0,
    }
}

[host_provider(std::collection::ArrayList::capacity)]
private micro array_list_host_capacity<T>(list: std.collection.ArrayList<T>): usize {
    return list._items.length
}

[host_provider(std::collection::ArrayList::push)]
private micro array_list_host_push<T>(list: std.collection.ArrayList<T>, value: T): unit {
    if list._length >= list._items.length {
        list.reserve_grow()
    }

    list._items⁅list._length⁆ = value
    list._length = list._length + 1
}

[host_provider(std::collection::ArrayList::clear)]
private micro array_list_host_clear<T>(list: std.collection.ArrayList<T>): unit {
    list._length = 0
}

[host_provider(std::collection::ArrayList::insert)]
private micro array_list_host_insert<T>(list: std.collection.ArrayList<T>, ordinal: usize, value: T): unit {
    let size: usize = list._length
    if ordinal == 0 || ordinal > size + 1 {
        return
    }

    if size >= list._items.length {
        list.reserve_grow()
    }

    let mut cursor: usize = size
    while cursor >= ordinal {
        list._items⁅cursor⁆ = list._items⁅cursor - 1⁆
        cursor = cursor - 1
    }

    list._items⁅ordinal - 1⁆ = value
    list._length = size + 1
}

[host_provider(std::collection::ArrayList::remove)]
private micro array_list_host_remove<T>(list: std.collection.ArrayList<T>, ordinal: usize): Option<T> {
    let size: usize = list._length
    if ordinal == 0 || ordinal > size {
        return None
    }

    let removed: T = list._items⁅ordinal - 1⁆
    let mut cursor: usize = ordinal
    while cursor < size {
        list._items⁅cursor - 1⁆ = list._items⁅cursor⁆
        cursor = cursor + 1
    }

    list._length = size - 1
    return Some(removed)
}

[host_provider(std::collection::ArrayList::length)]
private micro array_list_host_length<T>(list: std.collection.ArrayList<T>): usize {
    return list._length
}

[host_provider(std::collection::ArrayList::at)]
private micro array_list_host_at<T>(list: std.collection.ArrayList<T>, ordinal: usize): T {
    return list[ordinal as isize]
}

[host_provider(std::collection::ArrayList::contains)]
private micro array_list_host_contains<T>(list: std.collection.ArrayList<T>, value: T): bool
    where T: Equal
{
    let mut index: usize = 0
    while index < list._length {
        if list._items⁅index⁆ == value {
            return true
        }

        index = index + 1
    }

    return false
}
