# std.adaptor.nyar: 内存操作 [ovm] 宿主绑定
# 将 valkyrie-core 的内存操作映射为 NyarVM opcode
# OVM runtime 提供对应的内存宿主函数

#region 分配与释放

[ovm("alloc")]
micro alloc(size: i32): i32

[ovm("free")]
micro free(ptr: i32): i32

#endregion

#region i32 加载与存储

[ovm("i32_load")]
micro i32_load(ptr: i32, offset: i32): i32

[ovm("i32_store")]
micro i32_store(ptr: i32, offset: i32, value: i32): i32

#endregion

#region i64 加载与存储

[ovm("i64_load")]
micro i64_load(ptr: i32, offset: i32): i64

[ovm("i64_store")]
micro i64_store(ptr: i32, offset: i32, value: i64): i32

#endregion

#region 批量操作

[ovm("mem_copy")]
micro mem_copy(dst: i32, src: i32, length: i32): i32

[ovm("mem_set")]
micro mem_set(dst: i32, value: i32, length: i32): i32

#endregion