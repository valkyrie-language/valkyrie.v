# hardware

异构设备抽象核心包（GPU 计算基石）：承接游戏、渲染与深度学习。
本文是**七层合同的冻结声明**：类型、词汇、不变量、执行模型、IR 指令表、故障注册表与验收口径。合同变更必须先改本文。

## 全层公理

- 设备语义不进 nyar 编译器；外部后端（Vulkan/DX12/WebGPU/CUDA）只经 `[host_contract]`/`[host_provider]` 唯一路径接入，provider 缺位即结构化失败，不做编译器特判。
- 词汇常量一律数值（kind/heap class/queue family/opcode/fault code），文本形态暂不进聚合与返回值。
- 能力集合 = i64 位掩码；限制结构 = 扁平标量；跨资源引用走工厂参数与调用点参数（聚合嵌套聚合当前不可物化）。
- 一切分配/校验失败走 `Result<T, HardwareFault>`，配无 panic 检查器；资源构造归后端工厂。

## L1 适配器/设备

- 类型：`Adapter`、`Device`（不透明 class 句柄）；`DeviceKind`（cpu=1/discrete_gpu=2/integrated_gpu=3/virtual_gpu=4/accelerator=5）；`Features{bits}` + 位常量（compute/transfer/graphics/timeline_semaphore/multi_queue/shader_f64/texture/device_lost_recovery）+ `hardware_features_has`；`DeviceLimits`（max_buffer_elements、max_workgroup_size_x/y/z、max_workgroup_count_x/y/z、max_shared_memory_bytes_per_workgroup、max_bind_groups、max_storage_buffers_per_stage、min_storage_buffer_offset_alignment）。
- API：`hardware_enumerate_adapters`、`adapter_kind/features/limits`、`adapter_request_device(adapter, required) -> Result<Device, HardwareFault>`、`device_features/limits/is_lost`。
- 不变量：required ⊆ supported，否则 `feature_missing`；limits/features 创建时冻结只读；`is_lost` 单调。

## L2 内存模型

- 类型：`HeapClass`（device_local=1/host_visible=2/unified=3）；`BufferUsage` 位掩码（storage_read/storage_read_write/uniform/staging_upload/staging_readback/indirect/map_read/map_write）；`Heap`（容量/已分配记账）；`Buffer<T>`（堆身份 + offset + length + usage + map 状态 + 内容）。
- API：`device_create_heap`、`heap_allocate<T>(heap, length, usage, alignment)`、`buffer_map_read/map_write`、`buffer_unmap`、`buffer_copy_to`。
- 不变量：仅 host_visible/unified 可 map，device_local 必走 staging；**map 会话 = epoch 令牌**：map 发放递增 epoch，unmap 作废，旧令牌操作一律 `map_conflict`；unmap 是写可见性边界；OOM 永远结构化（容量记账）；alignment 为 2 幂档、offset 对齐。

## L3 队列与提交

- 类型：`QueueFamily`（compute=1/transfer=2/graphics=3）；`Queue`；`CommandBuffer`（状态机标量 + 记账）；`Fence`（时间线值）。
- API：`device_request_queue`、`command_begin/record_copy_buffer/record_dispatch/record_barrier/command_end`、`queue_submit(queue, cmd, wait) -> Result<Fence, HardwareFault>`、`fence_wait`、`fences_wait_all/any`。
- 不变量：状态机 recording→ended→submitted，仅 ended 可提交；同队列 FIFO；fence 值单调。
- **执行模型两分（合同条款）**：CPU 参考后端 = 立即执行（record 即生效，submit 签发 fence）；GPU 后端 = 延迟执行。conformance 只断言「提交后 fence 可达且结果可见」，不断言「录制后修改的可见性」。

## L4 计算管线

