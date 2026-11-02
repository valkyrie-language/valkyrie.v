namespace database;

# Transaction — 乐观事务。
#
# begin 冻结基线快照（行、表、revision）；读写都作用于"写集 + 基线"的 staged 视图，
# 读己之写成立， repeatable read 由快照语义保证。
# commit 先对写集内每个键做乐观验证（当前引擎 revision 与首次触碰时的基线一致），
# 全部通过才整体生效并逐条记日志；任一不符即 `transaction_conflict`，引擎分毫不动。
# rollback 直接丢弃 staged 视图。v1 不含事务内 DDL（建/删表走引擎直写）。
# 隔离级别当前只作登记：内存引擎一律提供快照隔离语义，不小于 repeatable read。

micro database_isolation_read_committed() -> i64 {
    return 1
}

micro database_isolation_repeatable_read() -> i64 {
    return 2
}

micro database_isolation_serializable() -> i64 {
    return 3
}

class Transaction {
    _backend: i64
    _closed: bool
    _isolation: i64
    _base_revision: i64
    _base_rows: [DatabaseRecord]
    _base_tables: [[u8]]
    _write_ops: [i64]
    _write_tables: [[u8]]
    _write_keys: [[u8]]
    _write_values: [[u8]]
    _write_base: [i64]
}

# 开启事务；引擎未声明事务能力即 `capability_missing`，级别未登记即 `invalid_argument`。
micro database_tx_begin(engine: DatabaseEngine, isolation: i64) -> Result<Transaction, DatabaseFault> {
    if !engine.is_open() {
        return Fail(DatabaseFault { code: database_fault_engine_closed() })
    }
    if !engine._cap_transactions {
        return Fail(DatabaseFault { code: database_fault_capability_missing() })
    }
    if isolation < database_isolation_read_committed() || isolation > database_isolation_serializable() {
        return Fail(DatabaseFault { code: database_fault_invalid_argument() })
    }
    return Fine(Transaction {
        _backend: engine._backend,
        _closed: false,
        _isolation: isolation,
        _base_revision: engine._next_revision,
        _base_rows: engine._rows,
        _base_tables: engine._tables,
        _write_ops: [],
        _write_tables: [],
        _write_keys: [],
        _write_values: [],
        _write_base: []
    })
}

# 写集内键的最新暂存下标（无则 -1）。
micro database_tx_write_index(tx: Transaction, table: [u8], key: [u8]) -> i64 {
    let count: i64 = tx._write_ops.length() as i64
    let mut found: i64 = -1
    let mut cursor: i64 = 0
    while cursor < count {
        let staged_table: [u8] = std::collection::array::get(tx._write_tables, cursor as usize)
        let staged_key: [u8] = std::collection::array::get(tx._write_keys, cursor as usize)
        if database_bytes_equal(staged_table, table) && database_bytes_equal(staged_key, key) {
            found = cursor
        }
        cursor = cursor + 1
    }
    return found
}

imply Transaction {
    micro is_closed(self) -> bool {
        return self._closed
    }

    micro isolation(self) -> i64 {
        return self._isolation
    }

    # 事务的基线 revision（begin 时刻引擎值）。
    micro base_revision(self) -> i64 {
        return self._base_revision
    }

    # 暂存写操作数。
    micro write_count(self) -> i64 {
        return self._write_ops.length() as i64
    }

    # 读：写集最新值优先，其次基线快照；表未注册（基线口径）即 `table_missing`。
    micro get(self, table: [u8], key: [u8]) -> Result<Option<[u8]>, DatabaseFault> {
        if self._closed {
            return Fail(DatabaseFault { code: database_fault_transaction_closed() })
        }
        if !database_catalog_tables_have(self._base_tables, table) {
            return Fail(DatabaseFault { code: database_fault_table_missing() })
        }
        let staged: i64 = database_tx_write_index(self, table, key)
        if staged >= 0 {
            let op: i64 = std::collection::array::get(self._write_ops, staged as usize)
            if op == database_journal_op_delete() {
                let missing: Option<[u8]> = None
                return Fine(missing)
            }
            return Fine(Some(std::collection::array::get(self._write_values, staged as usize)))
        }
        let slot: DatabaseSlot = database_engine_slot(self._base_rows, table, key)
        if database_slot_is_absent(slot) {
            let missing: Option<[u8]> = None
            return Fine(missing)
        }
        let row: DatabaseRecord = std::collection::array::get(self._base_rows, database_slot_index(slot) as usize)
        return Fine(Some(row.value))
    }

    # 暂存写入；首次触碰时记录基线 revision（0 表示基线缺席）。
    micro put(mut self, table: [u8], key: [u8], value: [u8]) -> Result<bool, DatabaseFault> {
        if self._closed {
            return Fail(DatabaseFault { code: database_fault_transaction_closed() })
        }
        if !database_catalog_tables_have(self._base_tables, table) {
            return Fail(DatabaseFault { code: database_fault_table_missing() })
        }
        database_tx_stage(self, database_journal_op_put(), table, key, value)
        return Fine(true)
    }

    # 暂存删除；缺席键也照常暂存（提交时按序生效）。
    micro delete(mut self, table: [u8], key: [u8]) -> Result<bool, DatabaseFault> {
        if self._closed {
            return Fail(DatabaseFault { code: database_fault_transaction_closed() })
        }
        if !database_catalog_tables_have(self._base_tables, table) {
            return Fail(DatabaseFault { code: database_fault_table_missing() })
        }
        database_tx_stage(self, database_journal_op_delete(), table, key, [])
        return Fine(true)
    }

    # 回滚：丢弃全部暂存，引擎分毫不动；幂等。
    micro rollback(mut self) -> unit {
        self._closed = true
    }
}

