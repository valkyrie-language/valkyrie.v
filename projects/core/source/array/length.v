namespace core::array;

# 结构化数组 `[T]` 的长度。
# 该声明是数组长度结构操作的唯一前端来源：`[intrinsic]` 只冻结语言身份，
# 目标实现由已绑定的 adaptor / 后端计划提供，声明不携带任何目标助记符。
[intrinsic("builtin.array.length")]
micro length<T>(array: [T]): usize { }
