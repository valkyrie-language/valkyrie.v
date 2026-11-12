namespace std.adaptor.clr.random;

# 宿主熵源：`System.Security.Cryptography.RandomNumberGenerator`。
# 只取熵，不产生序列；序列语义归生成器合同的实现类型，平台不另挂宿主
# RNG 算法（`System.Random` 与合同实现的序列不同）。
# 时钟不是熵：旧 `Environment.TickCount64` 绑定已删除，同一 tick 重复值
# 会把时钟冒充成熵源，违反 `std.random` 熵合同（02 §4.3）。

[host_provider(std::random::entropy)]
micro host_entropy() -> u64 {
    let high: u64 = __rng_int32(2147483647) as u64
    let low: u64 = __rng_int32(2147483647) as u64
    return (high << 32) | low
}

[clr("System.Security.Cryptography", "System.Security.Cryptography.RandomNumberGenerator", "GetInt32")]
private micro __rng_int32(to_exclusive: i32): i32 { }
