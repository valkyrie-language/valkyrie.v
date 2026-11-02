namespace std.adaptor.clr.collection;

# `std.collection.array` 合同经 `System.Array` 正式导入实现（无 intrinsic、无名字表）。

[host_provider(std::collection::array::length)]
private micro array_host_length<T>(array: [T]): usize {
    return __array_clr_length::<T>(array)
}

[host_provider(std::collection::array::get)]
private micro array_host_get<T>(array: [T], index: usize): T {
    return __array_clr_get::<T>(array, index)
}

[host_provider(std::collection::array::set)]
private micro array_host_set<T>(array: [T], index: usize, value: T): unit {
    __array_clr_set::<T>(array, index, value)
}

[host_provider(std::collection::array::new)]
private micro array_host_new<T>(length: usize): [T] {
    return __array_clr_new::<T>(length)
}

[clr("System.Runtime", "System.Array", "get_Length"), pure]
private micro __array_clr_length<T>(array: [T]): usize { }

[clr("System.Runtime", "System.Array", "GetValue"), pure]
private micro __array_clr_get<T>(array: [T], index: usize): T { }

[clr("System.Runtime", "System.Array", "SetValue")]
private micro __array_clr_set<T>(array: [T], index: usize, value: T): unit { }

# `Array.CreateInstance(Type, Int32)`：元素类型参数由后端按 `T` 合成（编码能力待后端复核，
# 不通过则按 clr 目标私有合同失败，不得回退旧实现通道）。
[clr("System.Runtime", "System.Array", "CreateInstance"), pure]
private micro __array_clr_new<T>(length: usize): [T] { }
