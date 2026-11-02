# hardware._

`hardware._` 是异构设备抽象的顶层 workspace：GPU / 加速器 / CPU 的设备枚举、内存缓冲、传输与 kernel 调度。

## 定位

- 设备语义全部由本生态的普通 V 代码承载，**不进 nyar 编译器**，无编译器特判
- 非 CPU 后端（Vulkan / WebGPU / CUDA）通过正式 `[host_contract]` / `[host_provider]` 合同接入，带 capability 查询与 feature gate
- CPU 是纯 V 参考后端：传输为值语义快照，map/dispatch 为同步逐元素执行，始终可用
- 缺 host capability / provider 的部分记录坐标、结构化失败（`Fail(HardwareFault)`），不硬编码、不 fallback

## 组成

- `hardware`：核心包 —— `Device` / `Buffer` / `Queue` / `Kernel` 合同、CPU 参考后端、host capability 接入面
- 计划中：`hardware.adaptor.vulkan`、`hardware.adaptor.webgpu`、`hardware.adaptor.cuda`（各自 capability + feature gate，见包 readme 的后端 roadmap）

## 当前状态

- `hardware`：第一批落地（设备枚举、缓冲与传输、队列与 map dispatch、kernel trait 合同、CPU 后端），缺口坐标见 `projects/hardware/readme.md`

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
