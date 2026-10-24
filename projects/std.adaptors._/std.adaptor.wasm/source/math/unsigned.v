namespace std.adaptor.wasm.math;

# std.adaptor.wasm: 无符号与指针宽度整数的目标绑定
# 目标为 wasm32 系列，usize/isize 分别按 u32/i32 绑定。
# u8/u16 需要截断或掩码，wasm 没有对应单条指令，必须保持未绑定并结构化失败。

#region u32

[host_provider(core::primitive::__u32_add)] [wasm_operator("i32.add")] micro u32_add(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_sub)] [wasm_operator("i32.sub")] micro u32_sub(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_mul)] [wasm_operator("i32.mul")] micro u32_mul(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_div)] [wasm_operator("i32.div_u")] micro u32_div(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_rem)] [wasm_operator("i32.rem_u")] micro u32_rem(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_eq)] [wasm_operator("i32.eq")] micro u32_eq(a: u32, b: u32): bool

[host_provider(core::primitive::__u32_lt)] [wasm_operator("i32.lt_u")] micro u32_lt(a: u32, b: u32): bool

[host_provider(core::primitive::__u32_and)] [wasm_operator("i32.and")] micro u32_and(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_or)] [wasm_operator("i32.or")] micro u32_or(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_xor)] [wasm_operator("i32.xor")] micro u32_xor(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_shl)] [wasm_operator("i32.shl")] micro u32_shl(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_shr)] [wasm_operator("i32.shr_u")] micro u32_shr(a: u32, b: u32): u32

#endregion

#region usize（wasm32）

[host_provider(core::primitive::__usize_add)] [wasm_operator("i32.add")] micro usize_add(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_sub)] [wasm_operator("i32.sub")] micro usize_sub(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_mul)] [wasm_operator("i32.mul")] micro usize_mul(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_div)] [wasm_operator("i32.div_u")] micro usize_div(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_rem)] [wasm_operator("i32.rem_u")] micro usize_rem(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_eq)] [wasm_operator("i32.eq")] micro usize_eq(a: usize, b: usize): bool

[host_provider(core::primitive::__usize_lt)] [wasm_operator("i32.lt_u")] micro usize_lt(a: usize, b: usize): bool

[host_provider(core::primitive::__usize_and)] [wasm_operator("i32.and")] micro usize_and(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_or)] [wasm_operator("i32.or")] micro usize_or(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_xor)] [wasm_operator("i32.xor")] micro usize_xor(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_shl)] [wasm_operator("i32.shl")] micro usize_shl(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_shr)] [wasm_operator("i32.shr_u")] micro usize_shr(a: usize, b: usize): usize

#endregion

#region u64

[host_provider(core::primitive::__u64_add)] [wasm_operator("i64.add")] micro u64_add(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_sub)] [wasm_operator("i64.sub")] micro u64_sub(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_mul)] [wasm_operator("i64.mul")] micro u64_mul(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_div)] [wasm_operator("i64.div_u")] micro u64_div(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_rem)] [wasm_operator("i64.rem_u")] micro u64_rem(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_eq)] [wasm_operator("i64.eq")] micro u64_eq(a: u64, b: u64): bool

[host_provider(core::primitive::__u64_lt)] [wasm_operator("i64.lt_u")] micro u64_lt(a: u64, b: u64): bool

[host_provider(core::primitive::__u64_and)] [wasm_operator("i64.and")] micro u64_and(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_or)] [wasm_operator("i64.or")] micro u64_or(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_xor)] [wasm_operator("i64.xor")] micro u64_xor(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_shl)] [wasm_operator("i64.shl")] micro u64_shl(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_shr)] [wasm_operator("i64.shr_u")] micro u64_shr(a: u64, b: u64): u64

#endregion

#region isize（wasm32）

[host_provider(core::primitive::__isize_add)] [wasm_operator("i32.add")] micro isize_add(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_sub)] [wasm_operator("i32.sub")] micro isize_sub(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_mul)] [wasm_operator("i32.mul")] micro isize_mul(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_div)] [wasm_operator("i32.div_s")] micro isize_div(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_rem)] [wasm_operator("i32.rem_s")] micro isize_rem(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_neg)] [wasm_operator("i32.neg")] micro isize_neg(a: isize): isize

[host_provider(core::primitive::__isize_eq)] [wasm_operator("i32.eq")] micro isize_eq(a: isize, b: isize): bool

[host_provider(core::primitive::__isize_lt)] [wasm_operator("i32.lt_s")] micro isize_lt(a: isize, b: isize): bool

[host_provider(core::primitive::__isize_and)] [wasm_operator("i32.and")] micro isize_and(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_or)] [wasm_operator("i32.or")] micro isize_or(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_xor)] [wasm_operator("i32.xor")] micro isize_xor(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_shl)] [wasm_operator("i32.shl")] micro isize_shl(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_shr)] [wasm_operator("i32.shr_s")] micro isize_shr(a: isize, b: isize): isize

#endregion
