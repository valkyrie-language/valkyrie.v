namespace database;

# 后端身份词汇。
micro database_backend_memory() -> i64 {
    return 1
}

# 打开参数（平直标量）。
# 内存引擎总是新实例：`create_if_missing` / `error_if_exists` 被接受但不生效
# （内存无持久身份，不伪造"已存在"语义）。外部后端的连接参数由适配器自身面提供。
structure DatabaseOpenOptions {
    backend: i64
    create_if_missing: bool
    error_if_exists: bool
}

micro database_open_options(backend: i64) -> DatabaseOpenOptions {
    return DatabaseOpenOptions {
        backend: backend,
        create_if_missing: true,
        error_if_exists: false
    }
}

# 内存参考引擎的零参工厂：conformance 套件与早期集成的标准入口。
micro database_memory_open() -> Result<DatabaseEngine, DatabaseFault> {
    return DatabaseEngine::open(database_open_options(database_backend_memory()))
}

# DatabaseEngine — 引擎句柄与全部可变状态。
#
# 引擎层键值是不透明字节；记录按（表空间, 键）无符号字节字典序排列。
# 内存参考引擎把全部状态放在 V 值内：快照/崩溃/恢复因此可用纯值语义表达。
# 能力面在打开时按后端写入，查询是纯字段读取，不回调宿主。
class DatabaseEngine {
    _backend: i64
    _open: bool
    _needs_recovery: bool
    _cap_transactions: bool
    _cap_snapshots: bool
    _cap_reverse_cursor: bool
    _cap_batch_atomic: bool
    _cap_wal: bool
    _cap_durable: bool
    _cap_ordered_index: bool
    _cap_hash_index: bool
    _tables: [[u8]]
    _catalog_revision: i64
    _rows: [DatabaseRecord]
    _next_revision: i64
    _journal_ops: [i64]
    _journal_tables: [[u8]]
    _journal_keys: [[u8]]
    _journal_values: [[u8]]
    _journal_revisions: [i64]
    _flushed_count: i64
    _flush_calls: i64
    _checkpoint_revision: i64
    _checkpoint_catalog_revision: i64
    _checkpoint_tables: [[u8]]
    _checkpoint_rows: [DatabaseRecord]
}

imply DatabaseEngine {
    # 打开引擎。后端未注册即 `backend_unavailable`，不伪造可用引擎。
    micro open(options: DatabaseOpenOptions) -> Result<DatabaseEngine, DatabaseFault> {
        if options.backend != database_backend_memory() {
            return Fail(DatabaseFault { code: database_fault_backend_unavailable() })
        }
        return Fine(DatabaseEngine {
            _backend: options.backend,
            _open: true,
            _needs_recovery: false,
            _cap_transactions: true,
            _cap_snapshots: true,
            _cap_reverse_cursor: true,
            _cap_batch_atomic: true,
            _cap_wal: true,
            _cap_durable: false,
            _cap_ordered_index: true,
            _cap_hash_index: false,
            _tables: [],
            _catalog_revision: 0,
            _rows: [],
            _next_revision: 0,
            _journal_ops: [],
            _journal_tables: [],
            _journal_keys: [],
            _journal_values: [],
            _journal_revisions: [],
            _flushed_count: 0,
            _flush_calls: 0,
            _checkpoint_revision: 0,
            _checkpoint_catalog_revision: 0,
            _checkpoint_tables: [],
            _checkpoint_rows: []
        })
    }

    # 关闭。幂等；对已关闭引擎的操作一律 `engine_closed`。
    micro close(mut self) -> unit {
        self._open = false
    }

    micro is_open(self) -> bool {
        return self._open && !self._needs_recovery
    }

    micro backend(self) -> i64 {
        return self._backend
    }

    micro cap_transactions(self) -> bool {
        return self._cap_transactions
    }

    micro cap_snapshots(self) -> bool {
        return self._cap_snapshots
    }

    micro cap_reverse_cursor(self) -> bool {
        return self._cap_reverse_cursor
    }

    micro cap_batch_atomic(self) -> bool {
        return self._cap_batch_atomic
    }

    micro cap_wal(self) -> bool {
        return self._cap_wal
    }

    micro cap_durable(self) -> bool {
        return self._cap_durable
    }

    micro cap_ordered_index(self) -> bool {
        return self._cap_ordered_index
    }

    micro cap_hash_index(self) -> bool {
        return self._cap_hash_index
    }

    micro revision(self) -> i64 {
        return self._next_revision
    }

    micro catalog_revision(self) -> i64 {
        return self._catalog_revision
    }

    # 点查：表未注册即 `table_missing`；键缺席不是失败，走 `None`。
    micro get(self, table: [u8], key: [u8]) -> Result<Option<[u8]>, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        if !database_engine_table_exists(self, table) {
            return Fail(DatabaseFault { code: database_fault_table_missing() })
        }
        let slot: DatabaseSlot = database_engine_slot(self._rows, table, key)
        if database_slot_is_absent(slot) {
            let missing: Option<[u8]> = None
            return Fine(missing)
        }
        let row: DatabaseRecord = std::collection::array::get(self._rows, database_slot_index(slot) as usize)
        return Fine(Some(row.value))
    }

    # 写入：先记日志（WAL 语义），再发布状态；返回新 revision。
    micro put(mut self, table: [u8], key: [u8], value: [u8]) -> Result<i64, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        if !database_engine_table_exists(self, table) {
            return Fail(DatabaseFault { code: database_fault_table_missing() })
        }
        let revision: i64 = self._next_revision + 1
        database_engine_journal(self, database_journal_op_put(), table, key, value, revision)
        self._rows = database_engine_rows_put(self._rows, database_record(table, key, value, revision))
        self._next_revision = revision
        return Fine(revision)
    }

    # 删除：键缺席是 `Fine(false)` 空操作，不记日志、不消耗 revision。
    micro delete(mut self, table: [u8], key: [u8]) -> Result<bool, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        if !database_engine_table_exists(self, table) {
            return Fail(DatabaseFault { code: database_fault_table_missing() })
        }
        let slot: DatabaseSlot = database_engine_slot(self._rows, table, key)
        if database_slot_is_absent(slot) {
            return Fine(false)
        }
        let revision: i64 = self._next_revision + 1
        database_engine_journal(self, database_journal_op_delete(), table, key, [], revision)
        self._rows = database_engine_rows_remove(self._rows, database_slot_index(slot))
        self._next_revision = revision
        return Fine(true)
    }
}

