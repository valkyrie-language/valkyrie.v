namespace std.adaptor.wasi.collection;

# wasi 复用 wasm GC 数组表示：`std.collection.array` 合同经
# `[wasm_operator("array.*")]` 目标 operator 绑定实现（无 intrinsic、无名字表、
# 无链接豁免）。冻结与编码路径与 `std.adaptor.wasm.collection` 完全同一条：
# 计划构造期按 wasm backend 私有数组助记符表冻结 arity 与操作身份，编码期按
# 元素类型解析 arraytype 并发射 `ref.cast` + GC 数组指令，与 MIR `Array*` 臂
# 共用同一发射器。声明形状与冻结计划不符、未知助记符或缺 provider 均结构化失败。

[host_provider(std::collection::array::new), wasm_operator("array.new"), pure]
private micro array_host_new<T>(length: usize): [T] { }

[host_provider(std::collection::array::length), wasm_operator("array.length"), pure]
private micro array_host_length<T>(array: [T]): usize { }

[host_provider(std::collection::array::get), wasm_operator("array.get"), pure]
private micro array_host_get<T>(array: [T], index: usize): T { }

[host_provider(std::collection::array::set), wasm_operator("array.set")]
private micro array_host_set<T>(array: [T], index: usize, value: T): unit { }
