namespace database;

# WriteBatch — 批量原子提交。
#
# 批量把一串 put/delete 暂存为一次提交边界：校验全部通过才整体生效，
# 任何一项表空间缺失都整体失败，不出现半提交状态。
# 空批量是幂等空操作（返回当前 revision，不消耗新 revision）。
# commit/discard 后批量封口，再用即 `batch_sealed`。
class WriteBatch {
    _backend: i64
    _sealed: bool
    _ops: [i64]
    _tables: [[u8]]
    _keys: [[u8]]
    _values: [[u8]]
}

# 以引擎后端身份开立批量（不读引擎状态，引擎关闭不影响开立）。
micro database_batch(engine: DatabaseEngine) -> WriteBatch {
    return WriteBatch {
        _backend: engine.backend(),
        _sealed: false,
        _ops: [],
        _tables: [],
        _keys: [],
        _values: []
    }
}

imply WriteBatch {
    # 暂存写入；已封口即 `batch_sealed`。
    micro put(mut self, table: [u8], key: [u8], value: [u8]) -> Result<bool, DatabaseFault> {
        if self._sealed {
            return Fail(DatabaseFault { code: database_fault_batch_sealed() })
        }
        self._ops = push(self._ops, database_journal_op_put())
        self._tables = push(self._tables, table)
        self._keys = push(self._keys, key)
        self._values = push(self._values, value)
        return Fine(true)
    }

    # 暂存删除；已封口即 `batch_sealed`。
    micro delete(mut self, table: [u8], key: [u8]) -> Result<bool, DatabaseFault> {
        if self._sealed {
            return Fail(DatabaseFault { code: database_fault_batch_sealed() })
        }
        self._ops = push(self._ops, database_journal_op_delete())
        self._tables = push(self._tables, table)
        self._keys = push(self._keys, key)
        self._values = push(self._values, [])
        return Fine(true)
    }

    micro count(self) -> i64 {
        return self._ops.length() as i64
    }

    micro is_empty(self) -> bool {
        return self.count() == 0
    }

    # 丢弃：封口且不生效任何暂存项。
    micro discard(mut self) -> unit {
        self._sealed = true
    }
}

# 原子提交：先校验全部表空间，再按序整体生效并逐条记日志，最后封口。
# 返回最后一次写入的 revision（空批量返回引擎当前 revision）。
micro database_batch_commit(mut engine: DatabaseEngine, mut batch: WriteBatch) -> Result<i64, DatabaseFault> {
    if !engine.is_open() {
        return Fail(DatabaseFault { code: database_fault_engine_closed() })
    }
    if batch._sealed {
        return Fail(DatabaseFault { code: database_fault_batch_sealed() })
    }
    if !engine._cap_batch_atomic {
        return Fail(DatabaseFault { code: database_fault_capability_missing() })
    }
    let count: i64 = batch.count()
    if count == 0 {
        batch._sealed = true
        return Fine(engine._next_revision)
    }
    let mut cursor: i64 = 0
    while cursor < count {
        let table: [u8] = std::collection::array::get(batch._tables, cursor as usize)
        if !database_engine_table_exists(engine, table) {
            return Fail(DatabaseFault { code: database_fault_table_missing() })
        }
        cursor = cursor + 1
    }
    let mut applied_revision: i64 = engine._next_revision
    cursor = 0
    while cursor < count {
        let op: i64 = std::collection::array::get(batch._ops, cursor as usize)
        let table: [u8] = std::collection::array::get(batch._tables, cursor as usize)
        let key: [u8] = std::collection::array::get(batch._keys, cursor as usize)
        let value: [u8] = std::collection::array::get(batch._values, cursor as usize)
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
    batch._sealed = true
    return Fine(applied_revision)
}
