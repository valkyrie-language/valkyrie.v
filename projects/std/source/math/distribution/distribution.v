namespace std.math.distribution;

# std.math.distribution — 概率分布：能力合同与实现类型。
#
# 建模合同：
# - `Distribution` 是分布的能力合同：关联类型 `Sample` 表达样本类型，
#   `sample` 消费满足 `std.random.Generator` 的生成器产出一个样本。
# - 具体分布是实现该合同的类型：参数由类型自身持有，退化参数在构造时
#   结构化失败，不返回默认值。
# - 依赖方向单向：distribution → `std.random` 的流；`std.random` 不感知分布。
# - 合同开放可扩展：用户自定义分布实现本合同即可接入；标准库不维护
#   封闭的具体类型集合，也不提供按名字分派的函数族。
# - 同一种子 + 同一生成器实现 + 同一分布参数 → 同一序列样本；
#   跨 lane 可复现性由本合同表达。

trait Distribution {
    type Sample;

    # 从生成器流取一个样本。
    micro sample<G>(self, generator: G) -> Sample
        where G: std::random::Generator
}
