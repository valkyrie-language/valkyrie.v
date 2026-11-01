namespace std.adaptor.ovm.collection;

# `std.collection.array` 合同经 `nyar.host` 正式宿主导入实现（无 intrinsic、无名字表）：
# OVM 在加载期把 `array.new`/`array.length`/`array.get`/`array.set` 解析为冻结的
# `HostOp`，热路径按枚举分派操作 `LayoutObject` 元素槽；未知符号加载期拒绝。

[host_provider(std::collection::array::length)]
private micro array_host_length<T>(array: [T]): usize {
    return __array_ovm_length::<T>(array)
}

[host_provider(std::collection::array::get)]
private micro array_host_get<T>(array: [T], index: usize): T {
    return __array_ovm_get::<T>(array, index)
}

[host_provider(std::collection::array::set)]
private micro array_host_set<T>(array: [T], index: usize, value: T): unit {
    __array_ovm_set::<T>(array, index, value)
}

[host_provider(std::collection::array::new)]
private micro array_host_new<T>(length: usize): [T] {
    return __array_ovm_new::<T>(length)
}

[ovm("array.length"), pure]
private micro __array_ovm_length<T>(array: [T]): usize { }

[ovm("array.get"), pure]
private micro __array_ovm_get<T>(array: [T], index: usize): T { }

[ovm("array.set")]
private micro __array_ovm_set<T>(array: [T], index: usize, value: T): unit { }

[ovm("array.new"), pure]
private micro __array_ovm_new<T>(length: usize): [T] { }
