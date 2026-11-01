# std.adaptor.clr: 算术运算 [clr_operator] 绑定
# 将 valkyrie-core 的算术运算映射为 MSIL 单 opcode
# 编译器使用 [clr_operator] 绑定直接内联为对应指令，零函数调用开销
# MSIL 算术/比较 opcode 与数值载体无关，因此助记符携带载体限定名。

#region i32 算术

[host_provider(std::primitive::__i32_add)]
[clr_operator("i32.add")]
micro i32_add(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_sub)]
[clr_operator("i32.sub")]
micro i32_sub(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_mul)]
[clr_operator("i32.mul")]
micro i32_mul(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_div)]
[clr_operator("i32.div")]
micro i32_div(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_rem)]
[clr_operator("i32.rem")]
micro i32_rem(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_neg)]
[clr_operator("i32.neg")]
micro i32_neg(a: i32): i32

#endregion

#region i64 算术

[host_provider(std::primitive::__i64_add)]
[clr_operator("i64.add")]
micro i64_add(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_sub)]
[clr_operator("i64.sub")]
micro i64_sub(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_mul)]
[clr_operator("i64.mul")]
micro i64_mul(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_div)]
[clr_operator("i64.div")]
micro i64_div(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_rem)]
[clr_operator("i64.rem")]
micro i64_rem(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_neg)]
[clr_operator("i64.neg")]
micro i64_neg(a: i64): i64

#endregion

#region i64 位运算
# `and`/`or`/`xor` 为单 opcode；`shl`/`shr` 的位移量是 `int32`，
# `i64` 位移量的 `conv.i4` 截窄由 CLR backend 冻结配方显式给出，不在本文件推断。

[host_provider(std::primitive::__i64_and)]
[clr_operator("i64.and")]
micro i64_and(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_or)]
[clr_operator("i64.or")]
micro i64_or(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_xor)]
[clr_operator("i64.xor")]
micro i64_xor(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shl)]
[clr_operator("i64.shl")]
micro i64_shl(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shr)]
[clr_operator("i64.shr")]
micro i64_shr(a: i64, b: i64): i64

#endregion

#region f64 算术
# MSIL `neg` 对浮点保留 -0.0，与语言语义一致。

[host_provider(std::primitive::__f64_add)]
[clr_operator("f64.add")]
micro f64_add(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_sub)]
[clr_operator("f64.sub")]
micro f64_sub(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_mul)]
[clr_operator("f64.mul")]
micro f64_mul(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_div)]
[clr_operator("f64.div")]
micro f64_div(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_neg)]
[clr_operator("f64.neg")]
micro f64_neg(a: f64): f64

#endregion

#region 比较
# 只绑定项目已声明的 `eq` / `lt` host 合同；返回类型必须与合同声明同源（`bool`），
# MSIL 比较 opcode 压入的结果槽由冻结计划的 `result_type = I32` 承载。

[host_provider(std::primitive::__i32_eq)]
[clr_operator("i32.eq")]
micro i32_eq(a: i32, b: i32): bool

[host_provider(std::primitive::__i32_lt)]
[clr_operator("i32.lt")]
micro i32_lt(a: i32, b: i32): bool

[host_provider(std::primitive::__i64_eq)]
[clr_operator("i64.eq")]
micro i64_eq(a: i64, b: i64): bool

[host_provider(std::primitive::__i64_lt)]
[clr_operator("i64.lt")]
micro i64_lt(a: i64, b: i64): bool

#endregion
