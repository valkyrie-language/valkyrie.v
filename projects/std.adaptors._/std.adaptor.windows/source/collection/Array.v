namespace std.adaptor.windows.collection;

# `std.collection.array` 合同经 x86-64 机器码目标 operator 绑定实现
# （无 intrinsic、无名字表）：助记符在计划构造期冻结为数组计划（arity 与操作身份），
# 机器后端按冻结表示发射——`[0]` 是元素个数，元素从 `+8` 起按 8 字节槽排列。
# 越界与初始化前沿等集合语义全部留在 `std`，本适配器只绑定机械读写与分配。

[host_provider(std::collection::array::length)]
private micro array_host_length<T>(array: [T]): usize {
    return __array_x86_64_length::<T>(array)
}

[host_provider(std::collection::array::get)]
private micro array_host_get<T>(array: [T], index: usize): T {
    return __array_x86_64_get::<T>(array, index)
}

[host_provider(std::collection::array::set)]
private micro array_host_set<T>(array: [T], index: usize, value: T): unit {
    __array_x86_64_set::<T>(array, index, value)
}

[host_provider(std::collection::__array_slots)]
private micro array_host_allocate<T>(capacity: usize): [T] {
    return __array_x86_64_new::<T>(capacity)
}

[x86_64_operator("array.length"), pure]
private micro __array_x86_64_length<T>(array: [T]): usize { }

[x86_64_operator("array.get"), pure]
private micro __array_x86_64_get<T>(array: [T], index: usize): T { }

[x86_64_operator("array.set")]
private micro __array_x86_64_set<T>(array: [T], index: usize, value: T): unit { }

[x86_64_operator("array.new"), pure]
private micro __array_x86_64_new<T>(length: usize): [T] { }
