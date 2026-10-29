namespace std.adaptor.wasm.collection;

[host_provider(std::collection::Array::length)]
private micro array_host_length<T>(array: [T]): usize {
    return array.length
}

[host_provider(std::collection::Array::get)]
private micro array_host_get<T>(array: [T], ordinal: usize): Option<T> {
    let item_count: usize = array.length
    if ordinal == 0 || ordinal > item_count {
        return None
    }

    return Some(array::[ordinal - 1])
}

[host_provider(std::collection::Array::set)]
private micro array_host_set<T>(mut array: [T], ordinal: usize, value: T): unit {
    let item_count: usize = array.length
    if ordinal == 0 || ordinal > item_count {
        return
    }

    array::[ordinal - 1] = value
}

[host_provider(std::collection::Array::push)]
private micro array_host_push<T>(array: [T], value: T): [T] {
    let old_len: usize = array.length
    let mut new_array: [T] = new [T](old_len + 1)
    let mut i: usize = 0
    while i < old_len {
        new_array::[i] = array::[i]
        i = i + 1
    }
    new_array::[old_len] = value
    return new_array
}
