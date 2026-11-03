namespace std.adaptor.ovm.random;

# 宿主熵源：OVM `math_rand` 宿主符号。只取熵，不产生序列；
# 序列语义归生成器合同的实现类型，平台不另给算法。

[host_provider(std::random::entropy)]
micro host_entropy() -> u64 {
    return std.adaptor.ovm.builtin.math_rand() as u64
}