# 二分定位结果：键所在下标，或缺失时的有序插入位置（均为 0 基）。
unite DatabaseSlot {
    [constructor]
    Found {
        index: i64
    }
    [constructor]
    Absent {
        insert_at: i64
    }
}

micro database_slot_is_absent(slot: DatabaseSlot) -> bool {
    return match slot {
        case Found(payload): false
        case Absent(payload): true
    }
}

# 命中返回下标，缺失返回插入位置（调用方先以 `database_slot_is_absent` 区分）。
micro database_slot_index(slot: DatabaseSlot) -> i64 {
    return match slot {
        case Found(payload): payload.index
        case Absent(payload): payload.insert_at
    }
}

# 行存储二分定位：按（表空间, 键）字典序。
micro database_engine_slot(rows: [DatabaseRecord], table: [u8], key: [u8]) -> DatabaseSlot {
    let mut low: i64 = 0
    let mut high: i64 = rows.length() as i64
    while low < high {
        let middle: i64 = (low + high) / 2
        let row: DatabaseRecord = std::collection::array::get(rows, middle as usize)
        let order: i64 = database_compare_bytes(row.table, table)
        if order == 0 {
            let by_key: i64 = database_compare_bytes(row.key, key)
            if by_key == 0 {
                return Found { index: middle }
            }
            if by_key < 0 {
                low = middle + 1
            }
            else {
                high = middle
            }
        }
        if order < 0 {
            low = middle + 1
        }
        if order > 0 {
            high = middle
        }
    }
    return Absent { insert_at: low }
}

# 有序插入或替换（函数式重建，写回新数组）。
micro database_engine_rows_put(rows: [DatabaseRecord], record: DatabaseRecord) -> [DatabaseRecord] {
    let slot: DatabaseSlot = database_engine_slot(rows, record.table, record.key)
    let size: i64 = rows.length() as i64
    let mut rebuilt: [DatabaseRecord] = []
    let mut cursor: i64 = 0
    if database_slot_is_absent(slot) {
        let insert_at: i64 = database_slot_index(slot)
        while cursor < size {
            if cursor == insert_at {
                rebuilt = push(rebuilt, record)
            }
            rebuilt = push(rebuilt, std::collection::array::get(rows, cursor as usize))
            cursor = cursor + 1
        }
        if insert_at >= size {
            rebuilt = push(rebuilt, record)
        }
        return rebuilt
    }
    let replace_at: i64 = database_slot_index(slot)
    while cursor < size {
        if cursor == replace_at {
            rebuilt = push(rebuilt, record)
        }
        else {
            rebuilt = push(rebuilt, std::collection::array::get(rows, cursor as usize))
        }
        cursor = cursor + 1
    }
    return rebuilt
}

micro database_engine_rows_remove(rows: [DatabaseRecord], index: i64) -> [DatabaseRecord] {
    let mut rebuilt: [DatabaseRecord] = []
    let size: i64 = rows.length() as i64
    let mut cursor: i64 = 0
    while cursor < size {
        if cursor != index {
            rebuilt = push(rebuilt, std::collection::array::get(rows, cursor as usize))
        }
        cursor = cursor + 1
    }
    return rebuilt
}