micro database_tx_stage(mut tx: Transaction, op: i64, table: [u8], key: [u8], value: [u8]) -> unit {
    let slot: DatabaseSlot = database_engine_slot(tx._base_rows, table, key)
    if database_slot_is_absent(slot) {
        tx._write_base = push(tx._write_base, 0)
    }
    else {
        let row: DatabaseRecord = std::collection::array::get(tx._base_rows, database_slot_index(slot) as usize)
        tx._write_base = push(tx._write_base, row.revision)
    }
    tx._write_ops = push(tx._write_ops, op)
    tx._write_tables = push(tx._write_tables, table)
    tx._write_keys = push(tx._write_keys, key)
    tx._write_values = push(tx._write_values, value)
}

# 提交：先验证（写集各键首次触碰的基线与当前引擎 revision 一致），再整体生效。
# 验证失败即 `transaction_conflict`，引擎分毫不动；成功返回最后写入的 revision。
micro database_tx_commit(mut engine: DatabaseEngine, mut tx: Transaction) -> Result<i64, DatabaseFault> {
    if tx._closed {
        return Fail(DatabaseFault { code: database_fault_transaction_closed() })
    }
    if !engine.is_open() {
        return Fail(DatabaseFault { code: database_fault_engine_closed() })
    }
    let count: i64 = tx._write_ops.length() as i64
    let mut cursor: i64 = 0
    while cursor < count {
        let table: [u8] = std::collection::array::get(tx._write_tables, cursor as usize)
        let key: [u8] = std::collection::array::get(tx._write_keys, cursor as usize)
        let first_touch: i64 = database_tx_first_touch(tx, table, key)
        if first_touch == cursor {
            let expected: i64 = std::collection::array::get(tx._write_base, cursor as usize)
            let slot: DatabaseSlot = database_engine_slot(engine._rows, table, key)
            let mut current: i64 = 0
            if !database_slot_is_absent(slot) {
                current = std::collection::array::get(engine._rows, database_slot_index(slot) as usize).revision
            }
            if current != expected {
                return Fail(DatabaseFault { code: database_fault_transaction_conflict() })
            }
        }
        cursor = cursor + 1
    }
    let mut applied_revision: i64 = engine._next_revision
    cursor = 0
    while cursor < count {
        let op: i64 = std::collection::array::get(tx._write_ops, cursor as usize)
        let table: [u8] = std::collection::array::get(tx._write_tables, cursor as usize)
        let key: [u8] = std::collection::array::get(tx._write_keys, cursor as usize)
        let value: [u8] = std::collection::array::get(tx._write_values, cursor as usize)
        applied_revision = applied_revision + 1
        database_engine_journal(engine, op, table, key, value, applied_revision)
        if op == database_journal_op_put() {
            engine._rows = database_engine_rows_put(engine._rows, database_record(table, key, value, applied_revision))
        }
        else {
            let slot: DatabaseSlot = database_engine_slot(engine._rows, table, key)
            if !database_slot_is_absent(slot) {
                engine._rows = database_engine_rows_remove(engine._rows, database_slot_index(slot))
            }
        }
        cursor = cursor + 1
    }
    engine._next_revision = applied_revision
    tx._closed = true
    return Fine(applied_revision)
}

# 写集内该键首次暂存的下标。
micro database_tx_first_touch(tx: Transaction, table: [u8], key: [u8]) -> i64 {
    let count: i64 = tx._write_ops.length() as i64
    let mut cursor: i64 = 0
    while cursor < count {
        let staged_table: [u8] = std::collection::array::get(tx._write_tables, cursor as usize)
        let staged_key: [u8] = std::collection::array::get(tx._write_keys, cursor as usize)
        if database_bytes_equal(staged_table, table) && database_bytes_equal(staged_key, key) {
            return cursor
        }
        cursor = cursor + 1
    }
    return -1
}
