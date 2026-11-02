namespace database.conformance;

# 内存参考引擎的验收入口：`[main]` 聚合跑全部合同项，逐用例另有 `[export]`。
# 返回口径：0 = 全绿；非 0 = 用例号 * 100 + 阶段号，定位首个失败点。
# 外部适配器以各自工厂复用 `conformance_c*` 用例函数，不走本入口。

[main]
micro main() -> i32 {
    let mut code: i64 = conformance_c01_engine_open_close(database::database_memory_open)
    if code != 0 {
        return (100 + code) as i32
    }
    code = conformance_c02_catalog(database::database_memory_open)
    if code != 0 {
        return (200 + code) as i32
    }
    code = conformance_c03_read_write(database::database_memory_open)
    if code != 0 {
        return (300 + code) as i32
    }
    code = conformance_c04_cursor(database::database_memory_open)
    if code != 0 {
        return (400 + code) as i32
    }
    code = conformance_c05_write_batch(database::database_memory_open)
    if code != 0 {
        return (500 + code) as i32
    }
    code = conformance_c06_transaction(database::database_memory_open)
    if code != 0 {
        return (600 + code) as i32
    }
    code = conformance_c07_snapshot(database::database_memory_open)
    if code != 0 {
        return (700 + code) as i32
    }
    code = conformance_c08_journal_recovery(database::database_memory_open)
    if code != 0 {
        return (800 + code) as i32
    }
    code = conformance_c09_key_encoding(database::database_memory_open)
    if code != 0 {
        return (900 + code) as i32
    }
    code = conformance_c10_statistics(database::database_memory_open)
    if code != 0 {
        return (1000 + code) as i32
    }
    code = conformance_c11_revision_monotonicity(database::database_memory_open)
    if code != 0 {
        return (1100 + code) as i32
    }
    code = conformance_c12_interleave_consistency(database::database_memory_open)
    if code != 0 {
        return (1200 + code) as i32
    }
    code = conformance_c13_value_ordering(database::database_memory_open)
    if code != 0 {
        return (1300 + code) as i32
    }
    code = conformance_c14_fault_model(database::database_memory_open)
    if code != 0 {
        return (1400 + code) as i32
    }
    code = conformance_c15_index_surface(database::database_memory_open)
    if code != 0 {
        return (1500 + code) as i32
    }
    return 0
}

[export]
micro conformance_memory_c01() -> i64 {
    return conformance_c01_engine_open_close(database::database_memory_open)
}

[export]
micro conformance_memory_c02() -> i64 {
    return conformance_c02_catalog(database::database_memory_open)
}

[export]
micro conformance_memory_c03() -> i64 {
    return conformance_c03_read_write(database::database_memory_open)
}

[export]
micro conformance_memory_c04() -> i64 {
    return conformance_c04_cursor(database::database_memory_open)
}

[export]
micro conformance_memory_c05() -> i64 {
    return conformance_c05_write_batch(database::database_memory_open)
}

[export]
micro conformance_memory_c06() -> i64 {
    return conformance_c06_transaction(database::database_memory_open)
}

[export]
micro conformance_memory_c07() -> i64 {
    return conformance_c07_snapshot(database::database_memory_open)
}

[export]
micro conformance_memory_c08() -> i64 {
    return conformance_c08_journal_recovery(database::database_memory_open)
}

[export]
micro conformance_memory_c09() -> i64 {
    return conformance_c09_key_encoding(database::database_memory_open)
}

[export]
micro conformance_memory_c10() -> i64 {
    return conformance_c10_statistics(database::database_memory_open)
}

[export]
micro conformance_memory_c11() -> i64 {
    return conformance_c11_revision_monotonicity(database::database_memory_open)
}

[export]
micro conformance_memory_c12() -> i64 {
    return conformance_c12_interleave_consistency(database::database_memory_open)
}

[export]
micro conformance_memory_c13() -> i64 {
    return conformance_c13_value_ordering(database::database_memory_open)
}

[export]
micro conformance_memory_c14() -> i64 {
    return conformance_c14_fault_model(database::database_memory_open)
}

[export]
micro conformance_memory_c15() -> i64 {
    return conformance_c15_index_surface(database::database_memory_open)
}
