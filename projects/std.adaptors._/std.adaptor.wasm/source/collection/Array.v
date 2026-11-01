namespace std.adaptor.wasm.collection;

# E3 目标私有合同缺口：wasm GC 数组的 length/get/set/new 需要按元素类型注册 arraytype
# （运行期动态类型索引），现有 `[wasm_operator]` 助记符表只编码 numeric，无法表达。
# 在目标私有合同定案前，本 adaptor 不提供 `std.collection.array` 合同实现；
# 调用按缺 provider 结构化失败闭合，不得恢复 `[intrinsic]` 注解、名字表或链接豁免。
