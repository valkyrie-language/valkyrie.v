namespace hardware;

# hardware — 异构设备抽象（GPU/加速器/CPU）核心包。
#
# 合同面：Device / Buffer / Queue / Kernel 四层 + backend 接入面。
# 原则：
# - 设备语义不进 nyar 编译器；非 CPU 后端经 [host_contract]/[host_provider] 唯一路径接入。
# - CPU 是纯 V 参考后端，始终可用；外部后端缺 provider 时结构化失败（HardwareFault），不伪造。
# - 当前工具链洪泛期的构造约束（utf8 聚合字段、函数值聚合字段等）与缺口坐标见包 readme。
