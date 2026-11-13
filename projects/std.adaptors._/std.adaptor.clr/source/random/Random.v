namespace std.adaptor.clr.random;

# 宿主熵源：`System.Security.Cryptography.RandomNumberGenerator`。
# 只取熵，不产生序列；序列语义归生成器合同的实现类型，平台不另挂宿主
# RNG 算法（`System.Random` 与合同实现的序列不同）。
# 时钟不是熵：旧 `Environment.TickCount64` 绑定已删除，同一 tick 重复值
# 会把时钟冒充成熵源，违反 `std.random` 熵合同（02 §4.3）。
# 全宽事实：`GetBytes` 填充 8 个真实随机字节，按小端拼成完整 u64——
# 两次受限 `GetInt32(2147483647)` 拼 u64 会使位 63/31 恒零（旧实现缺陷，
# 已删除），不用返回类型掩盖实际分布。

[host_provider(std::random::entropy)]
micro host_entropy() -> u64 {
    let bytes: [u8] = [0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8]
    let generator: any = __rng_create()
    __rng_get_bytes(generator, bytes)
    let low: u64 = (bytes⁅0⁆ as u64) | ((bytes⁅1⁆ as u64) << 8) | ((bytes⁅2⁆ as u64) << 16) | ((bytes⁅3⁆ as u64) << 24)
    let high: u64 = (bytes⁅4⁆ as u64) | ((bytes⁅5⁆ as u64) << 8) | ((bytes⁅6⁆ as u64) << 16) | ((bytes⁅7⁆ as u64) << 24)
    return (high << 32) | low
}

[clr("System.Security.Cryptography", "System.Security.Cryptography.RandomNumberGenerator", "Create")]
private micro __rng_create(): any { }

[clr("System.Security.Cryptography", "System.Security.Cryptography.RandomNumberGenerator", "GetBytes")]
private micro __rng_get_bytes(generator: any, buffer: [u8]): unit { }
