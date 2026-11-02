namespace database.conformance;

# C6 事务：读己之写、快照隔离、乐观冲突、回滚、关闭纪律、隔离级别登记。
micro conformance_c06_transaction(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    let created: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if !database::database_outcome_is_fine(created) {
        return 1
    }
    let seeded: Result<i64, database::DatabaseFault> = engine.put([1], [1], [10])
    if !database::database_outcome_is_fine(seeded) {
        return 2
    }
    let mut tx: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    let base_read: Option<[u8]> = database::database_outcome_must(tx.get([1], [1]))
    if !database::database_bytes_equal(base_read.unwrap(), [10]) {
        return 3
    }
    let mut staged: Result<bool, database::DatabaseFault> = tx.put([1], [1], [11])
    staged = tx.put([1], [2], [20])
    let own_write: Option<[u8]> = database::database_outcome_must(tx.get([1], [1]))
    if !database::database_bytes_equal(own_write.unwrap(), [11]) {
        return 4
    }
    let committed: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, tx)
    if !database::database_outcome_is_fine(committed) {
        return 5
    }
    let visible: Option<[u8]> = database::database_outcome_must(engine.get([1], [1]))
    if !database::database_bytes_equal(visible.unwrap(), [11]) {
        return 6
    }
    let after_commit_get: Result<Option<[u8]>, database::DatabaseFault> = tx.get([1], [1])
    if database::database_outcome_fault_code(after_commit_get) != database::database_fault_transaction_closed() {
        return 7
    }
    let mut snapshot_tx: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    let before_direct: Option<[u8]> = database::database_outcome_must(snapshot_tx.get([1], [1]))
    if !database::database_bytes_equal(before_direct.unwrap(), [11]) {
        return 8
    }
    let direct: Result<i64, database::DatabaseFault> = engine.put([1], [1], [12])
    if !database::database_outcome_is_fine(direct) {
        return 9
    }
    let repeatable: Option<[u8]> = database::database_outcome_must(snapshot_tx.get([1], [1]))
    if !database::database_bytes_equal(repeatable.unwrap(), [11]) {
        return 10
    }
    let conflict_stage: Result<bool, database::DatabaseFault> = snapshot_tx.put([1], [1], [99])
    let conflicted: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, snapshot_tx)
    if database::database_outcome_fault_code(conflicted) != database::database_fault_transaction_conflict() {
        return 11
    }
    let engine_kept: Option<[u8]> = database::database_outcome_must(engine.get([1], [1]))
    if !database::database_bytes_equal(engine_kept.unwrap(), [12]) {
        return 12
    }
    snapshot_tx.rollback()
    let mut cas_tx: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_serializable()))
    let cas_stage: Result<bool, database::DatabaseFault> = cas_tx.put([1], [3], [30])
    let cas_commit: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, cas_tx)
    if !database::database_outcome_is_fine(cas_commit) {
        return 13
    }
    let cas_visible: Option<[u8]> = database::database_outcome_must(engine.get([1], [3]))
    if !database::database_bytes_equal(cas_visible.unwrap(), [30]) {
        return 14
    }
    let mut rollback_tx: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_read_committed()))
    let rollback_stage: Result<bool, database::DatabaseFault> = rollback_tx.put([1], [4], [40])
    rollback_tx.rollback()
    let rolled_back: Option<[u8]> = database::database_outcome_must(engine.get([1], [4]))
    if rolled_back.is_some() {
        return 15
    }
    let after_rollback_put: Result<bool, database::DatabaseFault> = rollback_tx.put([1], [4], [40])
    if database::database_outcome_fault_code(after_rollback_put) != database::database_fault_transaction_closed() {
        return 16
    }
    let invalid_low: Result<database::Transaction, database::DatabaseFault> = database::database_tx_begin(engine, 0)
    if database::database_outcome_fault_code(invalid_low) != database::database_fault_invalid_argument() {
        return 17
    }
    let invalid_high: Result<database::Transaction, database::DatabaseFault> = database::database_tx_begin(engine, 99)
    if database::database_outcome_fault_code(invalid_high) != database::database_fault_invalid_argument() {
        return 18
    }
    let mut delete_tx: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    let delete_stage: Result<bool, database::DatabaseFault> = delete_tx.delete([1], [1])
    let deleted_read: Option<[u8]> = database::database_outcome_must(delete_tx.get([1], [1]))
    if deleted_read.is_some() {
        return 19
    }
    let delete_commit: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, delete_tx)
    if !database::database_outcome_is_fine(delete_commit) {
        return 20
    }
    let deleted_visible: Option<[u8]> = database::database_outcome_must(engine.get([1], [1]))
    if deleted_visible.is_some() {
        return 21
    }
    return 0
}

# C7 快照：创建即冻结、后续写入不可见、缺失语义、快照游标、引擎关闭后仍可读。
micro conformance_c07_snapshot(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    let created: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if !database::database_outcome_is_fine(created) {
        return 1
    }
    let seeded: Result<i64, database::DatabaseFault> = engine.put([1], [1], [10])
    if !database::database_outcome_is_fine(seeded) {
        return 2
    }
    let snapshot: database::DatabaseSnapshot = database::database_outcome_must(database::database_snapshot(engine))
    let frozen_revision: i64 = database::database_snapshot_revision(snapshot)
    let later: Result<i64, database::DatabaseFault> = engine.put([1], [1], [11])
    if !database::database_outcome_is_fine(later) {
        return 3
    }
    let added: Result<i64, database::DatabaseFault> = engine.put([1], [2], [20])
    if !database::database_outcome_is_fine(added) {
        return 4
    }
    let frozen_read: Result<Option<[u8]>, database::DatabaseFault> = database::database_snapshot_get(snapshot, [1], [1])
    let frozen: Option<[u8]> = database::database_outcome_must(frozen_read)
    if !database::database_bytes_equal(frozen.unwrap(), [10]) {
        return 5
    }
    let invisible: Option<[u8]> = database::database_outcome_must(database::database_snapshot_get(snapshot, [1], [2]))
    if invisible.is_some() {
        return 6
    }
    let frozen_count: i64 = database::database_snapshot_record_count(snapshot)
    if frozen_count != 1 {
        return 7
    }
    let missing_table: Result<Option<[u8]>, database::DatabaseFault> = database::database_snapshot_get(snapshot, [9], [1])
    if database::database_outcome_fault_code(missing_table) != database::database_fault_table_missing() {
        return 8
    }
    let mut cursor: database::DatabaseCursor = database::database_outcome_must(database::database_snapshot_cursor(snapshot, [1]))
    if !cursor.first() {
        return 9
    }
    if !database::database_bytes_equal(database::database_outcome_must(cursor.value()), [10]) {
        return 10
    }
    if cursor.next() {
        return 11
    }
    if frozen_revision != 1 {
        return 12
    }
    engine.close()
    let after_close: Option<[u8]> = database::database_outcome_must(database::database_snapshot_get(snapshot, [1], [1]))
    if !database::database_bytes_equal(after_close.unwrap(), [10]) {
        return 13
    }
    return 0
}
