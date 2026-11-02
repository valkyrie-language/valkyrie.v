namespace database.conformance;

# C9 有序键编码：i64 往返与保序、字节串转义与前缀性质、复合键、损坏拒绝、值编码。
# 本组不依赖引擎实例，工厂参数仅为与其他组同形。
micro conformance_c09_key_encoding(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let zero: i64 = database::database_outcome_must(database::database_decode_i64(database::database_encode_i64(0)))
    if zero != 0 {
        return 1
    }
    let one: i64 = database::database_outcome_must(database::database_decode_i64(database::database_encode_i64(1)))
    if one != 1 {
        return 2
    }
    let negative_one: i64 = database::database_outcome_must(database::database_decode_i64(database::database_encode_i64(-1)))
    if negative_one != -1 {
        return 3
    }
    let large: i64 = database::database_outcome_must(database::database_decode_i64(database::database_encode_i64(1000000)))
    if large != 1000000 {
        return 4
    }
    let large_negative: i64 = database::database_outcome_must(database::database_decode_i64(database::database_encode_i64(-1000000)))
    if large_negative != -1000000 {
        return 5
    }
    let huge_negative: i64 = database::database_outcome_must(database::database_decode_i64(database::database_encode_i64(-1000000000000)))
    if huge_negative != -1000000000000 {
        return 6
    }
    let encode_negatives: i64 = database::database_compare_bytes(database::database_encode_i64(-100), database::database_encode_i64(-1))
    if encode_negatives >= 0 {
        return 7
    }
    let negative_below_zero: i64 = database::database_compare_bytes(database::database_encode_i64(-1), database::database_encode_i64(0))
    if negative_below_zero >= 0 {
        return 8
    }
    let zero_below_positive: i64 = database::database_compare_bytes(database::database_encode_i64(0), database::database_encode_i64(1))
    if zero_below_positive >= 0 {
        return 9
    }
    let positives_ordered: i64 = database::database_compare_bytes(database::database_encode_i64(1), database::database_encode_i64(100))
    if positives_ordered >= 0 {
        return 10
    }
    let tag: u8 = std::collection::array::get(database::database_encode_i64(0), 0)
    if tag as i64 != database::database_kind_i64() {
        return 11
    }
    let prefix_property: i64 = database::database_compare_bytes(database::database_encode_bytes([1, 2]), database::database_encode_bytes([1, 2, 3]))
    if prefix_property >= 0 {
        return 12
    }
    let bytes_ordered: i64 = database::database_compare_bytes(database::database_encode_bytes([1, 2]), database::database_encode_bytes([1, 3]))
    if bytes_ordered >= 0 {
        return 13
    }
    let escaped: [u8] = database::database_encode_bytes([0])
    let escaped_size: i64 = escaped.length() as i64
    if escaped_size != 4 {
        return 14
    }
    if std::collection::array::get(escaped, 1) != 0 || std::collection::array::get(escaped, 2) != 1 {
        return 15
    }
    let escape_order: i64 = database::database_compare_bytes(database::database_encode_bytes([1, 0, 2]), database::database_encode_bytes([1, 1]))
    if escape_order >= 0 {
        return 16
    }
    let composite_same_head: i64 = database::database_compare_bytes(
        database::database_encode_composite([database::database_encode_i64(1), database::database_encode_bytes([1])]),
        database::database_encode_composite([database::database_encode_i64(1), database::database_encode_bytes([2])]))
    if composite_same_head >= 0 {
        return 17
    }
    let composite_next_head: i64 = database::database_compare_bytes(
        database::database_encode_composite([database::database_encode_i64(1), database::database_encode_bytes([9])]),
        database::database_encode_composite([database::database_encode_i64(2), database::database_encode_bytes([1])]))
    if composite_next_head >= 0 {
        return 18
    }
    let short_decode: Result<i64, database::DatabaseFault> = database::database_decode_i64([2])
    if database::database_outcome_fault_code(short_decode) != database::database_fault_corrupt_encoding() {
        return 19
    }
    let wrong_tag: Result<i64, database::DatabaseFault> = database::database_decode_i64([1, 0, 0, 0, 0, 0, 0, 0, 0])
    if database::database_outcome_fault_code(wrong_tag) != database::database_fault_corrupt_encoding() {
        return 20
    }
    let value_i64: [u8] = database::database_value_encode_i64(42)
    let value_kind: i64 = database::database_outcome_must(database::database_value_kind(value_i64))
    if value_kind != database::database_kind_i64() {
        return 21
    }
    let value_roundtrip: i64 = database::database_outcome_must(database::database_value_decode_i64(value_i64))
    if value_roundtrip != 42 {
        return 22
    }
    let value_text: [u8] = database::database_value_encode_text([65, 66])
    let text_kind: i64 = database::database_outcome_must(database::database_value_kind(value_text))
    if text_kind != database::database_kind_text() {
        return 23
    }
    let text_payload: [u8] = database::database_outcome_must(database::database_value_payload(value_text))
    if !database::database_bytes_equal(text_payload, [65, 66]) {
        return 24
    }
    let mismatched: Result<i64, database::DatabaseFault> = database::database_value_decode_i64(value_text)
    if database::database_outcome_fault_code(mismatched) != database::database_fault_corrupt_encoding() {
        return 25
    }
    let empty_kind: Result<i64, database::DatabaseFault> = database::database_value_kind([])
    if database::database_outcome_fault_code(empty_kind) != database::database_fault_corrupt_encoding() {
        return 26
    }
    let ignore_factory: Result<database::DatabaseEngine, database::DatabaseFault> = open()
    if !database::database_outcome_is_fine(ignore_factory) {
        return 27
    }
    return 0
}

# C10 观测：尺寸估算口径、记录计数、表单表计数、flush 计数。
micro conformance_c10_statistics(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    if engine.estimate_size() != 0 {
        return 1
    }
    if engine.record_count() != 0 {
        return 2
    }
    let created: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if !database::database_outcome_is_fine(created) {
        return 3
    }
    let empty_table: i64 = database::database_outcome_must(engine.table_records([1]))
    if empty_table != 0 {
        return 4
    }
    let seeded: Result<i64, database::DatabaseFault> = engine.put([1], [5], [1, 2])
    if !database::database_outcome_is_fine(seeded) {
        return 5
    }
    let estimated: i64 = engine.estimate_size()
    let expected: i64 = 1 + 2 + database::database_stats_record_overhead()
    if estimated != expected {
        return 6
    }
    if engine.record_count() != 1 {
        return 7
    }
    let one_table: i64 = database::database_outcome_must(engine.table_records([1]))
    if one_table != 1 {
        return 8
    }
    let missing: Result<i64, database::DatabaseFault> = engine.table_records([9])
    if database::database_outcome_fault_code(missing) != database::database_fault_table_missing() {
        return 9
    }
    if engine.flush_calls() != 0 {
        return 10
    }
    let flushed: Result<i64, database::DatabaseFault> = engine.flush(false)
    if !database::database_outcome_is_fine(flushed) {
        return 11
    }
    if engine.flush_calls() != 1 {
        return 12
    }
    return 0
}
