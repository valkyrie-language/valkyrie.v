namespace std.adaptor.wasm.collection;

# `std.collection.array` 合同经 `[wasm_operator("array.*")]` 目标 operator 绑定实现
# （无 intrinsic、无名字表、无链接豁免）：助记符在 `TargetExecutionPlan` 构造期一次性
# 冻结为数组计划（arity 与操作身份），与 wasm numeric 助记符表同形的后端私有配方表；
# `array.new`/`array.length`/`array.get`/`array.set` 在编码期按元素类型从
# RepresentationPlan 的 wasm-gc arraytype 注册表解析类型索引，发射
# `ref.cast` + GC 数组指令，与 MIR `ArrayNew`/`ArrayGet`/`ArraySet`/`ArrayLength`
# 臂共用同一发射器。声明形状与冻结计划不符、未知助记符或缺 provider 均结构化失败。

[host_provider(std::collection::array::new), wasm_operator("array.new"), pure]
private micro array_host_new<T>(length: usize): [T] { }

[host_provider(std::collection::array::length), wasm_operator("array.length"), pure]
private micro array_host_length<T>(array: [T]): usize { }

[host_provider(std::collection::array::get), wasm_operator("array.get"), pure]
private micro array_host_get<T>(array: [T], index: usize): T { }

[host_provider(std::collection::array::set), wasm_operator("array.set")]
private micro array_host_set<T>(array: [T], index: usize, value: T): unit { }
