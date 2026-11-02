namespace database;

# Snapshot — 引擎只读冻结视图。
#
# 值语义拷贝：快照在创建时刻与引擎脱钩，之后引擎的写入/崩溃/恢复都不影响快照。
# 快照不提供写路径；游标可直接开在快照上（与开在引擎上语义一致）。
structure DatabaseSnapshot {
    backend: i64
    rows: [DatabaseRecord]
    tables: [[u8]]
    revision: i64
}

# 冻结当前引擎；引擎未声明快照能力即 `capability_missing`。
micro database_snapshot(engine: DatabaseEngine) -> Result<DatabaseSnapshot, DatabaseFault> {
    if !engine.is_open() {
        return Fail(DatabaseFault { code: database_fault_engine_closed() })
    }
    if !engine._cap_snapshots {
        return Fail(DatabaseFault { code: database_fault_capability_missing() })
    }
    return Fine(DatabaseSnapshot {
        backend: engine._backend,
        rows: engine._rows,
        tables: engine._tables,
        revision: engine._next_revision
    })
}

micro database_snapshot_revision(snapshot: DatabaseSnapshot) -> i64 {
    return snapshot.revision
}

micro database_snapshot_record_count(snapshot: DatabaseSnapshot) -> i64 {
    return snapshot.rows.length() as i64
}

# 点查快照；表未注册（快照口径）即 `table_missing`，键缺席走 `None`。
micro database_snapshot_get(snapshot: DatabaseSnapshot, table: [u8], key: [u8]) -> Result<Option<[u8]>, DatabaseFault> {
    if !database_catalog_tables_have(snapshot.tables, table) {
        return Fail(DatabaseFault { code: database_fault_table_missing() })
    }
    let slot: DatabaseSlot = database_engine_slot(snapshot.rows, table, key)
    if database_slot_is_absent(slot) {
        let missing: Option<[u8]> = None
        return Fine(missing)
    }
    let row: DatabaseRecord = std::collection::array::get(snapshot.rows, database_slot_index(slot) as usize)
    return Fine(Some(row.value))
}

# 快照上的全表正向游标。
micro database_snapshot_cursor(snapshot: DatabaseSnapshot, table: [u8]) -> Result<DatabaseCursor, DatabaseFault> {
    return database_cursor_build(snapshot.rows, snapshot.tables, table, [], false, false)
}

# 快照上的前缀正向游标。
micro database_snapshot_cursor_prefix(snapshot: DatabaseSnapshot, table: [u8], prefix: [u8]) -> Result<DatabaseCursor, DatabaseFault> {
    return database_cursor_build(snapshot.rows, snapshot.tables, table, prefix, true, false)
}
