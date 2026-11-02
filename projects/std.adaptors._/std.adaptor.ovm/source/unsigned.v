# std.adaptor.ovm: 无符号与指针宽度整数的目标绑定
# 只登记 OVM 真正具备的指令：位宽相同且语义相同的加、减、乘、等值比较与无符号比较
# （`i32.lt_u`/`i32.le_u`/`i32.gt_u`/`i32.ge_u` 是 VM 冻结的无符号比较头码），
# 以及位运算（32 位道经 `[ovm_operator]` 冻结头码 `i32.and`/`i32.or`/`i32.xor`/`i32.shl`/
# `i32.shr_u` 内联，u64 道经 `nyar.host` 宿主导入，与 i64 位运算同轨）。
# 无符号除余在 VM 中没有对应指令（`i32.div`/`i32.rem` 是有符号语义，不能顶替），
# 宿主符号表只有算术右移 `i64_shr`、没有逻辑右移 `i64_shr_u`，两者都必须保持未绑合并结构化失败；
# u8/u16 需要截断，VM 没有掩码指令，因此不提供 provider。

#region u32

[host_provider(std::primitive::__u32_add)]
[ovm_operator("i32.add")]
micro u32_add(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_sub)]
[ovm_operator("i32.sub")]
micro u32_sub(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_mul)]
[ovm_operator("i32.mul")]
micro u32_mul(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_eq)]
[ovm_operator("i32.eq")]
micro u32_eq(a: u32, b: u32): bool

[host_provider(std::primitive::__u32_lt)]
[ovm_operator("i32.lt_u")]
micro u32_lt(a: u32, b: u32): bool

[host_provider(std::primitive::__u32_and)]
[ovm_operator("i32.and")]
micro u32_and(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_or)]
[ovm_operator("i32.or")]
micro u32_or(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_xor)]
[ovm_operator("i32.xor")]
micro u32_xor(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_shl)]
[ovm_operator("i32.shl")]
micro u32_shl(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_shr)]
[ovm_operator("i32.shr_u")]
micro u32_shr(a: u32, b: u32): u32

#endregion

#region usize（OVM 指针宽度为 32 位）

[host_provider(std::primitive::__usize_add)]
[ovm_operator("i32.add")]
micro usize_add(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_sub)]
[ovm_operator("i32.sub")]
micro usize_sub(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_mul)]
[ovm_operator("i32.mul")]
micro usize_mul(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_eq)]
[ovm_operator("i32.eq")]
micro usize_eq(a: usize, b: usize): bool

[host_provider(std::primitive::__usize_lt)]
[ovm_operator("i32.lt_u")]
micro usize_lt(a: usize, b: usize): bool

[host_provider(std::primitive::__usize_and)]
[ovm_operator("i32.and")]
micro usize_and(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_or)]
[ovm_operator("i32.or")]
micro usize_or(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_xor)]
[ovm_operator("i32.xor")]
micro usize_xor(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_shl)]
[ovm_operator("i32.shl")]
micro usize_shl(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_shr)]
[ovm_operator("i32.shr_u")]
micro usize_shr(a: usize, b: usize): usize

#endregion

#region u64

[host_provider(std::primitive::__u64_add)]
[ovm("i64_add")]
micro u64_add(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_sub)]
[ovm("i64_sub")]
micro u64_sub(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_mul)]
[ovm("i64_mul")]
micro u64_mul(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_eq)]
[ovm("i64_eq")]
micro u64_eq(a: u64, b: u64): bool

# 与/或/异或/左移对 64 位无符号与有符号语义一致，经 `nyar.host` 宿主导入，
# 符号由 runtime `parse_host_op` 解析，未知符号在模块加载期结构化失败。
[host_provider(std::primitive::__u64_and)]
[ovm("i64_and")]
micro u64_and(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_or)]
[ovm("i64_or")]
micro u64_or(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_xor)]
[ovm("i64_xor")]
micro u64_xor(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_shl)]
[ovm("i64_shl")]
micro u64_shl(a: u64, b: u64): u64

# `__u64_shr` 保持未绑定：宿主符号表没有逻辑右移 `i64_shr_u`，
# 用算术右移 `i64_shr` 顶替会在最高位为 1 时给出错误结果。
#endregion

#region isize（OVM 指针宽度为 32 位，有符号）

[host_provider(std::primitive::__isize_add)]
[ovm_operator("i32.add")]
micro isize_add(a: isize, b: isize): isize

[host_provider(std::primitive::__isize_sub)]
[ovm_operator("i32.sub")]
micro isize_sub(a: isize, b: isize): isize

[host_provider(std::primitive::__isize_mul)]
[ovm_operator("i32.mul")]
micro isize_mul(a: isize, b: isize): isize

[host_provider(std::primitive::__isize_div)]
[ovm_operator("i32.div")]
micro isize_div(a: isize, b: isize): isize

[host_provider(std::primitive::__isize_rem)]
[ovm_operator("i32.rem")]
micro isize_rem(a: isize, b: isize): isize

[host_provider(std::primitive::__isize_neg)]
[ovm_operator("i32.neg")]
micro isize_neg(a: isize): isize

[host_provider(std::primitive::__isize_eq)]
[ovm_operator("i32.eq")]
micro isize_eq(a: isize, b: isize): bool

[host_provider(std::primitive::__isize_lt)]
[ovm_operator("i32.lt")]
micro isize_lt(a: isize, b: isize): bool

[host_provider(std::primitive::__isize_and)]
[ovm_operator("i32.and")]
micro isize_and(a: isize, b: isize): isize

[host_provider(std::primitive::__isize_or)]
[ovm_operator("i32.or")]
micro isize_or(a: isize, b: isize): isize

[host_provider(std::primitive::__isize_xor)]
[ovm_operator("i32.xor")]
micro isize_xor(a: isize, b: isize): isize

[host_provider(std::primitive::__isize_shl)]
[ovm_operator("i32.shl")]
micro isize_shl(a: isize, b: isize): isize

# isize 是有符号类型，右移必须是算术右移 `i32.shr_s`。
[host_provider(std::primitive::__isize_shr)]
[ovm_operator("i32.shr_s")]
micro isize_shr(a: isize, b: isize): isize

#endregion
