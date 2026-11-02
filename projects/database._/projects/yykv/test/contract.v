namespace yykv;

[test]
micro memory_shard_has_no_durable_atomic_commit() -> unit {
    let shard: KvMemoryShard = kv_memory_new()
    if kv_memory_durable_atomic_commit(shard) {
        panic("memory shard must not claim a durable atomic commit boundary")
    }
}

[test]
micro commit_changes_is_structurally_unsupported() -> unit {
    let shard: KvMemoryShard = kv_memory_new()
    let changes: [KvShardChange] = [
        Put {
            key: kv_key("n", [1]),
            value: kv_inline([1])
        }
    ]
    match kv_memory_commit_changes(shard, changes) {
        case Applied(payload):
            panic("memory shard must refuse the durable commit boundary")
        case Unsupported(payload):
            if payload.feature.length() == 0 {
                panic("unsupported outcome should carry a reason")
            }
    }
}

[test]
micro cas_conflicts_when_expecting_absent_but_present() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let stored: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1]), kv_inline([1]))
    match kv_memory_compare_and_put(stored.shard, kv_key("n", [1]), None, kv_inline([2])) {
        case Applied(payload):
            panic("expecting an absent key must conflict with an existing record")
        case Conflict(payload):
            if !kv_key_equals(payload.key, kv_key("n", [1])) {
                panic("conflict should echo the contested key")
            }
    }
}

[test]
micro cas_conflicts_on_revision_mismatch() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let stored: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1]), kv_inline([1]))
    match kv_memory_compare_and_put(stored.shard, kv_key("n", [1]), Some(2), kv_inline([2])) {
        case Applied(payload):
            panic("stale revision expectation must conflict")
        case Conflict(payload):
            if !kv_key_equals(payload.key, kv_key("n", [1])) {
                panic("conflict should echo the contested key")
            }
    }
}

[test]
micro cas_applies_when_revision_matches() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let stored: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1]), kv_inline([1]))
    match kv_memory_compare_and_put(stored.shard, kv_key("n", [1]), Some(1), kv_inline([2])) {
        case Applied(payload):
            if payload.revision != 2 {
                panic("successful cas should consume a new revision")
            }
            let record: KvRecord = kv_memory_get(payload.shard, kv_key("n", [1])).unwrap()
            let bytes: [u8] = kv_stored_value_inline_bytes(record.value).unwrap()
            if !kv_bytes_equal(bytes, [2]) {
                panic("successful cas should store the new value")
            }
        case Conflict(payload):
            panic("matching revision must not conflict")
    }
}

[test]
micro cas_applies_when_key_absent() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    match kv_memory_compare_and_put(empty, kv_key("n", [1]), None, kv_inline([1])) {
        case Applied(payload):
            if payload.revision != 1 {
                panic("cas on an absent key should consume revision 1")
            }
        case Conflict(payload):
            panic("expecting absent on an absent key must not conflict")
    }
    match kv_memory_compare_and_put(empty, kv_key("n", [2]), Some(7), kv_inline([2])) {
        case Applied(payload):
            if payload.revision != 1 {
                panic("cas with any expectation on an absent key applies")
            }
        case Conflict(payload):
            panic("revision expectation is not checked against an absent key")
    }
}
