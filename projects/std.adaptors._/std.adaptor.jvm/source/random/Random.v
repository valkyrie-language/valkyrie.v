namespace std.adaptor.jvm.random;

# 宿主熵源：`System.nanoTime`；序列语义归 std 默认实现，平台不另挂宿主 RNG 算法
# （宿主 `java.util.Random` 与 SplitMix64 序列不同，绑定它会违反同种子同序列合同）。

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random {
    return std.random.Random::with_seed(__random_jvm_entropy() as u64)
}

[jvm("java.lang.System", "nanoTime")]
private micro __random_jvm_entropy(): i64 { }
