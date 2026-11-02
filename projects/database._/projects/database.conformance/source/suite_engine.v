namespace database.conformance;

# C1 引擎开/关与能力面：打开可读能力、关闭后全操作硬失败、未知后端 fail-closed。
micro conformance_c01_engine_open_close(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let opened: Result<database::DatabaseEngine, database::DatabaseFault> = open()
    if !database::database_outcome_is_fine(opened) {
        return 1
    }
    let mut engine: database::DatabaseEngine = database::database_outcome_must(opened)
    if !engine.is_open() {
        return 2
    }
    let backend: i64 = engine.backend()
    if backend <= 0 {
        return 3
    }
    let revision: i64 = engine.revision()
    if revision != 0 {
        return 4
    }
    let records: i64 = engine.record_count()
    if records != 0 {
        return 5
    }
    let missing_table_put: Result<i64, database::DatabaseFault> = engine.put([9], [1], [1])
    let missing_table_code: i64 = database::database_outcome_fault_code(missing_table_put)
    if missing_table_code != database::database_fault_table_missing() {
        return 6
    }
    let created: Result<i64, database::DatabaseFault> = engine.create_table([9])
    if !database::database_outcome_is_fine(created) {
        return 7
    }
    engine.close()
    if engine.is_open() {
        return 8
    }
    let closed_get: Result<Option<[u8]>, database::DatabaseFault> = engine.get([9], [1])
    if database::database_outcome_fault_code(closed_get) != database::database_fault_engine_closed() {
        return 9
    }
    let closed_put: Result<i64, database::DatabaseFault> = engine.put([9], [1], [1])
    if database::database_outcome_fault_code(closed_put) != database::database_fault_engine_closed() {
        return 10
    }
    let closed_create: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if database::database_outcome_fault_code(closed_create) != database::database_fault_engine_closed() {
        return 11
    }
    let closed_flush: Result<i64, database::DatabaseFault> = engine.flush(false)
    if database::database_outcome_fault_code(closed_flush) != database::database_fault_engine_closed() {
        return 12
    }
    let closed_checkpoint: Result<i64, database::DatabaseFault> = engine.checkpoint()
    if database::database_outcome_fault_code(closed_checkpoint) != database::database_fault_engine_closed() {
        return 13
    }
    engine.close()
    let unknown: Result<database::DatabaseEngine, database::DatabaseFault> = database::DatabaseEngine::open(database::database_open_options(999))
    if database::database_outcome_fault_code(unknown) != database::database_fault_backend_unavailable() {
        return 14
    }
    return 0
}

# C2 Catalog：建表/重名/空名/删表/册 revision 单调/删后引用全失败。
micro conformance_c02_catalog(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    let first: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if database::database_outcome_must(first) != 1 {
        return 1
    }
    if !engine.table_exists([1]) {
        return 2
    }
    if engine.table_count() != 1 {
        return 3
    }
    let tables: [[u8]] = engine.list_tables()
    let table_total: i64 = tables.length() as i64
    if table_total != 1 {
        return 4
    }
    if !database::database_bytes_equal(std::collection::array::get(tables, 0), [1]) {
        return 5
    }
    let duplicate: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if database::database_outcome_fault_code(duplicate) != database::database_fault_table_exists() {
        return 6
    }
    let invalid: Result<i64, database::DatabaseFault> = engine.create_table([])
    if database::database_outcome_fault_code(invalid) != database::database_fault_table_invalid() {
        return 7
    }
    let second: Result<i64, database::DatabaseFault> = engine.create_table([2])
    if database::database_outcome_must(second) != 2 {
        return 8
    }
    if engine.catalog_revision() != 2 {
        return 9
    }
    let dropped: Result<i64, database::DatabaseFault> = engine.drop_table([1])
    if database::database_outcome_must(dropped) != 3 {
        return 10
    }
    if engine.table_exists([1]) {
        return 11
    }
    let drop_again: Result<i64, database::DatabaseFault> = engine.drop_table([1])
    if database::database_outcome_fault_code(drop_again) != database::database_fault_table_missing() {
        return 12
    }
    let get_missing: Result<Option<[u8]>, database::DatabaseFault> = engine.get([1], [1])
    if database::database_outcome_fault_code(get_missing) != database::database_fault_table_missing() {
        return 13
    }
    let put_missing: Result<i64, database::DatabaseFault> = engine.put([1], [1], [1])
    if database::database_outcome_fault_code(put_missing) != database::database_fault_table_missing() {
        return 14
    }
    let delete_missing: Result<bool, database::DatabaseFault> = engine.delete([1], [1])
    if database::database_outcome_fault_code(delete_missing) != database::database_fault_table_missing() {
        return 15
    }
    let cursor_missing: Result<database::DatabaseCursor, database::DatabaseFault> = engine.cursor([1])
    if database::database_outcome_fault_code(cursor_missing) != database::database_fault_table_missing() {
        return 16
    }
    let records_missing: Result<i64, database::DatabaseFault> = engine.table_records([1])
    if database::database_outcome_fault_code(records_missing) != database::database_fault_table_missing() {
        return 17
    }
    return 0
}

# C3 读写路径：写读回、替换递增 revision、删除语义、缺席删除不消耗 revision、二进制键。
micro conformance_c03_read_write(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    let created: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if !database::database_outcome_is_fine(created) {
        return 1
    }
    let first: Result<i64, database::DatabaseFault> = engine.put([1], [10], [100])
    if database::database_outcome_must(first) != 1 {
        return 2
    }
    let got: Result<Option<[u8]>, database::DatabaseFault> = engine.get([1], [10])
    let present: Option<[u8]> = database::database_outcome_must(got)
    if present.is_none() {
        return 3
    }
    if !database::database_bytes_equal(present.unwrap(), [100]) {
        return 4
    }
    let replaced: Result<i64, database::DatabaseFault> = engine.put([1], [10], [101])
    if database::database_outcome_must(replaced) != 2 {
        return 5
    }
    let regot: Option<[u8]> = database::database_outcome_must(engine.get([1], [10]))
    if !database::database_bytes_equal(regot.unwrap(), [101]) {
        return 6
    }
    let second: Result<i64, database::DatabaseFault> = engine.put([1], [20], [200])
    if database::database_outcome_must(second) != 3 {
        return 7
    }
    let removed: Result<bool, database::DatabaseFault> = engine.delete([1], [10])
    if !database::database_outcome_must(removed) {
        return 8
    }
    let after_delete: Option<[u8]> = database::database_outcome_must(engine.get([1], [10]))
    if after_delete.is_some() {
        return 9
    }
    let remove_absent: Result<bool, database::DatabaseFault> = engine.delete([1], [10])
    if database::database_outcome_must(remove_absent) {
        return 10
    }
    if engine.revision() != 3 {
        return 11
    }
    let binary_key: Result<i64, database::DatabaseFault> = engine.put([1], [0, 255, 0, 1], [9])
    if !database::database_outcome_is_fine(binary_key) {
        return 12
    }
    let binary_got: Option<[u8]> = database::database_outcome_must(engine.get([1], [0, 255, 0, 1]))
    if !database::database_bytes_equal(binary_got.unwrap(), [9]) {
        return 13
    }
    let empty_value: Result<i64, database::DatabaseFault> = engine.put([1], [30], [])
    if !database::database_outcome_is_fine(empty_value) {
        return 14
    }
    let empty_got: Option<[u8]> = database::database_outcome_must(engine.get([1], [30]))
    if empty_got.is_none() {
        return 15
    }
    let empty_size: i64 = empty_got.unwrap().length() as i64
    if empty_size != 0 {
        return 16
    }
    return 0
}
