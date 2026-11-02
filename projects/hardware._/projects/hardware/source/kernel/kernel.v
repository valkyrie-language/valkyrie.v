namespace hardware;

# Kernel<T, U> — map kernel 行为合同：输入元素 T 映射为输出元素 U。
#
# 实现者在自己的 kernel 结构上承载参数（如系数），`apply` 为纯元素级映射。
# 调度侧当前以函数值参数承载（`Queue.dispatch_map`），trait 直接 `.apply` 消费；
# 泛型 bound 调度当前不可解析，见包 readme。
trait Kernel<T, U> {
    micro apply(self, input: T) -> U
}
