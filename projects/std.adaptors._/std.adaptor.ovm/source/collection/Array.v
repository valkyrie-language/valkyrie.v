namespace std.adaptor.ovm.collection;

# std.adaptor.ovm: `std::collection::push` 宿主绑定。
# 与 std.adaptor.wasm 同配方：新建长度 +1 的数组并逐项拷贝，末尾写入新元素；
# provider 只能特化合同，不得以空体替代实现。

[host_provider(std::collection::push)]
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
