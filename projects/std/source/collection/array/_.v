# std.collection.array: 结构化数组 `[T]` 的能力合同层（length/get/set 等）。
# 职责与容器类型 `std.collection.Array`（class，`Array.v`）不同：本模块只持有语言级
# 数组结构操作的 host contract 声明，不携带目标助记符、名字表或后端特判；
# 实现由 adaptor 的 `[host_provider]` 绑定。

namespace! std.collection.array;
