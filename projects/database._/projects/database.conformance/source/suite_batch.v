namespace database.conformance;

# C5 批量：暂存不可见、原子提交、校验失败整体不生效、空批量幂等、封口纪律。
micro conformance_c05_write_batch(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    let created: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if !database::database_outcome_is_fine(created) {
        return 1
    }
    let seeded: Result<i64, database::DatabaseFault> = engine.put([1], [1], [10])
    if !database::database_outcome_is_fine(seeded) {
        return 2
    }
    let mut batch: database::WriteBatch = database::database_batch(engine)
    if !batch.is_empty() {
        return 3
    }
    let mut staged: Result<bool, database::DatabaseFault> = batch.put([1], [2], [20])
    if !database::database_outcome_is_fine(staged) {
        return 4
    }
    staged = batch.put([1], [3], [30])
    staged = batch.delete([1], [1])
    if batch.count() != 3 {
        return 5
    }
    let before_commit: Option<[u8]> = database::database_outcome_must(engine.get([1], [2]))
    if before_commit.is_some() {
        return 6
    }
    let revision_before: i64 = engine.revision()
    let committed: Result<i64, database::DatabaseFault> = database::database_batch_commit(engine, batch)
    let final_revision: i64 = database::database_outcome_must(committed)
    if final_revision != revision_before + 3 {
        return 7
    }
    if engine.revision() != revision_before + 3 {
        return 8
    }
    let second: Option<[u8]> = database::database_outcome_must(engine.get([1], [2]))
    if !database::database_bytes_equal(second.unwrap(), [20]) {
        return 9
    }
    let removed: Option<[u8]> = database::database_outcome_must(engine.get([1], [1]))
    if removed.is_some() {
        return 10
    }
    let reuse: Result<bool, database::DatabaseFault> = batch.put([1], [4], [40])
    if database::database_outcome_fault_code(reuse) != database::database_fault_batch_sealed() {
        return 11
    }
    let recommit: Result<i64, database::DatabaseFault> = database::database_batch_commit(engine, batch)
    if database::database_outcome_fault_code(recommit) != database::database_fault_batch_sealed() {
        return 12
    }
    let mut empty_batch: database::WriteBatch = database::database_batch(engine)
    let empty_commit: Result<i64, database::DatabaseFault> = database::database_batch_commit(engine, empty_batch)
    let empty_result: i64 = database::database_outcome_must(empty_commit)
    let revision_after_empty: i64 = engine.revision()
    if empty_result != revision_after_empty {
        return 13
    }
    let mut broken: database::WriteBatch = database::database_batch(engine)
    let mut stage: Result<bool, database::DatabaseFault> = broken.put([1], [7], [70])
    stage = broken.put([9], [1], [1])
    let failed: Result<i64, database::DatabaseFault> = database::database_batch_commit(engine, broken)
    if database::database_outcome_fault_code(failed) != database::database_fault_table_missing() {
        return 14
    }
    let not_applied: Option<[u8]> = database::database_outcome_must(engine.get([1], [7]))
    if not_applied.is_some() {
        return 15
    }
    if engine.revision() != revision_before + 3 {
        return 16
    }
    let mut discarded: database::WriteBatch = database::database_batch(engine)
    let mut staged_discard: Result<bool, database::DatabaseFault> = discarded.put([1], [8], [80])
    discarded.discard()
    let after_discard: Result<bool, database::DatabaseFault> = discarded.put([1], [8], [80])
    if database::database_outcome_fault_code(after_discard) != database::database_fault_batch_sealed() {
        return 17
    }
    let discarded_invisible: Option<[u8]> = database::database_outcome_must(engine.get([1], [8]))
    if discarded_invisible.is_some() {
        return 18
    }
    engine.close()
    let mut closed_batch: database::WriteBatch = database::database_batch(engine)
    let closed_stage: Result<bool, database::DatabaseFault> = closed_batch.put([1], [1], [1])
    let closed_commit: Result<i64, database::DatabaseFault> = database::database_batch_commit(engine, closed_batch)
    if database::database_outcome_fault_code(closed_commit) != database::database_fault_engine_closed() {
        return 19
    }
    return 0
}
