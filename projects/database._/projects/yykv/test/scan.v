namespace yykv;

private micro scan_fixture() -> KvMemoryShard {
    let empty: KvMemoryShard = kv_memory_new()
    let step1: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1, 2]), kv_inline([12]))
    let step2: KvPutOutcome = kv_memory_put(step1.shard, kv_key("n", [1, 3]), kv_inline([13]))
    let step3: KvPutOutcome = kv_memory_put(step2.shard, kv_key("n", [2, 1]), kv_inline([21]))
    return step3.shard
}

[test]
micro scan_returns_prefix_subset_in_byte_order() -> unit {
    let shard: KvMemoryShard = scan_fixture()
    let hits: [KvRecord] = kv_memory_scan(shard, "n", [1], None, None, 0)
    if hits.length() != 2 {
        panic("prefix [1] should match two records")
    }
    if !kv_bytes_equal(hits⁅0⁆.key.bytes, [1, 2]) {
        panic("scan must order by key bytes ascending")
    }
    if !kv_bytes_equal(hits⁅1⁆.key.bytes, [1, 3]) {
        panic("scan must order by key bytes ascending")
    }
}

[test]
micro scan_cursors_are_exclusive() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let step1: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1]), kv_inline([1]))
    let step2: KvPutOutcome = kv_memory_put(step1.shard, kv_key("n", [2]), kv_inline([2]))
    let step3: KvPutOutcome = kv_memory_put(step2.shard, kv_key("n", [3]), kv_inline([3]))
    let shard: KvMemoryShard = step3.shard
    let after_hits: [KvRecord] = kv_memory_scan(shard, "n", [], Some([2]), None, 0)
    if after_hits.length() != 1 {
        panic("after cursor must exclude the boundary key")
    }
    if !kv_bytes_equal(after_hits⁅0⁆.key.bytes, [3]) {
        panic("after cursor should keep only strictly greater keys")
    }
    let before_hits: [KvRecord] = kv_memory_scan(shard, "n", [], None, Some([2]), 0)
    if before_hits.length() != 1 {
        panic("before cursor must exclude the boundary key")
    }
    if !kv_bytes_equal(before_hits⁅0⁆.key.bytes, [1]) {
        panic("before cursor should keep only strictly smaller keys")
    }
    let window: [KvRecord] = kv_memory_scan(shard, "n", [], Some([1]), Some([3]), 0)
    if window.length() != 1 {
        panic("exclusive window should keep only the middle key")
    }
    if !kv_bytes_equal(window⁅0⁆.key.bytes, [2]) {
        panic("exclusive window should keep key [2]")
    }
}

[test]
micro scan_limit_caps_results() -> unit {
    let shard: KvMemoryShard = scan_fixture()
    let capped: [KvRecord] = kv_memory_scan(shard, "n", [], None, None, 2)
    if capped.length() != 2 {
        panic("limit should cap the result count")
    }
    if !kv_bytes_equal(capped⁅0⁆.key.bytes, [1, 2]) {
        panic("limit should keep the byte-order head")
    }
    let uncapped: [KvRecord] = kv_memory_scan(shard, "n", [], None, None, 0)
    if uncapped.length() != 3 {
        panic("limit 0 should mean no cap")
    }
}

[test]
micro scan_isolates_namespaces() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let step1: KvPutOutcome = kv_memory_put(empty, kv_key("a", [1]), kv_inline([1]))
    let step2: KvPutOutcome = kv_memory_put(step1.shard, kv_key("b", [1]), kv_inline([2]))
    let shard: KvMemoryShard = step2.shard
    let hits: [KvRecord] = kv_memory_scan(shard, "a", [], None, None, 0)
    if hits.length() != 1 {
        panic("scan must stay inside one namespace")
    }
    if !hits⁅0⁆.key.space.equals("a") {
        panic("scan must not leak records from another namespace")
    }
    let other: [KvRecord] = kv_memory_scan(shard, "b", [], None, None, 0)
    if other.length() != 1 {
        panic("namespace b should hold its own record")
    }
}
