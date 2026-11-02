namespace yyds.kv;

[test]
micro put_then_get_returns_latest_record() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let outcome: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1, 2]), kv_inline([9, 8]))
    if outcome.revision != 1 {
        panic("first put should consume revision 1")
    }
    if kv_memory_length(outcome.shard) != 1 {
        panic("shard should hold one record")
    }
    let found: Option<KvRecord> = kv_memory_get(outcome.shard, kv_key("n", [1, 2]))
    if found.is_none() {
        panic("stored key should be found")
    }
    let record: KvRecord = found.unwrap()
    if record.revision != 1 {
        panic("record should carry revision 1")
    }
    if kv_stored_value_is_object(record.value) {
        panic("value should stay inline")
    }
    let bytes: [u8] = kv_stored_value_inline_bytes(record.value).unwrap()
    if !kv_bytes_equal(bytes, [9, 8]) {
        panic("inline bytes should roundtrip")
    }
    if kv_memory_get(outcome.shard, kv_key("n", [1, 3])).is_some() {
        panic("absent key should not be found")
    }
}

[test]
micro put_replace_bumps_revision_and_keeps_length() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let first: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1]), kv_inline([1]))
    let second: KvPutOutcome = kv_memory_put(first.shard, kv_key("n", [1]), kv_inline([2]))
    if second.revision != 2 {
        panic("replace should consume a new revision")
    }
    if kv_memory_length(second.shard) != 1 {
        panic("replace should not duplicate the key")
    }
    let record: KvRecord = kv_memory_get(second.shard, kv_key("n", [1])).unwrap()
    if record.revision != 2 {
        panic("stored record should carry the newer revision")
    }
    let bytes: [u8] = kv_stored_value_inline_bytes(record.value).unwrap()
    if !kv_bytes_equal(bytes, [2]) {
        panic("replace should store the newer value")
    }
    if kv_memory_length(first.shard) != 1 {
        panic("functional put must not mutate the source shard length")
    }
    let original: KvRecord = kv_memory_get(first.shard, kv_key("n", [1])).unwrap()
    if original.revision != 1 {
        panic("functional put must not mutate the source shard contents")
    }
}

[test]
micro delete_reports_removed_and_hides_record() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let stored: KvPutOutcome = kv_memory_put(empty, kv_key("n", [7]), kv_inline([7]))
    let removed: KvDeleteOutcome = kv_memory_delete(stored.shard, kv_key("n", [7]))
    if !removed.removed {
        panic("delete should report removal of an existing key")
    }
    if kv_memory_length(removed.shard) != 0 {
        panic("delete should shrink the shard")
    }
    if kv_memory_get(removed.shard, kv_key("n", [7])).is_some() {
        panic("deleted key should stay hidden")
    }
    if kv_memory_revision(removed.shard) != 1 {
        panic("delete must not consume a revision")
    }
}

[test]
micro delete_absent_key_reports_not_removed() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let outcome: KvDeleteOutcome = kv_memory_delete(empty, kv_key("n", [7]))
    if outcome.removed {
        panic("delete of an absent key must report not removed")
    }
    if kv_memory_length(outcome.shard) != 0 {
        panic("delete of an absent key must leave the shard unchanged")
    }
}

[test]
micro records_stay_locatable_after_out_of_order_inserts() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let step1: KvPutOutcome = kv_memory_put(empty, kv_key("n", [3]), kv_inline([3]))
    let step2: KvPutOutcome = kv_memory_put(step1.shard, kv_key("n", [1]), kv_inline([1]))
    let step3: KvPutOutcome = kv_memory_put(step2.shard, kv_key("n", [2]), kv_inline([2]))
    if kv_memory_length(step3.shard) != 3 {
        panic("three distinct keys should coexist")
    }
    if kv_memory_get(step3.shard, kv_key("n", [1])).is_none() {
        panic("key [1] should be locatable")
    }
    if kv_memory_get(step3.shard, kv_key("n", [2])).is_none() {
        panic("key [2] should be locatable")
    }
    if kv_memory_get(step3.shard, kv_key("n", [3])).is_none() {
        panic("key [3] should be locatable")
    }
}
