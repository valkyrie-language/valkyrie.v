namespace std.collection.array;

# 分配一块容量载体：库 API 合同（host contract），调用走唯一 `Invoke` 路径。
# 这是能力合同、不是作者语法——不存在 `new [T](n)`；作者构造可读数组仍只有 `[]` 字面量
# 与显式初始化路径。
#
# 返回的是「容量槽位」，不是可读元素数组：`capacity` 个槽位没有一个是有效 `T`。
# 把本合同的返回值当普通 `[T]` 读取未初始化槽位是合同违例；有效元素的判定归
# `std.collection.ArrayStorage` 的初始化前沿，不归目标。
# 分配、槽位内存形态、长度溢出（usize 上限）、泛型元素表示与 GC、失败与资源责任
# 全部由目标 provider 承担；缺 provider 时结构化失败闭合，不得空体成功或链接豁免。
[host_contract]
micro allocate<T>(capacity: usize): [T]
