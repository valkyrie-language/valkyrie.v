namespace std.adaptor.ovm.collection;

# std.adaptor.ovm: `std::collection::push` 宿主绑定。
# 与 std.adaptor.wasm 同配方：新建长度 +1 的数组并逐项拷贝，末尾写入新元素；
# provider 只能特化合同，不得以空体替代实现。

# 按长度构造 `[T]`：与 `builtin.array.length` / `builtin.array.get` / `builtin.array.set`
# 同族的语言结构语义声明；这里只重复冻结同一身份，不引入目标指令或后端名字表。
[intrinsic("builtin.array.new")]
private micro __array_new<T>(length: usize): [T] { }

[host_provider(std::collection::push)]
private micro array_host_push<T>(array: [T], value: T): [T] {
    let old_len: usize = array.length
    let mut new_array: [T] = __array_new::<T>(old_len + 1)
    let mut i: usize = 0
    while i < old_len {
        new_array::[i] = array::[i]
        i = i + 1
    }
    new_array::[old_len] = value
    return new_array
}
