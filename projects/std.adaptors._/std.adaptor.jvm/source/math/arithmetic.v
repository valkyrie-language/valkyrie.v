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
