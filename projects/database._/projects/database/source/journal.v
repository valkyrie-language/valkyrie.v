namespace database;

# Journal（WAL 语义）。
#
# 每次状态变更先记日志再发布：日志条目携带 op、表、键、值与 revision。
# `flush` 推进已刷盘边界（内存引擎不承诺持久，`require_durable` 必失败）；
# `checkpoint` 把当前状态冻结为恢复点并折叠日志；
# `simulate_crash` 表达"断电后重开"：主状态回到检查点、未刷盘日志丢失；
# `recover` 依序重放幸存日志恢复主状态。
# 全部语义在内存引擎内真实成立，不伪造持久性。

micro database_journal_op_put() -> i64 {
    return 1
}

micro database_journal_op_delete() -> i64 {
    return 2
}

micro database_journal_op_create_table() -> i64 {
    return 3
}

micro database_journal_op_drop_table() -> i64 {
    return 4
}

# 追加一条日志（WAL：先于状态发布调用）。
micro database_engine_journal(mut engine: DatabaseEngine, op: i64, table: [u8], key: [u8], value: [u8], revision: i64) -> unit {
    engine._journal_ops = push(engine._journal_ops, op)
    engine._journal_tables = push(engine._journal_tables, table)
    engine._journal_keys = push(engine._journal_keys, key)
    engine._journal_values = push(engine._journal_values, value)
    engine._journal_revisions = push(engine._journal_revisions, revision)
}

imply DatabaseEngine {
    # 当前日志条数（自上次检查点）。
    micro journal_length(self) -> i64 {
        return self._journal_ops.length() as i64
    }

    # 已刷盘边界（条数）。
    micro journal_flushed(self) -> i64 {
        return self._flushed_count
    }

    # flush：把已刷盘边界推进到当前日志末尾，返回新边界。
    # `require_durable` 而引擎无持久能力时 `durability_unsupported`，边界不动。
    micro flush(mut self, require_durable: bool) -> Result<i64, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        if require_durable && !self._cap_durable {
            return Fail(DatabaseFault { code: database_fault_durability_unsupported() })
        }
        self._flushed_count = self.journal_length()
        self._flush_calls = self._flush_calls + 1
        return Fine(self._flushed_count)
    }

    # checkpoint：冻结当前状态为恢复点、折叠全部日志，返回检查点 revision。
    micro checkpoint(mut self) -> Result<i64, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        self._checkpoint_rows = self._rows
        self._checkpoint_tables = self._tables
        self._checkpoint_revision = self._next_revision
        self._checkpoint_catalog_revision = self._catalog_revision
        self._journal_ops = []
        self._journal_tables = []
        self._journal_keys = []
        self._journal_values = []
        self._journal_revisions = []
        self._flushed_count = 0
        return Fine(self._checkpoint_revision)
    }

    micro checkpoint_revision(self) -> i64 {
        return self._checkpoint_revision
    }

    # 模拟断电后重开：主状态回到检查点，未刷盘日志丢失，
    # 引擎标记为待恢复——恢复前一律 `engine_closed`，不静默提供读写。
    # 显式逐字段构造新实例（class 为引用语义，不能用别名拷贝）。
    micro simulate_crash(self) -> DatabaseEngine {
        return DatabaseEngine {
            _backend: self._backend,
            _open: false,
            _needs_recovery: true,
            _cap_transactions: self._cap_transactions,
            _cap_snapshots: self._cap_snapshots,
            _cap_reverse_cursor: self._cap_reverse_cursor,
            _cap_batch_atomic: self._cap_batch_atomic,
            _cap_wal: self._cap_wal,
            _cap_durable: self._cap_durable,
            _tables: self._checkpoint_tables,
            _catalog_revision: self._checkpoint_catalog_revision,
            _rows: self._checkpoint_rows,
            _next_revision: self._checkpoint_revision,
            _journal_ops: database_engine_i64_prefix(self._journal_ops, self._flushed_count),
            _journal_tables: database_engine_bytes_prefix(self._journal_tables, self._flushed_count),
            _journal_keys: database_engine_bytes_prefix(self._journal_keys, self._flushed_count),
            _journal_values: database_engine_bytes_prefix(self._journal_values, self._flushed_count),
            _journal_revisions: database_engine_i64_prefix(self._journal_revisions, self._flushed_count),
            _flushed_count: self._flushed_count,
            _flush_calls: self._flush_calls,
            _checkpoint_revision: self._checkpoint_revision,
            _checkpoint_catalog_revision: self._checkpoint_catalog_revision,
            _checkpoint_tables: self._checkpoint_tables,
            _checkpoint_rows: self._checkpoint_rows
        }
    }

    # 恢复：依序重放幸存日志（携带原 revision），返回重放条数。
    # 无需恢复时是 `Fine(0)` 幂等空操作。
    micro recover(mut self) -> Result<i64, DatabaseFault> {
        if !self._needs_recovery {
            return Fine(0)
        }
        let pending: i64 = self._journal_ops.length() as i64
        let mut cursor: i64 = 0
        while cursor < pending {
            let op: i64 = std::collection::array::get(self._journal_ops, cursor as usize)
            let table: [u8] = std::collection::array::get(self._journal_tables, cursor as usize)
            let key: [u8] = std::collection::array::get(self._journal_keys, cursor as usize)
            let value: [u8] = std::collection::array::get(self._journal_values, cursor as usize)
            let revision: i64 = std::collection::array::get(self._journal_revisions, cursor as usize)
            database_engine_replay(self, op, table, key, value, revision)
            if revision > self._next_revision {
                self._next_revision = revision
            }
            cursor = cursor + 1
        }
        self._open = true
        self._needs_recovery = false
        return Fine(pending)
    }
}

# 重放单条日志（恢复内部步骤；条目携带的 revision 原样落回）。
micro database_engine_replay(mut engine: DatabaseEngine, op: i64, table: [u8], key: [u8], value: [u8], revision: i64) -> unit {
    if op == database_journal_op_put() {
        engine._rows = database_engine_rows_put(engine._rows, database_record(table, key, value, revision))
        return
    }
    if op == database_journal_op_delete() {
        let slot: DatabaseSlot = database_engine_slot(engine._rows, table, key)
        if !database_slot_is_absent(slot) {
            engine._rows = database_engine_rows_remove(engine._rows, database_slot_index(slot))
        }
        return
    }
    if op == database_journal_op_create_table() {
        if !database_engine_table_exists(engine, table) {
            engine._tables = push(engine._tables, table)
        }
        engine._catalog_revision = engine._catalog_revision + 1
        return
    }
    if op == database_journal_op_drop_table() {
        engine._tables = database_engine_tables_remove(engine._tables, table)
        engine._rows = database_engine_rows_drop_table(engine._rows, table)
        engine._catalog_revision = engine._catalog_revision + 1
        return
    }
}

micro database_engine_i64_prefix(data: [i64], count: i64) -> [i64] {
    let mut out: [i64] = []
    let mut index: i64 = 0
    while index < count {
        out = push(out, std::collection::array::get(data, index as usize))
        index = index + 1
    }
    return out
}

micro database_engine_bytes_prefix(data: [[u8]], count: i64) -> [[u8]] {
    let mut out: [[u8]] = []
    let mut index: i64 = 0
    while index < count {
        out = push(out, std::collection::array::get(data, index as usize))
        index = index + 1
    }
    return out
}
