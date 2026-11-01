namespace std.adaptor.wasi.collection;

# E3 目标私有合同缺口：wasi 复用 wasm GC 数组表示，length/get/set/new 同样需要
# 按元素类型注册 arraytype，现有正式助记符合同无法表达。
# 在目标私有合同定案前，本 adaptor 不提供 `std.collection.array` 合同实现；
# 调用按缺 provider 结构化失败闭合，不得恢复 `[intrinsic]` 注解、名字表或链接豁免。
