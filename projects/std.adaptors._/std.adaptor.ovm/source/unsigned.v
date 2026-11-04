# std.adaptor.ovm: 无符号固定宽度整数的目标绑定
# 只登记 OVM 真正具备的指令：位宽相同且语义相同的加、减、乘、等值比较与无符号比较
# （`i32.lt_u`/`i32.le_u`/`i32.gt_u`/`i32.ge_u` 是 VM 冻结的无符号比较头码），
# 以及位运算（32 位道经 `[ovm_operator]` 冻结头码 `i32.and`/`i32.or`/`i32.xor`/`i32.shl`/
# `i32.shr_u` 内联，u64 道经 `nyar.host` 宿主导入，与 i64 位运算同轨）。
# 无符号除余与逻辑右移都有专用宿主符号：32 位道是 `i32.div_u`/`i32.rem_u` 冻结头码，
# 64 位道是 `i64_div_u`/`i64_rem_u`/`i64_shr_u` 宿主导入。有符号 `i32.div`/`i32.rem`、
# 算术 `i64_shr` 语义不同，不能顶替。
# u8/u16 的加与等值由 `std.primitive` 在 u32 载体上合成（加宽/窄化或拓宽比较），
# 不经本文件。其余 u8/u16 算术需要按位截断，VM 没有掩码指令，因此不提供 provider。
# `usize` / `isize` 是 `std.primitive` 按目标指针宽度展开的别名，不再是 host 合同；
# 其运算经由别名目标（u32/u64、i32/i64）的既有 provider 解析，本文件不再登记 `__usize_*` / `__isize_*`。

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

# 无符号除余是宿主符号 `i32_div_u` / `i32_rem_u`，不是可内联的冻结头码。
[host_provider(std::primitive::__u32_div)]
[ovm("i32_div_u")]
micro u32_div(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_rem)]
[ovm("i32_rem_u")]
micro u32_rem(a: u32, b: u32): u32

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

# 无符号小于：宿主符号 `i64_lt_u` 按无符号位型比较（最高位为 1 时与有符号 `i64_lt` 结论相反）。
[host_provider(std::primitive::__u64_lt)]
[ovm("i64_lt_u")]
micro u64_lt(a: u64, b: u64): bool

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

# 无符号除余与逻辑右移走专用宿主符号；算术右移 `i64_shr` 与有符号除余在最高位为 1 时
# 结论不同，不能顶替。
[host_provider(std::primitive::__u64_div)]
[ovm("i64_div_u")]
micro u64_div(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_rem)]
[ovm("i64_rem_u")]
micro u64_rem(a: u64, b: u64): u64

[host_provider(std::primitive::__u64_shr)]
[ovm("i64_shr_u")]
micro u64_shr(a: u64, b: u64): u64

#endregion
