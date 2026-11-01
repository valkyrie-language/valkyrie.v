namespace std.array;

# 结构化数组 `[T]` 的长度：库 API 合同（host contract），调用走唯一 `Invoke` 路径。
# 实现由 adaptor 的 `[host_provider]` 绑定到目标正式导入或真实函数体；
# 缺 provider 时按结构化失败闭合，不得以空体成功或名字表旁路替代实现。
[host_contract]
micro length<T>(array: [T]): usize
