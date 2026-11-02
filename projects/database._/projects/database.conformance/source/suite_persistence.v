namespace database.conformance;

# C16 持久化与浮点 fail-closed：未落地的后端/能力一律结构化失败，不伪造。
micro conformance_c16_fail_closed(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let unknown_backend: Result<database::DatabaseEngine, database::DatabaseFault> = database::DatabaseEngine::open(database::database_open_options(999))
    if database::database_outcome_fault_code(unknown_backend) != database::database_fault_backend_unavailable() {
        return 1
    }
    let f64_key: Result<[u8], database::DatabaseFault> = database::database_encode_f64(1.5)
    if database::database_outcome_fault_code(f64_key) != database::database_fault_capability_missing() {
        return 2
    }
    let f64_value: Result<[u8], database::DatabaseFault> = database::database_value_encode_f64(0.5)
    if database::database_outcome_fault_code(f64_value) != database::database_fault_capability_missing() {
        return 3
    }
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    if engine.cap_durable() {
        return 4
    }
    let durable_flush: Result<i64, database::DatabaseFault> = engine.flush(true)
    if database::database_outcome_fault_code(durable_flush) != database::database_fault_durability_unsupported() {
        return 5
    }
    if engine.flush_calls() != 0 {
        return 6
    }
    return 0
}
