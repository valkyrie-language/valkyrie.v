namespace hardware;

# fault 层：结构化故障分类表。
#
# HardwareFault 三要素（code / category / recoverable）在注册表一一对应；
# 分类用于消费方决定恢复策略，数值码用于稳定诊断身份。
# 不变量：recoverable = false 的故障之后，同一句柄不得继续使用。
