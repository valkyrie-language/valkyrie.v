namespace database.conformance;

# C11 revision 单调：每种写入消耗且只消耗一次；空批量/缺席删除/冲突事务不消耗。
micro conformance_c11_revision_monotonicity(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    let created: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if !database::database_outcome_is_fine(created) {
        return 1
    }
    if engine.revision() != 1 {
        return 2
    }
    let first: Result<i64, database::DatabaseFault> = engine.put([1], [1], [1])
    if database::database_outcome_must(first) != 2 {
        return 3
    }
    let second: Result<i64, database::DatabaseFault> = engine.put([1], [2], [2])
    if database::database_outcome_must(second) != 3 {
        return 4
    }
    let removed: Result<bool, database::DatabaseFault> = engine.delete([1], [1])
    if !database::database_outcome_must(removed) {
        return 5
    }
    if engine.revision() != 4 {
        return 6
    }
    let absent_delete: Result<bool, database::DatabaseFault> = engine.delete([1], [9])
    if database::database_outcome_must(absent_delete) {
        return 7
    }
    if engine.revision() != 4 {
        return 8
    }
    let empty_batch: database::WriteBatch = database::database_batch(engine)
    let empty_commit: Result<i64, database::DatabaseFault> = database::database_batch_commit(engine, empty_batch)
    if !database::database_outcome_is_fine(empty_commit) {
        return 9
    }
    if engine.revision() != 4 {
        return 10
    }
    let mut batch: database::WriteBatch = database::database_batch(engine)
    let mut staged: Result<bool, database::DatabaseFault> = batch.put([1], [3], [3])
    staged = batch.put([1], [4], [4])
    let batch_commit: Result<i64, database::DatabaseFault> = database::database_batch_commit(engine, batch)
    if database::database_outcome_must(batch_commit) != 6 {
        return 11
    }
    let mut tx: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    let mut tx_stage: Result<bool, database::DatabaseFault> = tx.put([1], [5], [5])
    tx_stage = tx.put([1], [6], [6])
    let tx_commit: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, tx)
    if database::database_outcome_must(tx_commit) != 8 {
        return 12
    }
    let mut losing_tx: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    let losing_stage: Result<bool, database::DatabaseFault> = losing_tx.put([1], [3], [30])
    let direct: Result<i64, database::DatabaseFault> = engine.put([1], [3], [31])
    if !database::database_outcome_is_fine(direct) {
        return 13
    }
    let conflicted: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, losing_tx)
    if database::database_outcome_fault_code(conflicted) != database::database_fault_transaction_conflict() {
        return 14
    }
    if engine.revision() != 9 {
        return 15
    }
    let snapshot: database::DatabaseSnapshot = database::database_outcome_must(database::database_snapshot(engine))
    if database::database_snapshot_revision(snapshot) != 9 {
        return 16
    }
    return 0
}
