# hardware._

`hardware._` 是异构设备抽象的顶层 workspace —— **GPU 计算基石**，承接后续的游戏、渲染与深度学习。

## 定位

- 设备语义全部由本生态的普通 V 代码承载，**不进 nyar 编译器**，无编译器特判
- 非 CPU 后端（Vulkan / DX12 / WebGPU / CUDA）通过正式 `[host_contract]` / `[host_provider]` 合同接入，带能力查询与限制结构
- CPU 是纯 V 参考后端：全合同实现，确定性数值基准（correctness oracle）
- 缺 host capability / provider 的操作返回结构化失败（`HardwareFault`），不硬编码、不 fallback

## 组成

- `hardware`：核心包 —— 七层冻结合同（device / memory / queue / pipeline / texture / fault / backend）
- `hardware.conformance`：合同项 conformance 套件 —— 同一套对每个注册后端运行，CPU 全绿后才进入真后端块
- 计划中：`hardware.adaptor.vulkan`、`hardware.adaptor.dx12`、`hardware.adaptor.webgpu`、`hardware.adaptor.cuda`

## 当前状态

- 七层合同已冻结，合同全文：[projects/hardware/readme.md](projects/hardware/readme.md)
- conformance 矩阵：[projects/hardware.conformance/readme.md](projects/hardware.conformance/readme.md)

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
