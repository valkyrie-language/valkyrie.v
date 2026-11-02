namespace std.adaptor.jvm.collection;

# `std.collection.array` 合同经 `java.lang.reflect.Array` 正式导入实现（无 intrinsic、无名字表）。

[host_provider(std::collection::array::length)]
private micro array_host_length<T>(array: [T]): usize {
    return __array_jvm_length::<T>(array)
}

[host_provider(std::collection::array::get)]
private micro array_host_get<T>(array: [T], index: usize): T {
    return __array_jvm_get::<T>(array, index)
}

[host_provider(std::collection::array::set)]
private micro array_host_set<T>(array: [T], index: usize, value: T): unit {
    __array_jvm_set::<T>(array, index, value)
}

[host_provider(std::collection::array::new)]
private micro array_host_new<T>(length: usize): [T] {
    return __array_jvm_new::<T>(length)
}

[jvm("java.lang.reflect.Array", "getLength"), pure]
private micro __array_jvm_length<T>(array: [T]): usize { }

[jvm("java.lang.reflect.Array", "get"), pure]
private micro __array_jvm_get<T>(array: [T], index: usize): T { }

[jvm("java.lang.reflect.Array", "set")]
private micro __array_jvm_set<T>(array: [T], index: usize, value: T): unit { }

# `newInstance(Class, int)`：组件类型参数由后端按 `T` 合成（编码能力待后端复核，
# 不通过则按 jvm 目标私有合同失败，不得回退旧实现通道）。
[jvm("java.lang.reflect.Array", "newInstance"), pure]
private micro __array_jvm_new<T>(length: usize): [T] { }
