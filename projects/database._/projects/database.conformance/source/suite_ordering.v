namespace database.conformance;

# C13 值全序：类型码序 + 同类型内载荷序；损坏形态结构化拒绝。
micro conformance_c13_value_ordering(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let null_a: [u8] = database::database_value_encode_null()
    let null_b: [u8] = database::database_value_encode_null()
    let null_equal: i64 = database::database_outcome_must(database::database_compare_values(null_a, null_b))
    if null_equal != 0 {
        return 1
    }
    let null_below_bytes: i64 = database::database_outcome_must(database::database_compare_values(null_a, database::database_value_encode_bytes([1])))
    if null_below_bytes >= 0 {
        return 2
    }
    let bytes_below_i64: i64 = database::database_outcome_must(database::database_compare_values(database::database_value_encode_bytes([255]), database::database_value_encode_i64(-9999999)))
    if bytes_below_i64 >= 0 {
        return 3
    }
    let i64_below_text: i64 = database::database_outcome_must(database::database_compare_values(database::database_value_encode_i64(9999999), database::database_value_encode_text([65])))
    if i64_below_text >= 0 {
        return 4
    }
    let text_below_bool: i64 = database::database_outcome_must(database::database_compare_values(database::database_value_encode_text([255]), database::database_value_encode_bool(false)))
    if text_below_bool >= 0 {
        return 5
    }
    let i64_inner_order: i64 = database::database_outcome_must(database::database_compare_values(database::database_value_encode_i64(-5), database::database_value_encode_i64(3)))
    if i64_inner_order >= 0 {
        return 6
    }
    let bytes_inner_order: i64 = database::database_outcome_must(database::database_compare_values(database::database_value_encode_bytes([1]), database::database_value_encode_bytes([1, 0])))
    if bytes_inner_order >= 0 {
        return 7
    }
    let bool_inner_order: i64 = database::database_outcome_must(database::database_compare_values(database::database_value_encode_bool(false), database::database_value_encode_bool(true)))
    if bool_inner_order >= 0 {
        return 8
    }
    let unknown_tag: Result<i64, database::DatabaseFault> = database::database_compare_values([99, 0], null_a)
    if database::database_outcome_fault_code(unknown_tag) != database::database_fault_corrupt_encoding() {
        return 9
    }
    let malformed_i64: Result<i64, database::DatabaseFault> = database::database_compare_values(database::database_value_encode_i64(1), [2, 1])
    if database::database_outcome_fault_code(malformed_i64) != database::database_fault_corrupt_encoding() {
        return 10
    }
    let malformed_bool: Result<i64, database::DatabaseFault> = database::database_compare_values([5, 7], [5, 0])
    if database::database_outcome_fault_code(malformed_bool) != database::database_fault_corrupt_encoding() {
        return 11
    }
    let bool_roundtrip: bool = database::database_outcome_must(database::database_value_decode_bool(database::database_value_encode_bool(true)))
    if !bool_roundtrip {
        return 12
    }
    let bool_mismatch: Result<bool, database::DatabaseFault> = database::database_value_decode_bool(database::database_value_encode_i64(1))
    if database::database_outcome_fault_code(bool_mismatch) != database::database_fault_corrupt_encoding() {
        return 13
    }
    let ignore_factory: Result<database::DatabaseEngine, database::DatabaseFault> = open()
    if !database::database_outcome_is_fine(ignore_factory) {
        return 14
    }
    return 0
}

# C14 错误模型：硬失败带与可恢复带的判定边界；合同误用属硬失败。
micro conformance_c14_fault_model(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    let missing: Result<Option<[u8]>, database::DatabaseFault> = engine.get([9], [1])
    let code: i64 = database::database_outcome_fault_code(missing)
    if code != database::database_fault_table_missing() {
        return 1
    }
    if database::database_fault_is_recoverable(code) {
        return 2
    }
    if database::database_fault_is_recoverable(database::database_fault_engine_closed()) {
        return 3
    }
    if database::database_fault_is_recoverable(database::database_fault_transaction_conflict()) {
        return 4
    }
    if database::database_fault_is_recoverable(database::database_fault_corrupt_encoding()) {
        return 5
    }
    if !database::database_fault_is_recoverable(database::database_fault_engine_busy()) {
        return 6
    }
    if !database::database_fault_is_recoverable(database::database_fault_snapshot_expired()) {
        return 7
    }
    let fine_outcome: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if database::database_outcome_fault_code(fine_outcome) != 0 {
        return 8
    }
    return 0
}
