namespace std.adaptor.jvm.random;

# 宿主熵源：`java.security.SecureRandom`。只取熵，不产生序列；序列语义
# 归生成器合同的实现类型，平台不另挂宿主序列（`java.util.Random` 与合同
# 实现的序列不同，绑定它会违反同种子同序列合同）。
# 时钟不是熵：旧 `System.nanoTime` 绑定已删除，纳秒计时把时钟冒充成
# 熵源，违反 `std.random` 熵合同（02 §4.3）。

[host_provider(std::random::entropy)]
micro host_entropy() -> u64 {
    return __secure_random_next_long(__secure_random_new()) as u64
}

[jvm("java.security.SecureRandom", "<init>")]
private micro __secure_random_new(): any { }

[jvm("java.security.SecureRandom", "nextLong")]
private micro __secure_random_next_long(source: any): i64 { }
