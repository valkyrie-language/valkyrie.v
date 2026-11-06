namespace std.operator;

# Countable: 精确计数合同。
# `length` 是承载的元素个数，不是容量、也不是索引空间上界。
# 只做声明，不提供默认体；实现一律由 impl 侧显式给出。
trait Countable {
    micro length(self): usize
}
