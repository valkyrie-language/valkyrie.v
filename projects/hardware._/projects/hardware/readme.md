# hardware

异构设备抽象核心包：`Device` / `Buffer` / `Queue` / `Kernel` 合同与 CPU 参考后端。

## 分层

```text
source/
├── device/    设备描述、能力（DeviceCapabilities）、枚举与设备身份比较
├── buffer/    泛型缓冲 Buffer<T>：host↔device 写读、device↔device 传输
├── queue/     命令队列 Queue：提交计数、同步等待、map kernel 调度
├── kernel/    Kernel trait 合同（apply: T -> U）
└── backend/   后端实现与接入面：cpu.v 为纯 V 参考后端，host.v 登记 host capability 缺口
```

## 模型约定

- **设备身份是数值**：`backend_token` + `ordinal`（均为 `i64`）参与相等比较；人类可读名称
  投影待 utf8 返回身份修复后提供，不进聚合字段。
- **能力随设备携带**：`Device.capabilities` 在枚举时构造，能力查询是纯字段读取，不回调宿主。
- **错误走 `Result<T, HardwareFault>`**：`HardwareFault.code` 为稳定数值码（注册表见下文），
  配套 `hardware_outcome_is_fine` / `hardware_outcome_fault_code` / `hardware_outcome_value_or`
  无 panic 检查器。
- **传输语义**：CPU 后端为值语义快照拷贝；未知/外部后端 `Fail(hardware_fault_backend_unavailable())`。
- **调度语义**：`hardware_dispatch_map` 校验队列与输入缓冲同设备、设备声明 `map_kernel`
  能力，CPU 后端同步逐元素执行并累加提交计数。

## Fault 码注册表

| 码   | 常量函数 | 含义 |
|---|---|---|
| 1001 | `hardware_fault_device_mismatch` | 缓冲/队列/目标设备身份不一致 |
| 1002 | `hardware_fault_capability_missing` | 设备未声明所需能力（如 `map_kernel`） |
| 1003 | `hardware_fault_backend_unavailable` | 目标后端无已注册 provider |

## 后端 roadmap

| 后端 | 形态 | 状态 |
|---|---|---|
| CPU | 纯 V 参考后端（`backend/cpu.v`） | 第一批落地 |
| Vulkan | `hardware.adaptor.vulkan`：`[host_provider]` 绑定枚举/缓冲/kernel 模块加载，feature gate 按目标条件 | 后续块 |
| WebGPU | `hardware.adaptor.webgpu`：wasm/browser 目标的 host capability | 后续块 |
| CUDA | `hardware.adaptor.cuda`：native 目标的 host capability | 后续块 |

后端接入纪律：provider 只经 `[host_contract]`/`[host_provider]` 唯一路径，不做编译器特判；
能力查询与限制由各后端在枚举时填入 `DeviceCapabilities`，缺事实即结构化失败。

## 当前已知限制

- 外部设备枚举：`[host_contract] hardware_host_enumerate_devices` 无 provider（所属面：
  `source/backend/host.v`）；`hardware_enumerate_devices` 当前只返回 CPU 参考设备。
- kernel 的 trait-bound 泛型调度：`where K: Kernel<T, U>` 由 `K` 反推 `T`/`U` 的调用点
  在当前编译器不可解析（`unresolved call`），方法级泛型 `imply` 内 `<T, U>` 与函数值实参
  的组合同样不可解析；本批口径：`Kernel` trait 直接 `.apply` 消费，泛型 map 调度为自由函数
  `hardware_dispatch_map(queue, input, mapper: micro(T) -> U)`。
- utf8 物化链断裂（双段）：含 `utf8` 字段的聚合构造器不可解析（`unresolved constructor`）；
  `-> utf8` 函数返回字面量与声明类型身份不一致被拒。设备名/后端名/诊断文案投影
  整体待编译器类型身份链修复后落地，当前 API 面保持数值/布尔/聚合。
- 函数值聚合字段：函数类型作为聚合字段时构造器不可解析；kernel 行为以 trait/参数传递，
  不存入聚合（std 的 `MapIterator` 同形字段亦按目标 gate）。
- `[test]` 入口双重断链：test 语义组注入 prelude 后 `std.primitive` 算子候选不可见
  （裸 `infix +`/`!=` 即 unresolved）；经 std 泛型（`push` → `array::new::<T>`）的开放实例
  在 test 根下报「调用实例没有定义或显式导入合同」。两条在 `[export]` 路径均不存在；
  `test/` 套件暂不能作为执行证据，以消费方 `[export]` harness 实测替代。归属编译器侧。
- OVM 运行时 host import 缺口：`nyar.host::i64_lt_u` 在 OVM 加载期不识别。std `push`
  的 V 默认体含 `usize` 比较，凡经 `push` 重建数组的模块在 OVM 加载期被拒；本包循环一律
  i64 计数 + `as usize`（所属面：`source/backend/cpu.v`），buffer/queue 层 OVM 执行因此暂停点。
- OVM 函数值调度缺口：函数值间接调用在 OVM 后端构建期 panic（未绑定调用实例）。
  `hardware_dispatch_map` 的 mapper 与 `Kernel.apply` 因此在 OVM 暂不可编译，
  wasm lane 已实测通过；JVM/CLR 未在本批验收范围。
- `let` 绑定 match 联合类型：`let x: T = match ...` 与控制流 join 上裸整数字面量
  （i32 原始身份 vs 名义身份）分裂被拒；本包代码一律 `return match` 且分支齐型。
- OVM 枚举返回边界：`hardware_enumerate_devices` 在 OVM 真实执行返回
  「expected i64, got null」——聚合数组字面量 `[device]` 的物化/返回边界缺口；
  设备构造与 `hardware_device_equals` 在 OVM 已实测通过。
