namespace hardware;

# hardware — 异构设备抽象核心包（GPU 计算基石），承接游戏、渲染与深度学习。
#
# 七层合同（冻结，见包 readme）：device（适配器/设备/能力/限制）→ memory（堆可见性、
# 缓冲 usage、map/unmap 相干性、staging、OOM）→ queue（队列族、命令录制、fence 时间线）→
# pipeline（shader 字节码 IR、计算管线、绑定槽位、dispatch）→ texture（渲染资源，合同 only）→
# fault（结构化故障分类表）→ backend（CPU 参考实现 + host capability 接入面）。
#
# 原则：设备语义不进 nyar 编译器；外部后端只经 [host_contract]/[host_provider] 接入；
# 缺能力/provider 时结构化失败，不硬编码、不 fallback、不伪造。
