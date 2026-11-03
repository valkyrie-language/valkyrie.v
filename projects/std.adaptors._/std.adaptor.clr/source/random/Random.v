namespace std.adaptor.clr.random;

# 宿主熵源：`System.Environment.TickCount64`；序列语义归 std 默认实现，
# 平台不另挂宿主 RNG 算法（`System.Random` 与 SplitMix64 序列不同）。

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random {
    return std.random.Random::with_seed(__random_clr_entropy() as u64)
}

[clr("System.Runtime", "System.Environment", "get_TickCount64")]
private micro __random_clr_entropy(): i64 { }
