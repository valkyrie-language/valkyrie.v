namespace std.adaptor.ovm.random;

# 宿主熵源：OVM `random_u64` 宿主符号，返回全宽 64 位原始随机字。
# 只取熵，不产生序列；序列语义归 `std.random::Generator` 的实现类型，平台不另给算法。

[host_provider(std::random::entropy)]
micro host_entropy() -> u64 {
    return std.adaptor.ovm.builtin.random_u64()
}
