namespace std.adaptor.clr.random;

# 宿主熵源：`System.Environment.TickCount64`。只取熵，不产生序列；
# 序列语义归生成器合同的实现类型，平台不另挂宿主 RNG 算法
# （`System.Random` 与合同实现的序列不同）。

[host_provider(std::random::entropy)]
micro host_entropy() -> u64 {
    return __random_clr_entropy() as u64
}

[clr("System.Runtime", "System.Environment", "get_TickCount64")]
private micro __random_clr_entropy(): i64 { }
