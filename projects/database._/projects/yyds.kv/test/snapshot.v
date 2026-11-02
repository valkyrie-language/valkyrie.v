namespace yyds.kv;

[test]
micro snapshot_freezes_state_at_creation() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let step1: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1]), kv_inline([10]))
    let snapshot: KvShardSnapshot = kv_memory_snapshot(step1.shard)
    if kv_snapshot_revision(snapshot) != 1 {
        panic("snapshot should carry the creation revision")
    }
    if kv_snapshot_record_count(snapshot) != 1 {
        panic("snapshot should hold the records at creation")
    }
    let step2: KvPutOutcome = kv_memory_put(step1.shard, kv_key("n", [1]), kv_inline([11]))
    let step3: KvPutOutcome = kv_memory_put(step2.shard, kv_key("n", [2]), kv_inline([20]))
    let frozen: Option<KvRecord> = kv_snapshot_get(snapshot, kv_key("n", [1]))
    if frozen.is_none() {
        panic("snapshot must keep the frozen record")
    }
    let frozen_bytes: [u8] = kv_stored_value_inline_bytes(frozen.unwrap().value).unwrap()
    if !kv_bytes_equal(frozen_bytes, [10]) {
        panic("snapshot must not see the later replace")
    }
    if kv_snapshot_get(snapshot, kv_key("n", [2])).is_some() {
        panic("snapshot must not see later inserts")
    }
    let latest: KvRecord = kv_memory_get(step3.shard, kv_key("n", [1])).unwrap()
    let latest_bytes: [u8] = kv_stored_value_inline_bytes(latest.value).unwrap()
    if !kv_bytes_equal(latest_bytes, [11]) {
        panic("the shard itself must see the new value")
    }
}

[test]
micro snapshot_scan_matches_shard_scan() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let step1: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1, 1]), kv_inline([11]))
    let step2: KvPutOutcome = kv_memory_put(step1.shard, kv_key("n", [1, 2]), kv_inline([12]))
    let step3: KvPutOutcome = kv_memory_put(step2.shard, kv_key("n", [2, 1]), kv_inline([21]))
    let step4: KvPutOutcome = kv_memory_put(step3.shard, kv_key("m", [1, 3]), kv_inline([13]))
    let snapshot: KvShardSnapshot = kv_memory_snapshot(step4.shard)
    let hits: [KvRecord] = kv_snapshot_scan(snapshot, "n", [1], None, None, 0)
    if hits.length() != 2 {
        panic("snapshot scan must apply namespace and prefix filters")
    }
    if !kv_bytes_equal(hits⁅0⁆.key.bytes, [1, 1]) {
        panic("snapshot scan must keep byte order")
    }
    if !kv_bytes_equal(hits⁅1⁆.key.bytes, [1, 2]) {
        panic("snapshot scan must keep byte order")
    }
    let window: [KvRecord] = kv_snapshot_scan(snapshot, "n", [], Some([1, 1]), Some([2, 1]), 0)
    if window.length() != 1 {
        panic("snapshot scan cursors must stay exclusive")
    }
    if !kv_bytes_equal(window⁅0⁆.key.bytes, [1, 2]) {
        panic("exclusive window should keep only the middle key")
    }
}
