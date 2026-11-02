namespace std.adaptor.wasm.math;

# std.adaptor.wasm: 无符号固定宽度整数的目标绑定
# u8/u16 需要截断或掩码，wasm 没有对应单条指令，必须保持未绑定并结构化失败。

#region u32

[host_provider(std::primitive::__u32_add)] [wasm_operator("i32.add")] micro u32_add(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_sub)] [wasm_operator("i32.sub")] micro u32_sub(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_mul)] [wasm_operator("i32.mul")] micro u32_mul(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_div)] [wasm_operator("i32.div_u")] micro u32_div(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_rem)] [wasm_operator("i32.rem_u")] micro u32_rem(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_eq)] [wasm_operator("i32.eq")] micro u32_eq(a: u32, b: u32): bool

[host_provider(std::primitive::__u32_lt)] [wasm_operator("i32.lt_u")] micro u32_lt(a: u32, b: u32): bool

[host_provider(std::primitive::__u32_and)] [wasm_operator("i32.and")] micro u32_and(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_or)] [wasm_operator("i32.or")] micro u32_or(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_xor)] [wasm_operator("i32.xor")] micro u32_xor(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_shl)] [wasm_operator("i32.shl")] micro u32_shl(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_shr)] [wasm_operator("i32.shr_u")] micro u32_shr(a: u32, b: u32): u32

#endregion

#region u64

[host_provider(std::primitive::__u64_add)] [wasm_operator("i64.add")] micro u64_add(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_sub)] [wasm_operator("i64.sub")] micro u64_sub(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_mul)] [wasm_operator("i64.mul")] micro u64_mul(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_div)] [wasm_operator("i64.div_u")] micro u64_div(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_rem)] [wasm_operator("i64.rem_u")] micro u64_rem(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_eq)] [wasm_operator("i64.eq")] micro u64_eq(a: u64, b: u64): bool

[host_provider(std::primitive::__u64_lt)] [wasm_operator("i64.lt_u")] micro u64_lt(a: u64, b: u64): bool

[host_provider(std::primitive::__u64_and)] [wasm_operator("i64.and")] micro u64_and(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_or)] [wasm_operator("i64.or")] micro u64_or(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_xor)] [wasm_operator("i64.xor")] micro u64_xor(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_shl)] [wasm_operator("i64.shl")] micro u64_shl(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_shr)] [wasm_operator("i64.shr_u")] micro u64_shr(a: u64, b: u64): u64

#endregion
