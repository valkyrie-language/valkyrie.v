namespace hardware;

# HardwareFault — 结构化故障：code 为唯一权威字段；
# category / recoverable 由注册表函数按码派生（三元组语义不变）。
# 形态说明：多字段结构作 unite variant payload 在当前工具链运行时 illegal cast（当前工具链运行时不支持该形态），
# 单字段可用；code 本就是注册表唯一真源，派生字段不载体化。

structure HardwareFault {
    code: i64
}

# FaultCategory 词汇。
micro hardware_category_validation() -> i64 {
    return 1
}

micro hardware_category_out_of_memory() -> i64 {
    return 2
}

micro hardware_category_device_lost() -> i64 {
    return 3
}

micro hardware_category_feature_missing() -> i64 {
    return 4
}

micro hardware_category_unsupported() -> i64 {
    return 5
}

micro hardware_category_internal() -> i64 {
    return 6
}

# 故障码注册表（code ↔ category ↔ recoverable 三元组一一对应，禁止复用/改义）。

# 1001 缓冲/队列/目标设备身份不一致。
micro hardware_fault_device_mismatch() -> i64 {
    return 1001
}

# 1002 设备未声明所需能力（如 map_kernel）。
micro hardware_fault_capability_missing() -> i64 {
    return 1002
}

# 1003 目标后端无已注册 provider。
micro hardware_fault_backend_unavailable() -> i64 {
    return 1003
}

# 1004 堆容量不足（OOM；可恢复——释放或换更小分配可重试）。
micro hardware_fault_out_of_memory() -> i64 {
    return 1004
}

# 1005 设备丢失（不可恢复；句柄作废，需重新枚举）。
micro hardware_fault_device_lost() -> i64 {
    return 1005
}

# 1006 请求的 features 超出设备支持集（可恢复——降级请求可重试）。
micro hardware_fault_feature_missing() -> i64 {
    return 1006
}

# 1007 请求的 usage/形态超出设备支持集。
micro hardware_fault_usage_not_supported() -> i64 {
    return 1007
}

# 1008 对齐参数非法（非 2 幂或越档）。
micro hardware_fault_alignment_invalid() -> i64 {
    return 1008
}

# 1009 dispatch 维度为 0 或超出设备 limits。
micro hardware_fault_dispatch_exceeds_limits() -> i64 {
    return 1009
}

# 1010 命令缓冲状态机违规（未结束就提交、提交后再录制）。
micro hardware_fault_command_state_invalid() -> i64 {
    return 1010
}

# 1011 绑定组与管线布局不一致（槽位集合、kind 或范围不符）。
micro hardware_fault_bind_layout_mismatch() -> i64 {
    return 1011
}

# 1012 map 会话冲突（重复 map 或旧会话未关闭）。
micro hardware_fault_map_conflict() -> i64 {
    return 1012
}

# 1013 shader 模块非法（未知 opcode、寄存器越界、槽引用越界）。
micro hardware_fault_shader_invalid() -> i64 {
    return 1013
}

# 码 → 分类。
micro hardware_fault_category_of(code: i64) -> i64 {
    if code == hardware_fault_out_of_memory() {
        return hardware_category_out_of_memory()
    }
    if code == hardware_fault_device_lost() {
        return hardware_category_device_lost()
    }
    if code == hardware_fault_feature_missing() {
        return hardware_category_feature_missing()
    }
    if code == hardware_fault_backend_unavailable() || code == hardware_fault_usage_not_supported() {
        return hardware_category_unsupported()
    }
    return hardware_category_validation()
}

# 码 → 可恢复标记。
micro hardware_fault_recoverable_of(code: i64) -> bool {
    if code == hardware_fault_out_of_memory() || code == hardware_fault_feature_missing() {
        return true
    }
    return false
}

# 无 panic 检查器：成功通道判定。
micro hardware_outcome_is_fine<T>(outcome: Result<T, HardwareFault>) -> bool {
    return match outcome {
        case Fine(_value): true
        case Fail(_fault): false
    }
}

# 无 panic 检查器：失败码提取；成功通道返回 0（注册表之外）。
micro hardware_outcome_fault_code<T>(outcome: Result<T, HardwareFault>) -> i64 {
    let no_fault: i64 = 0
    return match outcome {
        case Fine(_value): no_fault
        case Fail(fault): fault.code
    }
}

# 无 panic 检查器：失败分类提取（经注册表派生）；成功通道返回 0。
micro hardware_outcome_fault_category<T>(outcome: Result<T, HardwareFault>) -> i64 {
    let no_fault: i64 = 0
    return match outcome {
        case Fine(_value): no_fault
        case Fail(fault): hardware_fault_category_of(fault.code)
    }
}

# 无 panic 检查器：失败可恢复标记提取（经注册表派生）；成功通道返回 false。
micro hardware_outcome_fault_recoverable<T>(outcome: Result<T, HardwareFault>) -> bool {
    return match outcome {
        case Fine(_value): false
        case Fail(fault): hardware_fault_recoverable_of(fault.code)
    }
}

# 无 panic 取值：成功通道给出值，失败通道给出调用方备选。
micro hardware_outcome_value_or<T>(outcome: Result<T, HardwareFault>, fallback: T) -> T {
    return match outcome {
        case Fine(value): value
        case Fail(_fault): fallback
    }
}
