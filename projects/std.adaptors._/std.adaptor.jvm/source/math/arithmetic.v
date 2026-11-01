# std.adaptor.jvm: 算术运算 [jvm_operator] 绑定
# 将 valkyrie-core 的算术运算映射为 JVM class 指令
# 编译器使用 [jvm_operator] 绑定直接内联为对应指令，零函数调用开销

#region i32 算术

[host_provider(std::primitive::__i32_add)]
[jvm_operator("integer.add")]
micro i32_add(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_sub)]
[jvm_operator("integer.subtract")]
micro i32_sub(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_mul)]
[jvm_operator("integer.multiply")]
micro i32_mul(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_div)]
[jvm_operator("integer.divide")]
micro i32_div(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_rem)]
[jvm_operator("integer.remainder")]
micro i32_rem(a: i32, b: i32): i32

[host_provider(std::primitive::__i32_neg)]
[jvm_operator("integer.negate")]
micro i32_neg(a: i32): i32

#endregion

#region i64 算术

[host_provider(std::primitive::__i64_add)]
[jvm_operator("long.add")]
micro i64_add(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_sub)]
[jvm_operator("long.subtract")]
micro i64_sub(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_mul)]
[jvm_operator("long.multiply")]
micro i64_mul(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_div)]
[jvm_operator("long.divide")]
micro i64_div(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_rem)]
[jvm_operator("long.remainder")]
micro i64_rem(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_neg)]
[jvm_operator("long.negate")]
micro i64_neg(a: i64): i64

#endregion

#region i64 位运算
# `land`/`lor`/`lxor` 为单指令；`lshl`/`lshr` 的位移量是 `int`，
# `i64` 位移量的 `l2i` 截窄由 JVM backend 冻结配方显式给出，不在本文件推断。

[host_provider(std::primitive::__i64_and)]
[jvm_operator("long.and")]
micro i64_and(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_or)]
[jvm_operator("long.or")]
micro i64_or(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_xor)]
[jvm_operator("long.xor")]
micro i64_xor(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shl)]
[jvm_operator("long.shift_left")]
micro i64_shl(a: i64, b: i64): i64

[host_provider(std::primitive::__i64_shr)]
[jvm_operator("long.shift_right")]
micro i64_shr(a: i64, b: i64): i64

#endregion

#region f64 算术
# JVM 没有 `dneg`；`__f64_neg` 需要 `dconst_0 + dsub` 序列而当前配方层没有浮点零常量，
# 因此不声明该 provider，避免静默错误语义。

[host_provider(std::primitive::__f64_add)]
[jvm_operator("double.add")]
micro f64_add(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_sub)]
[jvm_operator("double.subtract")]
micro f64_sub(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_mul)]
[jvm_operator("double.multiply")]
micro f64_mul(a: f64, b: f64): f64

[host_provider(std::primitive::__f64_div)]
[jvm_operator("double.divide")]
micro f64_div(a: f64, b: f64): f64

#endregion

#region usize（JVM 指针宽度为 32 位）
# 只绑定位宽相同且语义相同的加、减、乘、等值比较与无符号小于比较；
# JVM 没有指令级无符号除余，逻辑右移与位运算尚未在配方层冻结，
# 这些能力保持未绑合并结构化失败，不得用有符号指令顶替。

[host_provider(std::primitive::__usize_add)]
[jvm_operator("integer.add")]
micro usize_add(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_sub)]
[jvm_operator("integer.subtract")]
micro usize_sub(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_mul)]
[jvm_operator("integer.multiply")]
micro usize_mul(a: usize, b: usize): usize

[host_provider(std::primitive::__usize_eq)]
[jvm_operator("integer.compare_equal")]
micro usize_eq(a: usize, b: usize): bool

[host_provider(std::primitive::__usize_lt)]
[jvm_operator("integer.compare_less_than_unsigned")]
micro usize_lt(a: usize, b: usize): bool

#endregion

#region 比较
# 只绑定项目已声明的 `eq` / `lt` host 合同；返回类型必须与合同声明同源（`bool`），
# JVM 侧展开的分支序列压入 `int` 0/1，由冻结计划的 `result_type = I32` 承载。

[host_provider(std::primitive::__i32_eq)]
[jvm_operator("integer.compare_equal")]
micro i32_eq(a: i32, b: i32): bool

[host_provider(std::primitive::__i32_lt)]
[jvm_operator("integer.compare_less_than")]
micro i32_lt(a: i32, b: i32): bool

[host_provider(std::primitive::__i64_eq)]
[jvm_operator("long.compare_equal")]
micro i64_eq(a: i64, b: i64): bool

[host_provider(std::primitive::__i64_lt)]
[jvm_operator("long.compare_less_than")]
micro i64_lt(a: i64, b: i64): bool

#endregion

#region u32（JVM 以 `int` 承载）
# 与/或/异或与左移按位等价；右移必须绑定逻辑右移 `iushr`，不能用有符号 `ishr`。
# 无符号除余在 JVM 上需要 `Integer.divideUnsigned`/`remainderUnsigned` 静态调用，
# 配方层尚未冻结该形态，因此不声明 `__u32_div`/`__u32_rem`，保持结构化失败。

[host_provider(std::primitive::__u32_add)]
[jvm_operator("integer.add")]
micro u32_add(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_sub)]
[jvm_operator("integer.subtract")]
micro u32_sub(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_mul)]
[jvm_operator("integer.multiply")]
micro u32_mul(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_and)]
[jvm_operator("integer.and")]
micro u32_and(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_or)]
[jvm_operator("integer.or")]
micro u32_or(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_xor)]
[jvm_operator("integer.xor")]
micro u32_xor(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_shl)]
[jvm_operator("integer.shift_left")]
micro u32_shl(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_shr)]
[jvm_operator("integer.shift_right_unsigned")]
micro u32_shr(a: u32, b: u32): u32

[host_provider(std::primitive::__u32_eq)]
[jvm_operator("integer.compare_equal")]
micro u32_eq(a: u32, b: u32): bool

[host_provider(std::primitive::__u32_lt)]
[jvm_operator("integer.compare_less_than_unsigned")]
micro u32_lt(a: u32, b: u32): bool

#endregion
