namespace hardware;

# kernel 层：kernel 合同。
#
# Kernel 是 map/dispatch 的行为合同：`apply` 把输入元素映射为输出元素。
# 作者在自己的 kernel 结构上 `imply …: hardware::Kernel<T, U>` 后，可直接 `.apply` 消费，
# 或经 `Queue.dispatch_map` 的函数值参数等价调度。
#
# `where K: Kernel<T, U>` 由 K 反推 T/U 的泛型调度解析在当前编译器不可用，
# trait 对象不经 dispatch 泛型消费；外部后端的 kernel 模块（SPIR-V/WGSL/PTX 加载）
# 是独立的 host capability 面（后续块），与本 trait 不冲突。
