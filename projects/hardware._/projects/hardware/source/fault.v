namespace hardware;

# HardwareFault — 结构化失败通道。
#
# `code` 为稳定数值码（注册表见包 readme「Fault 码注册表」）；
# 人类可读诊断经 `hardware_fault_message` 投影，不把 utf8 存进聚合。

structure HardwareFault {
    code: i64
}

# 缓冲/队列/目标设备身份不一致。
micro hardware_fault_device_mismatch() -> i64 {
    return 1001
}

# 设备未声明所需能力（如 map_kernel）。
micro hardware_fault_capability_missing() -> i64 {
    return 1002
}

# 目标后端无已注册 provider。
micro hardware_fault_backend_unavailable() -> i64 {
    return 1003
}

# 诊断文案投影（`hardware_fault_message`）待 utf8 返回身份修复后落地。

# 无 panic 检查器：成功通道判定。
micro hardware_outcome_is_fine<T>(outcome: Result<T, HardwareFault>) -> bool {
    return match outcome {
        case Fine(_value): true
        case Fail(_fault): false
    }
}

# 无 panic 检查器：失败码提取；成功通道返回 0（保留码之外）。
micro hardware_outcome_fault_code<T>(outcome: Result<T, HardwareFault>) -> i64 {
    let no_fault: i64 = 0
    return match outcome {
        case Fine(_value): no_fault
        case Fail(fault): fault.code
    }
}

# 无 panic 取值：成功通道给出值，失败通道给出调用方备选。
micro hardware_outcome_value_or<T>(outcome: Result<T, HardwareFault>, fallback: T) -> T {
    return match outcome {
        case Fine(value): value
        case Fail(_fault): fallback
    }
}
