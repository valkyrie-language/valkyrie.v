namespace yyds.kv;

# KvFault — 分片级结构化失败通道。
#
# 与引擎层 `DatabaseFault` 同形：失败要么未生效并携带稳定数值码返回，
# 要么整体生效；不产出部分结果。码表见包 readme「Fault 码注册表」。
structure KvFault {
    code: i64
}

# 批量已封口（commit/discard 后继续使用）。
micro kv_fault_batch_sealed() -> i64 {
    return 3001
}

# 游标未定位（key/value/revision 在无效位置被取用）。
micro kv_fault_cursor_invalid() -> i64 {
    return 3002
}

# 请求了分片不提供的持久原子提交边界（内存分片 fail-closed，不伪造）。
micro kv_fault_non_atomic_boundary() -> i64 {
    return 3003
}

# 无 panic 检查器：成功通道判定。
micro kv_outcome_is_fine<T>(outcome: Result<T, KvFault>) -> bool {
    return match outcome {
        case Fine(_value): true
        case Fail(_fault): false
    }
}

# 无 panic 检查器：失败码提取；成功通道返回 0（保留码之外）。
micro kv_outcome_fault_code<T>(outcome: Result<T, KvFault>) -> i64 {
    let no_fault: i64 = 0
    return match outcome {
        case Fine(_value): no_fault
        case Fail(fault): fault.code
    }
}

# 无 panic 取值：成功通道给出值，失败通道给出调用方备选。
micro kv_outcome_value_or<T>(outcome: Result<T, KvFault>, fallback: T) -> T {
    return match outcome {
        case Fine(value): value
        case Fail(_fault): fallback
    }
}

# 断言式取值：失败通道触发 panic（仅供测试在已判定 `is_fine` 后取用）。
micro kv_outcome_must<T>(outcome: Result<T, KvFault>) -> T {
    return match outcome {
        case Fine(value): value
        case Fail(_fault): panic("kv outcome must be fine")
    }
}
