namespace std.adaptor.ovm.random;

# 宿主熵源：OVM `math_rand` 宿主符号；序列语义归 std 默认实现，平台不另给算法。

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random {
    return std.random.Random::with_seed(std.adaptor.ovm.builtin.math_rand() as u64)
}
