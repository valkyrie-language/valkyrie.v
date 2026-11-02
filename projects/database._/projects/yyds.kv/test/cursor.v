namespace yyds.kv;

private micro cursor_fixture() -> KvMemoryShard {
    let empty: KvMemoryShard = kv_memory_new()
    let step1: KvPutOutcome = kv_memory_put(empty, kv_key("n", [30]), kv_inline([3]))
    let step2: KvPutOutcome = kv_memory_put(step1.shard, kv_key("n", [10]), kv_inline([1]))
    let step3: KvPutOutcome = kv_memory_put(step2.shard, kv_key("n", [40]), kv_inline([4]))
    let step4: KvPutOutcome = kv_memory_put(step3.shard, kv_key("n", [20]), kv_inline([2]))
    let step5: KvPutOutcome = kv_memory_put(step4.shard, kv_key("other", [15]), kv_inline([9]))
    return step5.shard
}

[test]
micro cursor_iterates_namespace_in_byte_order() -> unit {
    let shard: KvMemoryShard = cursor_fixture()
    let mut cursor: KvShardCursor = kv_memory_cursor_in(shard, "n")
    if !cursor.first() {
        panic("cursor should position on the first record")
    }
    let mut visited: usize = 0
    let mut last_key: [u8] = []
    let mut walking: bool = true
    while walking {
        let record: KvRecord = kv_outcome_must(cursor.record())
        if last_key.length() > 0 && kv_compare_bytes(record.key.bytes, last_key) <= 0 {
            panic("cursor must iterate in ascending byte order")
        }
        last_key = record.key.bytes
        visited = visited + 1
        walking = cursor.next()
    }
    if visited != 4 {
        panic("namespace cursor must stay inside its namespace")
    }
}

[test]
micro cursor_seek_and_range_bounds() -> unit {
    let shard: KvMemoryShard = cursor_fixture()
    let mut cursor: KvShardCursor = kv_memory_cursor_in(shard, "n")
    if !cursor.seek([25]) {
        panic("seek should land on the next greater key")
    }
    let found: KvRecord = kv_outcome_must(cursor.record())
    if !kv_bytes_equal(found.key.bytes, [30]) {
        panic("seek must land on the first key >= target")
    }
    if cursor.seek([99]) {
        panic("seek beyond the last key must not position")
    }
    if cursor.valid() {
        panic("failed seek must leave the cursor unpositioned")
    }
    let ranged: KvShardCursor = kv_memory_cursor_range(shard, "n", Some([20]), Some([40]))
    let mut walk: KvShardCursor = ranged
    if !walk.first() {
        panic("range cursor should find the lower bound")
    }
    let first_hit: KvRecord = kv_outcome_must(walk.record())
    if !kv_bytes_equal(first_hit.key.bytes, [20]) {
        panic("range lower bound is inclusive")
    }
    if !walk.next() {
        panic("range should contain a second record")
    }
    let second_hit: KvRecord = kv_outcome_must(walk.record())
    if !kv_bytes_equal(second_hit.key.bytes, [30]) {
        panic("range upper bound is exclusive")
    }
    if walk.next() {
        panic("range [20, 40) must not contain 40")
    }
}

[test]
micro cursor_prefix_and_reverse() -> unit {
    let shard: KvMemoryShard = cursor_fixture()
    let prefixed: KvShardCursor = kv_memory_cursor_prefix(shard, "n", [4])
    let mut walk: KvShardCursor = prefixed
    if !walk.first() {
        panic("prefix cursor should find [40]")
    }
    if walk.next() {
        panic("prefix cursor must only see matching keys")
    }
    let mut reversed: KvShardCursor = kv_memory_cursor_reverse(shard, "n")
    if !reversed.first() {
        panic("reverse cursor should position on the largest key")
    }
    let top: KvRecord = kv_outcome_must(reversed.record())
    if !kv_bytes_equal(top.key.bytes, [40]) {
        panic("reverse iteration starts at the largest key")
    }
    if !reversed.next() {
        panic("reverse iteration should continue descending")
    }
    let next_hit: KvRecord = kv_outcome_must(reversed.record())
    if !kv_bytes_equal(next_hit.key.bytes, [30]) {
        panic("reverse iteration must descend in byte order")
    }
}

[test]
micro cursor_unpositioned_access_is_structured_failure() -> unit {
    let shard: KvMemoryShard = cursor_fixture()
    let cursor: KvShardCursor = kv_memory_cursor_in(shard, "n")
    let taken: Result<KvRecord, KvFault> = cursor.record()
    if kv_outcome_is_fine(taken) {
        panic("unpositioned cursor access must fail")
    }
    if kv_outcome_fault_code(taken) != kv_fault_cursor_invalid() {
        panic("unpositioned cursor access must report cursor_invalid")
    }
}

[test]
micro cursor_snapshot_isolation_from_later_writes() -> unit {
    let shard: KvMemoryShard = cursor_fixture()
    let cursor: KvShardCursor = kv_memory_cursor_in(shard, "n")
    let added: KvPutOutcome = kv_memory_put(shard, kv_key("n", [15]), kv_inline([7]))
    let mut walk: KvShardCursor = cursor
    if !walk.first() {
        panic("cursor should iterate its frozen snapshot")
    }
    let mut visited: usize = 0
    let mut walking: bool = true
    while walking {
        let record: KvRecord = kv_outcome_must(walk.record())
        if kv_bytes_equal(record.key.bytes, [15]) {
            panic("cursor must not see writes after its creation")
        }
        visited = visited + 1
        walking = walk.next()
    }
    if visited != 4 {
        panic("cursor snapshot must be stable")
    }
    if kv_memory_get(added.shard, kv_key("n", [15])).is_none() {
        panic("the shard itself must see the new write")
    }
}
