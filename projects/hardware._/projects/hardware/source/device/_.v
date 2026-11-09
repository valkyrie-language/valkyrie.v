namespace hardware;

# device 层：物理设备枚举、能力集合（Features 位掩码）、限制结构（DeviceLimits）与设备句柄。
#
# 不变量：
# - request_device 的 required features 必须是 adapter 支持集的子集，否则结构化失败；
# - limits/features 在设备创建时冻结，之后只读；
# - 外部后端的枚举经 host capability 接入（当前无 provider），provider 缺位不伪造设备。
