namespace std.adaptor.windows.math;

# std.adaptor.windows: core 算术 host contract 的 x86-64 绑定
# `[x86_64_operator]` 只声明 ISA 助记符，机器码由 machine backend 在编译期按冻结配方编码。
# 整数算术/位/移位/比较与 f32/f64 SSE2 载体都已进入 x86-64 冻结集。

#region i32 算术

[host_provider(std::primitive::__i32_add)] [x86_64_operator("integer.add")] micro i32_add(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_sub)] [x86_64_operator("integer.subtract")] micro i32_sub(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_mul)] [x86_64_operator("integer.multiply")] micro i32_mul(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_div)] [x86_64_operator("integer.divide")] micro i32_div(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_rem)] [x86_64_operator("integer.remainder")] micro i32_rem(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_neg)] [x86_64_operator("integer.negate")] micro i32_neg(a: i32): i32

[host_provider(std::primitive::__i32_and)] [x86_64_operator("integer.and")] micro i32_and(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_or)] [x86_64_operator("integer.or")] micro i32_or(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_xor)] [x86_64_operator("integer.xor")] micro i32_xor(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_shl)] [x86_64_operator("integer.shift_left")] micro i32_shl(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_shr)] [x86_64_operator("integer.shift_right")] micro i32_shr(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_eq)] [x86_64_operator("integer.compare_equal")] micro i32_eq(a: i32, b: i32): bool

[host_provider(std::primitive::__i32_lt)] [x86_64_operator("integer.compare_less_than")] micro i32_lt(a: i32, b: i32): bool

#endregion

#region i64 算术

[host_provider(std::primitive::__i64_add)] [x86_64_operator("long.add")] micro i64_add(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_sub)] [x86_64_operator("long.subtract")] micro i64_sub(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_mul)] [x86_64_operator("long.multiply")] micro i64_mul(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_div)] [x86_64_operator("long.divide")] micro i64_div(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_rem)] [x86_64_operator("long.remainder")] micro i64_rem(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_neg)] [x86_64_operator("long.negate")] micro i64_neg(a: i64): i64

[host_provider(std::primitive::__i64_and)] [x86_64_operator("long.and")] micro i64_and(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_or)] [x86_64_operator("long.or")] micro i64_or(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_xor)] [x86_64_operator("long.xor")] micro i64_xor(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shl)] [x86_64_operator("long.shift_left")] micro i64_shl(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shr)] [x86_64_operator("long.shift_right")] micro i64_shr(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_eq)] [x86_64_operator("long.compare_equal")] micro i64_eq(a: i64, b: i64): bool

[host_provider(std::primitive::__i64_lt)] [x86_64_operator("long.compare_less_than")] micro i64_lt(a: i64, b: i64): bool

#endregion

#region u32 无符号算术

[host_provider(std::primitive::__u32_add)] [x86_64_operator("integer.add")] micro u32_add(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_sub)] [x86_64_operator("integer.subtract")] micro u32_sub(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_mul)] [x86_64_operator("integer.multiply")] micro u32_mul(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_div)] [x86_64_operator("integer.divide_unsigned")] micro u32_div(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_rem)] [x86_64_operator("integer.remainder_unsigned")] micro u32_rem(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_and)] [x86_64_operator("integer.and")] micro u32_and(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_or)] [x86_64_operator("integer.or")] micro u32_or(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_xor)] [x86_64_operator("integer.xor")] micro u32_xor(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_shl)] [x86_64_operator("integer.shift_left")] micro u32_shl(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_shr)] [x86_64_operator("integer.shift_right_unsigned")] micro u32_shr(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_eq)] [x86_64_operator("integer.compare_equal")] micro u32_eq(a: u32, b: u32): bool

[host_provider(std::primitive::__u32_lt)] [x86_64_operator("integer.compare_less_than_unsigned")] micro u32_lt(a: u32, b: u32): bool

#endregion

#region u64 无符号算术

[host_provider(std::primitive::__u64_add)] [x86_64_operator("long.add")] micro u64_add(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_sub)] [x86_64_operator("long.subtract")] micro u64_sub(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_mul)] [x86_64_operator("long.multiply")] micro u64_mul(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_div)] [x86_64_operator("long.divide_unsigned")] micro u64_div(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_rem)] [x86_64_operator("long.remainder_unsigned")] micro u64_rem(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_and)] [x86_64_operator("long.and")] micro u64_and(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_or)] [x86_64_operator("long.or")] micro u64_or(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_xor)] [x86_64_operator("long.xor")] micro u64_xor(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_shl)] [x86_64_operator("long.shift_left")] micro u64_shl(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_shr)] [x86_64_operator("long.shift_right_unsigned")] micro u64_shr(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_eq)] [x86_64_operator("long.compare_equal")] micro u64_eq(a: u64, b: u64): bool

[host_provider(std::primitive::__u64_lt)] [x86_64_operator("long.compare_less_than_unsigned")] micro u64_lt(a: u64, b: u64): bool

#endregion

#region f64 SSE2 算术

# `xmm0/xmm1` 载体；比较按 IEEE 无序语义归一为 0/1，`neg` 翻转符号位保留 -0.0。
[host_provider(std::primitive::__f64_add)] [x86_64_operator("double.add")] micro f64_add(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_sub)] [x86_64_operator("double.subtract")] micro f64_sub(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_mul)] [x86_64_operator("double.multiply")] micro f64_mul(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_div)] [x86_64_operator("double.divide")] micro f64_div(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_neg)] [x86_64_operator("double.negate")] micro f64_neg(a: f64): f64

[host_provider(std::primitive::__f64_eq)] [x86_64_operator("double.compare_equal")] micro f64_eq(a: f64, b: f64): bool

[host_provider(std::primitive::__f64_lt)] [x86_64_operator("double.compare_less_than")] micro f64_lt(a: f64, b: f64): bool

#endregion

#region f32 SSE2 算术

[host_provider(std::primitive::__f32_add)] [x86_64_operator("float.add")] micro f32_add(a: f32, b: f32): f32

[host_provider(std::primitive::__f32_sub)] [x86_64_operator("float.subtract")] micro f32_sub(a: f32, b: f32): f32

[host_provider(std::primitive::__f32_mul)] [x86_64_operator("float.multiply")] micro f32_mul(a: f32, b: f32): f32

[host_provider(std::primitive::__f32_div)] [x86_64_operator("float.divide")] micro f32_div(a: f32, b: f32): f32

[host_provider(std::primitive::__f32_neg)] [x86_64_operator("float.negate")] micro f32_neg(a: f32): f32

[host_provider(std::primitive::__f32_eq)] [x86_64_operator("float.compare_equal")] micro f32_eq(a: f32, b: f32): bool

[host_provider(std::primitive::__f32_lt)] [x86_64_operator("float.compare_less_than")] micro f32_lt(a: f32, b: f32): bool

#endregion
