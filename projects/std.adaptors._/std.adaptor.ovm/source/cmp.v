# std.adaptor.ovm: 比较运算 [ovm_operator] 绑定
# 将 valkyrie-core 的比较运算映射为 OVM opcode
# bool 逻辑保留 Valkyrie 短路求值实现，不在此处绑定

#region i32 比较

[host_provider(core::primitive::__i32_eq)]
[ovm_operator("i32.eq")]
micro i32_eq(a: i32, b: i32): bool

[ovm_operator("i32.ne")]
micro i32_ne(a: i32, b: i32): bool

[host_provider(core::primitive::__i32_lt)]
[ovm_operator("i32.lt")]
micro i32_lt(a: i32, b: i32): bool

[ovm_operator("i32.le")]
micro i32_le(a: i32, b: i32): bool

[ovm_operator("i32.gt")]
micro i32_gt(a: i32, b: i32): bool

[ovm_operator("i32.ge")]
micro i32_ge(a: i32, b: i32): bool

#endregion