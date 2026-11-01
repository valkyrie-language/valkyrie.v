namespace std.adaptor.ovm.collection;

# E3 目标私有合同缺口：ovm 后端没有可编码数组 length/get/set/new 的正式助记符合同
# （`[ovm_operator]` 表仅 numeric），Odin VM 私有的 `CallIntrinsic` 不对外作为库实现来源。
# 在目标私有合同定案前，本 adaptor 不提供 `std.collection.array` 合同实现；
# 调用按缺 provider 结构化失败闭合，不得恢复 `[intrinsic]` 注解、名字表或链接豁免。
