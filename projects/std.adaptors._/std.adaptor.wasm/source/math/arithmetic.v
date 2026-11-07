namespace std.adaptor.wasm.math;

# std.adaptor.wasm: core 算术 host contract 的 WebAssembly 绑定
# [wasm_operator] 给出对应 wasm 助记符，由后端在编译期直接降低

#region i32 算术

[host_provider(std::primitive::__i32_add)] [wasm_operator("i32.add")] micro i32_add(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_sub)] [wasm_operator("i32.sub")] micro i32_sub(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_mul)] [wasm_operator("i32.mul")] micro i32_mul(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_div)] [wasm_operator("i32.div_s")] micro i32_div(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_rem)] [wasm_operator("i32.rem_s")] micro i32_rem(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_neg)] [wasm_operator("i32.neg")] micro i32_neg(a: i32): i32

[host_provider(std::primitive::__i32_eq)] [wasm_operator("i32.eq")] micro i32_eq(a: i32, b: i32): bool

[host_provider(std::primitive::__i32_lt)] [wasm_operator("i32.lt_s")] micro i32_lt(a: i32, b: i32): bool

[host_provider(std::primitive::__i32_and)] [wasm_operator("i32.and")] micro i32_and(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_or)] [wasm_operator("i32.or")] micro i32_or(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_xor)] [wasm_operator("i32.xor")] micro i32_xor(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_shl)] [wasm_operator("i32.shl")] micro i32_shl(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_shr)] [wasm_operator("i32.shr_s")] micro i32_shr(a: i32, b: i32): i32

#endregion

#region i64 算术

[host_provider(std::primitive::__i64_add)] [wasm_operator("i64.add")] micro i64_add(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_sub)] [wasm_operator("i64.sub")] micro i64_sub(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_mul)] [wasm_operator("i64.mul")] micro i64_mul(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_div)] [wasm_operator("i64.div_s")] micro i64_div(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_rem)] [wasm_operator("i64.rem_s")] micro i64_rem(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_neg)] [wasm_operator("i64.neg")] micro i64_neg(a: i64): i64

[host_provider(std::primitive::__i64_eq)] [wasm_operator("i64.eq")] micro i64_eq(a: i64, b: i64): bool

[host_provider(std::primitive::__i64_lt)] [wasm_operator("i64.lt_s")] micro i64_lt(a: i64, b: i64): bool

[host_provider(std::primitive::__i64_and)] [wasm_operator("i64.and")] micro i64_and(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_or)] [wasm_operator("i64.or")] micro i64_or(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_xor)] [wasm_operator("i64.xor")] micro i64_xor(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shl)] [wasm_operator("i64.shl")] micro i64_shl(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shr)] [wasm_operator("i64.shr_s")] micro i64_shr(a: i64, b: i64): i64

#endregion

#region f64 算术

[host_provider(std::primitive::__f64_add)] [wasm_operator("f64.add")] micro f64_add(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_sub)] [wasm_operator("f64.sub")] micro f64_sub(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_mul)] [wasm_operator("f64.mul")] micro f64_mul(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_div)] [wasm_operator("f64.div")] micro f64_div(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_neg)] [wasm_operator("f64.neg")] micro f64_neg(a: f64): f64

[host_provider(std::primitive::__f64_eq)] [wasm_operator("f64.eq")] micro f64_eq(a: f64, b: f64): bool

[host_provider(std::primitive::__f64_lt)] [wasm_operator("f64.lt")] micro f64_lt(a: f64, b: f64): bool

#endregion

#region f64 位模式重解释
# 只搬位、不做数值转换。opcode 由后端按助记符结构性冻结，不按函数名特判。
[host_provider(std::primitive::__f64_to_bits)] [wasm_operator("i64.reinterpret_f64")] micro f64_to_bits(a: f64): u64

[host_provider(std::primitive::__f64_from_bits)] [wasm_operator("f64.reinterpret_i64")] micro f64_from_bits(a: u64): f64

#endregion

#region f32 算术
# f32 是独立载体（`VALTYPE_F32` / 真实 4 字节），不得复用 f64 指令或载体。
# 算术与比较都在单精度上完成，不提升到 f64 再降回。

[host_provider(std::primitive::__f32_add)] [wasm_operator("f32.add")] micro f32_add(a: f32, b: f32): f32

[host_provider(std::primitive::__f32_sub)] [wasm_operator("f32.sub")] micro f32_sub(a: f32, b: f32): f32

[host_provider(std::primitive::__f32_mul)] [wasm_operator("f32.mul")] micro f32_mul(a: f32, b: f32): f32

[host_provider(std::primitive::__f32_div)] [wasm_operator("f32.div")] micro f32_div(a: f32, b: f32): f32

[host_provider(std::primitive::__f32_neg)] [wasm_operator("f32.neg")] micro f32_neg(a: f32): f32

[host_provider(std::primitive::__f32_eq)] [wasm_operator("f32.eq")] micro f32_eq(a: f32, b: f32): bool

[host_provider(std::primitive::__f32_lt)] [wasm_operator("f32.lt")] micro f32_lt(a: f32, b: f32): bool

#endregion

#region f32 位模式重解释
# 32 位位模式、`i32`/`u32` 同宽载体：只搬位，NaN payload 23 位与 -0.0/次正规保位。
[host_provider(std::primitive::__f32_to_bits)] [wasm_operator("i32.reinterpret_f32")] micro f32_to_bits(a: f32): u32

[host_provider(std::primitive::__f32_from_bits)] [wasm_operator("f32.reinterpret_i32")] micro f32_from_bits(a: u32): f32

#endregion
