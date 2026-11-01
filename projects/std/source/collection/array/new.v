namespace std.collection.array;

# 按长度分配 `[T]`：库 API 合同（host contract），调用走唯一 `Invoke` 路径。
# 这是能力合同、不是作者语法——不存在 `new [T](n)`；作者构造数组仍只有 `[]` 字面量。
# 分配、元素初始化（零值/默认值语义由目标定义）、长度溢出（usize 上限）、泛型元素表示与 GC、
# 失败与资源责任全部由目标 provider 承担；缺 provider 时结构化失败闭合，不得空体成功或链接豁免。
[host_contract]
micro new<T>(length: usize): [T]
