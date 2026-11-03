namespace std.adaptor.jvm.random;

# 宿主熵源：`System.nanoTime`。只取熵，不产生序列；序列语义归生成器
# 合同的实现类型，平台不另挂宿主 RNG 算法（宿主 `java.util.Random`
# 与合同实现的序列不同，绑定它会违反同种子同序列合同）。

[host_provider(std::random::entropy)]
micro host_entropy() -> u64 {
    return __random_jvm_entropy() as u64
}

[jvm("java.lang.System", "nanoTime")]
private micro __random_jvm_entropy(): i64 { }
