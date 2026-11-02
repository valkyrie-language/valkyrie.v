namespace database.conformance;

# C8 日志与恢复：flush 边界、持久性拒绝、检查点折叠、崩溃丢未刷盘、重放恢复。
micro conformance_c08_journal_recovery(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    if engine.journal_length() != 0 {
        return 1
    }
    let created: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if !database::database_outcome_is_fine(created) {
        return 2
    }
    let first: Result<i64, database::DatabaseFault> = engine.put([1], [1], [10])
    if !database::database_outcome_is_fine(first) {
        return 3
    }
    if engine.journal_length() != 2 {
        return 4
    }
    if engine.journal_flushed() != 0 {
        return 5
    }
    let durable: Result<i64, database::DatabaseFault> = engine.flush(true)
    if database::database_outcome_fault_code(durable) != database::database_fault_durability_unsupported() {
        return 6
    }
    if engine.journal_flushed() != 0 {
        return 7
    }
    let flushed: Result<i64, database::DatabaseFault> = engine.flush(false)
    if database::database_outcome_must(flushed) != 2 {
        return 8
    }
    if engine.journal_flushed() != 2 {
        return 9
    }
    if engine.flush_calls() != 1 {
        return 10
    }
    let second: Result<i64, database::DatabaseFault> = engine.put([1], [2], [20])
    if !database::database_outcome_is_fine(second) {
        return 11
    }
    let mut crashed: database::DatabaseEngine = engine.simulate_crash()
    if crashed.is_open() {
        return 12
    }
    let closed_read: Result<Option<[u8]>, database::DatabaseFault> = crashed.get([1], [1])
    if database::database_outcome_fault_code(closed_read) != database::database_fault_engine_closed() {
        return 13
    }
    let replayed: Result<i64, database::DatabaseFault> = crashed.recover()
    if database::database_outcome_must(replayed) != 2 {
        return 14
    }
    if !crashed.is_open() {
        return 15
    }
    let recovered: Option<[u8]> = database::database_outcome_must(crashed.get([1], [1]))
    if !database::database_bytes_equal(recovered.unwrap(), [10]) {
        return 16
    }
    let lost: Option<[u8]> = database::database_outcome_must(crashed.get([1], [2]))
    if lost.is_some() {
        return 17
    }
    let replay_again: Result<i64, database::DatabaseFault> = crashed.recover()
    if database::database_outcome_must(replay_again) != 0 {
        return 18
    }
    let third: Result<i64, database::DatabaseFault> = crashed.put([1], [3], [30])
    if !database::database_outcome_is_fine(third) {
        return 19
    }
    let checkpointed: Result<i64, database::DatabaseFault> = crashed.checkpoint()
    let checkpoint_revision: i64 = database::database_outcome_must(checkpointed)
    if crashed.journal_length() != 0 {
        return 20
    }
    if crashed.checkpoint_revision() != checkpoint_revision {
        return 21
    }
    let fourth: Result<i64, database::DatabaseFault> = crashed.put([1], [4], [40])
    if !database::database_outcome_is_fine(fourth) {
        return 22
    }
    let mut crashed_again: database::DatabaseEngine = crashed.simulate_crash()
    let empty_replay: Result<i64, database::DatabaseFault> = crashed_again.recover()
    if database::database_outcome_must(empty_replay) != 0 {
        return 23
    }
    let checkpoint_kept: Option<[u8]> = database::database_outcome_must(crashed_again.get([1], [3]))
    if !database::database_bytes_equal(checkpoint_kept.unwrap(), [30]) {
        return 24
    }
    let unflushed_lost: Option<[u8]> = database::database_outcome_must(crashed_again.get([1], [4]))
    if unflushed_lost.is_some() {
        return 25
    }
    let fifth: Result<i64, database::DatabaseFault> = crashed_again.put([1], [5], [50])
    if !database::database_outcome_is_fine(fifth) {
        return 26
    }
    let flushed_again: Result<i64, database::DatabaseFault> = crashed_again.flush(false)
    if !database::database_outcome_is_fine(flushed_again) {
        return 27
    }
    let mut crashed_third: database::DatabaseEngine = crashed_again.simulate_crash()
    let final_replay: Result<i64, database::DatabaseFault> = crashed_third.recover()
    if database::database_outcome_must(final_replay) != 1 {
        return 28
    }
    let durable_read: Option<[u8]> = database::database_outcome_must(crashed_third.get([1], [5]))
    if !database::database_bytes_equal(durable_read.unwrap(), [50]) {
        return 29
    }
    return 0
}
