namespace database.conformance;

# C12 交错一致性（单线程模型）：交错事务的隔离与冲突判定。
micro conformance_c12_interleave_consistency(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    let created: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if !database::database_outcome_is_fine(created) {
        return 1
    }
    let seeded: Result<i64, database::DatabaseFault> = engine.put([1], [1], [10])
    if !database::database_outcome_is_fine(seeded) {
        return 2
    }
    let mut tx1: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    let mut tx2: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    let mut stage: Result<bool, database::DatabaseFault> = tx1.put([1], [2], [20])
    stage = tx2.put([1], [3], [30])
    let commit1: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, tx1)
    if !database::database_outcome_is_fine(commit1) {
        return 3
    }
    let commit2: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, tx2)
    if !database::database_outcome_is_fine(commit2) {
        return 4
    }
    let visible_a: Option<[u8]> = database::database_outcome_must(engine.get([1], [2]))
    if !database::database_bytes_equal(visible_a.unwrap(), [20]) {
        return 5
    }
    let visible_b: Option<[u8]> = database::database_outcome_must(engine.get([1], [3]))
    if !database::database_bytes_equal(visible_b.unwrap(), [30]) {
        return 6
    }
    let mut tx3: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    let mut tx4: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    stage = tx3.put([1], [1], [11])
    stage = tx4.put([1], [1], [12])
    let commit3: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, tx3)
    if !database::database_outcome_is_fine(commit3) {
        return 7
    }
    let commit4: Result<i64, database::DatabaseFault> = database::database_tx_commit(engine, tx4)
    if database::database_outcome_fault_code(commit4) != database::database_fault_transaction_conflict() {
        return 8
    }
    let kept: Option<[u8]> = database::database_outcome_must(engine.get([1], [1]))
    if !database::database_bytes_equal(kept.unwrap(), [11]) {
        return 9
    }
    let mut tx5: database::Transaction = database::database_outcome_must(database::database_tx_begin(engine, database::database_isolation_repeatable_read()))
    let mid_flight: Result<i64, database::DatabaseFault> = engine.put([1], [4], [40])
    if !database::database_outcome_is_fine(mid_flight) {
        return 10
    }
    let moved: Result<i64, database::DatabaseFault> = engine.put([1], [1], [99])
    if !database::database_outcome_is_fine(moved) {
        return 13
    }
    let isolated: Option<[u8]> = database::database_outcome_must(tx5.get([1], [4]))
    if isolated.is_some() {
        return 11
    }
    let still_old: Option<[u8]> = database::database_outcome_must(tx5.get([1], [1]))
    if !database::database_bytes_equal(still_old.unwrap(), [11]) {
        return 12
    }
    tx5.rollback()
    return 0
}
