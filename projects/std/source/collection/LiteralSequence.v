# std.collection: 集合字面量构造合同
#
# 编译器按限定路径 `std::collection::LiteralSequence` 识别本合同：凡带有
# `imply ...: LiteralSequence<T>` 事实的类型，其集合字面量 `[e0, e1, ...]`
# 由声明期望类型驱动构造——先 `with_length(n)` 预留容量，再逐元素 `append`。
# 禁止先构造 Array 再隐式转换；`Array`/`[T]` 不实现本合同，仍走原 ArrayLiteral 路径。

namespace std.collection;

trait LiteralSequence<T> {
    micro with_length(n: usize): Self
    micro append(mut self, value: T): unit
}