- 类型：`ShaderModule`（element_kind（i64=1；f32/f64 扩展位）+ workgroup_size_x/y/z + register_count + **扁平 `[i64]` 定长 4 字字节码**（opcode,a0,a1,a2），寄存器机、线性流、v1 无控制流）；`ComputePipeline`（冻结模块快照 + 并行标量数组绑定布局）；`BindSlotKind`（storage_read=1/storage_read_write=2/uniform=3）；`BindGroup`（布局关校验凭证；实体资源由 dispatch 调用点 `[Buffer<T>]` 参数携带）。
- 指令表 v1：`const=1`、`workitem_id=2`、`workgroup_id=3`、`load_storage=4`、`store_storage=5`、`add/sub/mul/div/rem=10..14`、`neg=15`、`barrier=20`、`return=255`。
- API：`shader_module_create`（opcode/寄存器/槽引用校验）、`pipeline_create(device, module, layout_slots, layout_kinds)`、`bind_group_validate<T>(pipeline, slots, buffers)`、`queue_dispatch<T>(queue, pipeline, group, buffers, x, y, z)`。
- 不变量：pipeline 创建即冻结 module 拷贝；store 槽必须 read_write；绑定槽集合恰好等于布局；元素类型全管一致；dispatch 各维 ≥1 且 ≤ limits；CPU 遍历顺序冻结（group 字典序 z→y→x、lane 字典序 x→y→z），作确定性数值基准。

## L5 渲染资源（合同 only）

- 类型：`TextureFormat`（rgba8unorm/bgra8unorm/rgba16float/rgba32float/depth24plus）；`TextureUsage` 位掩码（sampled/storage/render_attachment/copy_src/copy_dst）；`Tiling`（linear/optimal）；`Texture`、`Sampler`（filter/address/lod）。
- 当前只立合同与校验不变量（尺寸为正、mip ≤ log2(max 维)、format 受 feature 支持）；实现与用例未落地，不伪造。

## L6 故障与恢复

- `HardwareFault{code}`（code 为唯一权威字段）；`FaultCategory`（validation=1/out_of_memory=2/device_lost=3/feature_missing=4/unsupported=5/internal=6）；category/recoverable 经 `hardware_fault_category_of`/`hardware_fault_recoverable_of` 由注册表派生，三元组语义不变。
- 注册表：1001 device_mismatch(validation)、1002 capability_missing(validation)、1003 backend_unavailable(unsupported)、1004 out_of_memory(oom，**可恢复**)、1005 device_lost(device_lost，**不可恢复**)、1006 feature_missing(feature_missing，**可恢复**)、1007 usage_not_supported(unsupported)、1008 alignment_invalid(validation)、1009 dispatch_exceeds_limits(validation)、1010 command_state_invalid(validation)、1011 bind_layout_mismatch(validation)、1012 map_conflict(validation)、1013 shader_invalid(validation)。
- 恢复合同：lost 设备上一切操作 → `device_lost`；恢复 = 重新枚举 + request，无隐式恢复；recoverable=false 后同句柄不可复用。

## L7 后端

- **CPU 参考后端**：全合同纯 V 实现，确定性数值基准（correctness oracle），字节码解释器 + 立即执行队列 + 堆记账。
- **外部后端**：`hardware.adaptor.vulkan/dx12/webgpu/cuda` 为规划中的 adaptor 包；字节码 → SPIR-V/WGSL/PTX 翻译器属各 adaptor 实现，不进编译器。

## 验收口径

- 同一套 `hardware.conformance` 套件按合同项逐条跑，**每个注册后端必须全过**；CPU 全绿（wasm 真实执行）后才允许进入真后端块。
- `[test]` 套件为长期交付物；当前执行载体走消费方 `[export]` harness。
- blocked/pending 不计通过；不用旧「单后端 9/9」口径冒充验收。

## 当前已知限制

- 外部设备枚举的 `[host_contract]` 尚无 provider，相关调用返回结构化失败。
- 泛型 bound（`where K: Trait<T, U>`）反推与函数值实参调度在当前工具链不可解析，调度/工厂为自由函数形态。
- utf8 聚合字段与 `-> utf8` 字面量返回当前不可用，名称与诊断文案暂不提供。
- 聚合嵌套聚合当前不可物化：`Device` 不内嵌 `Limits`、模块持扁平字节码、`BindGroup` 作校验凭证、map 会话以 epoch 令牌为凭（形态稳定，非临时绕过）。
- 多字段结构暂不能作为 unite variant payload：`HardwareFault` 只携 code，category/recoverable 由注册表函数派生。
