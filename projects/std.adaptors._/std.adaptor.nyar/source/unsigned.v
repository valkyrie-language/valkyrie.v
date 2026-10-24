# std.adaptor.nyar: 无符号与指针宽度整数的目标绑定
# 只登记 NyarVM 真正具备的指令：位宽相同且语义相同的加、减、乘与等值比较。
# 无符号除余、无符号比较与逻辑右移在 VM 中没有对应指令，必须保持未绑合并结构化失败；
# u8/u16 需要截断，VM 没有掩码指令，因此不提供 provider。

#region u32

[host_provider(core::primitive::__u32_add)]
[ovm_operator("i32.add")]
micro u32_add(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_sub)]
[ovm_operator("i32.sub")]
micro u32_sub(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_mul)]
[ovm_operator("i32.mul")]
micro u32_mul(a: u32, b: u32): u32

[host_provider(core::primitive::__u32_eq)]
[ovm_operator("i32.eq")]
micro u32_eq(a: u32, b: u32): bool

#endregion

#region usize（NyarVM 指针宽度为 32 位）

[host_provider(core::primitive::__usize_add)]
[ovm_operator("i32.add")]
micro usize_add(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_sub)]
[ovm_operator("i32.sub")]
micro usize_sub(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_mul)]
[ovm_operator("i32.mul")]
micro usize_mul(a: usize, b: usize): usize

[host_provider(core::primitive::__usize_eq)]
[ovm_operator("i32.eq")]
micro usize_eq(a: usize, b: usize): bool

#endregion

#region u64

[host_provider(core::primitive::__u64_add)]
[vm("i64_add")]
micro u64_add(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_sub)]
[vm("i64_sub")]
micro u64_sub(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_mul)]
[vm("i64_mul")]
micro u64_mul(a: u64, b: u64): u64

[host_provider(core::primitive::__u64_eq)]
[vm("i64_eq")]
micro u64_eq(a: u64, b: u64): bool

#endregion

#region isize（NyarVM 指针宽度为 32 位，有符号）

[host_provider(core::primitive::__isize_add)]
[ovm_operator("i32.add")]
micro isize_add(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_sub)]
[ovm_operator("i32.sub")]
micro isize_sub(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_mul)]
[ovm_operator("i32.mul")]
micro isize_mul(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_div)]
[ovm_operator("i32.div")]
micro isize_div(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_rem)]
[ovm_operator("i32.rem")]
micro isize_rem(a: isize, b: isize): isize

[host_provider(core::primitive::__isize_neg)]
[ovm_operator("i32.neg")]
micro isize_neg(a: isize): isize

[host_provider(core::primitive::__isize_eq)]
[ovm_operator("i32.eq")]
micro isize_eq(a: isize, b: isize): bool

[host_provider(core::primitive::__isize_lt)]
[ovm_operator("i32.lt")]
micro isize_lt(a: isize, b: isize): bool

#endregion
