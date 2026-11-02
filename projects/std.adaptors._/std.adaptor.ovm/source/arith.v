# std.adaptor.ovm: 算术运算 [ovm_operator] 绑定
# 将 valkyrie-core 的算术运算映射为 OVM opcode
# 编译器使用 [ovm_operator] 绑定直接内联为对应指令，零函数调用开销

#region i32 算术

[host_provider(std::primitive::__i32_add)]
[ovm_operator("i32.add")]
micro i32_add(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_sub)]
[ovm_operator("i32.sub")]
micro i32_sub(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_mul)]
[ovm_operator("i32.mul")]
micro i32_mul(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_div)]
[ovm_operator("i32.div")]
micro i32_div(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_rem)]
[ovm_operator("i32.rem")]
micro i32_rem(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_neg)]
[ovm_operator("i32.neg")]
micro i32_neg(a: i32): i32

#endregion

#region i32 位运算
# 与/或/异或/左移/算术右移是 VM 冻结的 `I32And`/`I32Or`/`I32Xor`/`I32Shl`/`I32ShrS` 头码，
# 与 i32 算术同轨经 `[ovm_operator]` 冻结助记符内联，零函数调用开销。
# VM 没有按位取反指令，std 侧也不存在 `__i32_not` 合同，保持无声明而不是用多指令配方伪造。

[host_provider(std::primitive::__i32_and)]
[ovm_operator("i32.and")]
micro i32_and(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_or)]
[ovm_operator("i32.or")]
micro i32_or(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_xor)]
[ovm_operator("i32.xor")]
micro i32_xor(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_shl)]
[ovm_operator("i32.shl")]
micro i32_shl(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_shr)]
[ovm_operator("i32.shr_s")]
micro i32_shr(a: i32, b: i32): i32

#endregion

#region i64 算术

[host_provider(std::primitive::__i64_add)]
[ovm("i64_add")]
micro i64_add(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_sub)]
[ovm("i64_sub")]
micro i64_sub(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_mul)]
[ovm("i64_mul")]
micro i64_mul(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_div)]
[ovm("i64_div")]
micro i64_div(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_rem)]
[ovm("i64_rem")]
micro i64_rem(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_neg)]
[ovm("i64_neg")]
micro i64_neg(a: i64): i64

#endregion

#region i64 比较

[host_provider(std::primitive::__i64_eq)]
[ovm("i64_eq")]
micro i64_eq(a: i64, b: i64): bool

[ovm("i64_ne")]
micro i64_ne(a: i64, b: i64): bool

[host_provider(std::primitive::__i64_lt)]
[ovm("i64_lt")]
micro i64_lt(a: i64, b: i64): bool

[ovm("i64_le")]
micro i64_le(a: i64, b: i64): bool

[ovm("i64_gt")]
micro i64_gt(a: i64, b: i64): bool

[ovm("i64_ge")]
micro i64_ge(a: i64, b: i64): bool

#endregion

#region i64 位运算
# OVM 没有 i64 头码：与 i64 算术/比较同轨，经 `nyar.host` 冻结宿主导入服务，
# 符号由 runtime `parse_host_op` 解析，未知符号在模块加载期结构化失败。

[host_provider(std::primitive::__i64_and)]
[ovm("i64_and")]
micro i64_and(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_or)]
[ovm("i64_or")]
micro i64_or(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_xor)]
[ovm("i64_xor")]
micro i64_xor(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shl)]
[ovm("i64_shl")]
micro i64_shl(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shr)]
[ovm("i64_shr")]
micro i64_shr(a: i64, b: i64): i64

#endregion

#region f64 算术

[host_provider(std::primitive::__f64_add)]
[ovm("f64_add")]
micro f64_add(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_sub)]
[ovm("f64_sub")]
micro f64_sub(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_mul)]
[ovm("f64_mul")]
micro f64_mul(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_div)]
[ovm("f64_div")]
micro f64_div(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_neg)]
[ovm("f64_neg")]
micro f64_neg(a: f64): f64

#endregion
