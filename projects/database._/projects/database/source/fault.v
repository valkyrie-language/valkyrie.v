namespace database;

# DatabaseFault — 结构化硬失败通道。
#
# 数据库失败是硬失败：操作要么完整生效，要么整体不生效并携带稳定数值码返回。
# `code` 为稳定数值码（注册表见包 readme「Fault 码注册表」）；
# 人类可读诊断经投影函数提供（待 utf8 返回身份修复），不进聚合字段。
structure DatabaseFault {
    code: i64
}

# 引擎已关闭（对已关闭引擎的任何操作）。
micro database_fault_engine_closed() -> i64 {
    return 2001
}

# create_table 的目标表已存在。
micro database_fault_table_exists() -> i64 {
    return 2002
}

# 操作引用了未注册的表。
micro database_fault_table_missing() -> i64 {
    return 2003
}

# 游标未定位（key/value/revision 在无效位置被取用）。
micro database_fault_cursor_invalid() -> i64 {
    return 2004
}

# 事务提交时乐观验证失败（写集内键的当前 revision 与基线不符）。
micro database_fault_transaction_conflict() -> i64 {
    return 2005
}

# 事务已关闭（commit/rollback 后继续使用）。
micro database_fault_transaction_closed() -> i64 {
    return 2006
}

# 目标后端无已注册 provider。
micro database_fault_backend_unavailable() -> i64 {
    return 2007
}

# 请求了引擎未声明的持久性保证（如对非持久引擎要求 durable flush）。
micro database_fault_durability_unsupported() -> i64 {
    return 2008
}

# 编码/解码失败（memcomparable 或值编码的格式校验不通过）。
micro database_fault_corrupt_encoding() -> i64 {
    return 2009
}

# 操作需要引擎未声明的能力。
micro database_fault_capability_missing() -> i64 {
    return 2010
}

# 表名不合法（空名）。
micro database_fault_table_invalid() -> i64 {
    return 2011
}

# 批量已封口（commit/discard 后继续使用）。
micro database_fault_batch_sealed() -> i64 {
    return 2012
}

# 恢复重放发现日志与检查点不一致（内存引擎内部不变量破坏时才可达）。
micro database_fault_journal_corrupt() -> i64 {
    return 2013
}

# 参数不合法（如未登记的隔离级别）。
micro database_fault_invalid_argument() -> i64 {
    return 2014
}

# 无 panic 检查器：成功通道判定。
micro database_outcome_is_fine<T>(outcome: Result<T, DatabaseFault>) -> bool {
    return match outcome {
        case Fine(_value): true
        case Fail(_fault): false
    }
}

# 无 panic 检查器：失败码提取；成功通道返回 0（保留码之外）。
micro database_outcome_fault_code<T>(outcome: Result<T, DatabaseFault>) -> i64 {
    let no_fault: i64 = 0
    return match outcome {
        case Fine(_value): no_fault
        case Fail(fault): fault.code
    }
}

# 无 panic 取值：成功通道给出值，失败通道给出调用方备选。
micro database_outcome_value_or<T>(outcome: Result<T, DatabaseFault>, fallback: T) -> T {
    return match outcome {
        case Fine(value): value
        case Fail(_fault): fallback
    }
}

# 断言式取值：失败通道触发 panic（仅供 harness/套件在已判定 `is_fine` 后取用）。
micro database_outcome_must<T>(outcome: Result<T, DatabaseFault>) -> T {
    return match outcome {
        case Fine(value): value
        case Fail(_fault): panic("database outcome must be fine")
    }
}
