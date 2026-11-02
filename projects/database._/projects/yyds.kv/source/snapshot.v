namespace yyds.kv;

# KvShardSnapshot — 分片只读冻结视图。
#
# 快照在创建时刻与分片脱钩（分片写操作返回新分片，旧记录数组不被修改），
# 之后的写入对快照不可见。快照不提供写路径。
structure KvShardSnapshot {
    records: [KvRecord]
    revision: u64
}

# 冻结当前分片。
micro kv_memory_snapshot(shard: KvMemoryShard) -> KvShardSnapshot {
    return KvShardSnapshot {
        records: shard.records,
        revision: shard.next_revision
    }
}

micro kv_snapshot_revision(snapshot: KvShardSnapshot) -> u64 {
    return snapshot.revision
}

micro kv_snapshot_record_count(snapshot: KvShardSnapshot) -> usize {
    return snapshot.records.length()
}

# 点查快照：键缺席走 `None`。
micro kv_snapshot_get(snapshot: KvShardSnapshot, key: KvKey) -> Option<KvRecord> {
    let mut index: usize = 0
    while index < snapshot.records.length() {
        let record: KvRecord = snapshot.records⁅index⁆
        if kv_key_equals(record.key, key) {
            return Some(record)
        }
        index = index + 1
    }
    return None
}

# 快照上的单命名空间前缀扫描（与分片扫描同口径：排他游标 + limit 0 无上限）。
micro kv_snapshot_scan(snapshot: KvShardSnapshot, space: utf8, prefix: [u8], after: Option<[u8]>, before: Option<[u8]>, limit: usize) -> [KvRecord] {
    let mut collected: [KvRecord] = []
    let mut index: usize = 0
    while index < snapshot.records.length() {
        let record: KvRecord = snapshot.records⁅index⁆
        index = index + 1
        if !record.key.space.equals(space) {
            continue
        }
        if !kv_bytes_have_prefix(record.key.bytes, prefix) {
            continue
        }
        if after.is_some() && kv_compare_bytes(record.key.bytes, after.unwrap()) <= 0 {
            continue
        }
        if before.is_some() && kv_compare_bytes(record.key.bytes, before.unwrap()) >= 0 {
            continue
        }
        collected = push(collected, record)
        if limit > 0 && collected.length() >= limit {
            return collected
        }
    }
    return collected
}
