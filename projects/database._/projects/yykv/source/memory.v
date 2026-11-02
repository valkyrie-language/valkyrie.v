namespace yykv;

# 内存分片：记录按键序保存在有序数组中（有序映射的纯 V 对应形态）。
# 仅用于单元测试与早期集成；按合同不提供持久化原子提交边界，
# 执行器不得对其开启事务，不得以执行器侧锁伪装持久性。
structure KvMemoryShard {
    records: [KvRecord]
    next_revision: u64
}

micro kv_memory_new() -> KvMemoryShard {
    return KvMemoryShard {
        records: [],
        next_revision: 0
    }
}

micro kv_memory_length(shard: KvMemoryShard) -> usize {
    return shard.records.length()
}

# 分片已消耗的最大 revision；空分片为 0。
micro kv_memory_revision(shard: KvMemoryShard) -> u64 {
    return shard.next_revision
}

# 二分定位结果：键所在下标，或缺失时的有序插入位置（均为 0 基）。
unite KvSlot {
    [constructor]
    Found {
        index: usize
    }
    [constructor]
    Absent {
        insert_at: usize
    }
}

private micro kv_memory_slot(shard: KvMemoryShard, key: KvKey) -> KvSlot {
    let mut low: usize = 0
    let mut high: usize = shard.records.length()
    while low < high {
        let middle: usize = (low + high) / 2
        let order: i32 = kv_compare_keys(shard.records⁅middle⁆.key, key)
        if order == 0 {
            return Found {
                index: middle
            }
        }
        if order < 0 {
            low = middle + 1
        }
        else {
            high = middle
        }
    }
    return Absent {
        insert_at: low
    }
}

micro kv_memory_get(shard: KvMemoryShard, key: KvKey) -> Option<KvRecord> {
    match kv_memory_slot(shard, key) {
        case Found(slot):
            Some(shard.records⁅slot.index⁆)
        case Absent(slot):
            None
    }
}

structure KvPutOutcome {
    shard: KvMemoryShard
    revision: u64
}

structure KvDeleteOutcome {
    shard: KvMemoryShard
    removed: bool
}

# 插入或替换，返回携带新 revision 的新分片；原分片不被修改。
micro kv_memory_put(shard: KvMemoryShard, key: KvKey, value: KvStoredValue) -> KvPutOutcome {
    let revision: u64 = shard.next_revision + 1
    let record: KvRecord = kv_record(key, value, revision)
    match kv_memory_slot(shard, key) {
        case Found(slot):
            KvPutOutcome {
                shard: KvMemoryShard {
                    records: kv_replace_at(shard.records, slot.index, record),
                    next_revision: revision
                },
                revision: revision
            }
        case Absent(slot):
            KvPutOutcome {
                shard: KvMemoryShard {
                    records: kv_insert_at(shard.records, slot.insert_at, record),
                    next_revision: revision
                },
                revision: revision
            }
    }
}

# 存在则删除并报告 removed；缺失时原样返回分片。
micro kv_memory_delete(shard: KvMemoryShard, key: KvKey) -> KvDeleteOutcome {
    match kv_memory_slot(shard, key) {
        case Found(slot):
            KvDeleteOutcome {
                shard: KvMemoryShard {
                    records: kv_remove_at(shard.records, slot.index),
                    next_revision: shard.next_revision
                },
                removed: true
            }
        case Absent(slot):
            KvDeleteOutcome {
                shard: shard,
                removed: false
            }
    }
}

# 一个分片级原子提交内的单项变更。
unite KvShardChange {
    [constructor]
    Put {
        key: KvKey
        value: KvStoredValue
    }
    [constructor]
    Delete {
        key: KvKey
    }
}

unite KvCommitOutcome {
    [constructor]
    Applied {
        shard: KvMemoryShard
    }
    [constructor]
    Unsupported {
        feature: utf8
    }
}

# 提交边界合同：内存分片的提交边界是进程易失的，必须保持拒绝，
# 使执行器拒绝在其上开启事务，而不是退化为逐条执行。
micro kv_memory_durable_atomic_commit(shard: KvMemoryShard) -> bool {
    return false
}

micro kv_memory_commit_changes(shard: KvMemoryShard, changes: [KvShardChange]) -> KvCommitOutcome {
    return Unsupported {
        feature: "memory shard does not provide a durable atomic commit boundary"
    }
}

unite KvCasOutcome {
    [constructor]
    Applied {
        shard: KvMemoryShard
        revision: u64
    }
    [constructor]
    Conflict {
        key: KvKey
    }
}

# 比较并写入：expect_revision 为 `None` 表示期望键缺失；
# 期望缺失但键存在、或期望 revision 与当前记录不符时冲突。
# 期望特定 revision 但键缺失时按写入处理（与参考语义一致）。
micro kv_memory_compare_and_put(shard: KvMemoryShard, key: KvKey, expect_revision: Option<u64>, value: KvStoredValue) -> KvCasOutcome {
    let current: Option<KvRecord> = kv_memory_get(shard, key)
    if kv_cas_conflicts(current, expect_revision) {
        return Conflict {
            key: key
        }
    }
    let outcome: KvPutOutcome = kv_memory_put(shard, key, value)
    return Applied {
        shard: outcome.shard,
        revision: outcome.revision
    }
}

private micro kv_cas_conflicts(current: Option<KvRecord>, expect_revision: Option<u64>) -> bool {
    match current {
        case Some(record):
            match expect_revision {
                case Some(expected):
                    record.revision != expected
                case None:
                    true
            }
        case None:
            false
    }
}

# 有序前缀扫描：单命名空间内按字节序升序返回至多 `limit` 条记录。
# `after` 为排他下界游标，`before` 为排他上界游标；`limit` 为 0 表示不设上限。
micro kv_memory_scan(shard: KvMemoryShard, space: utf8, prefix: [u8], after: Option<[u8]>, before: Option<[u8]>, limit: usize) -> [KvRecord] {
    let mut collected: [KvRecord] = []
    let mut cursor: usize = 0
    while cursor < shard.records.length() {
        let record: KvRecord = shard.records⁅cursor⁆
        cursor = cursor + 1
        if !record.key.space.equals(space) {
            continue
        }
        if !kv_bytes_have_prefix(record.key.bytes, prefix) {
            continue
        }
        if !kv_scan_key_after(record.key.bytes, after) {
            continue
        }
        if !kv_scan_key_before(record.key.bytes, before) {
            continue
        }
        collected = push(collected, record)
        if limit > 0 && collected.length() >= limit {
            return collected
        }
    }
    return collected
}

private micro kv_scan_key_after(bytes: [u8], after: Option<[u8]>) -> bool {
    match after {
        case Some(cursor):
            kv_compare_bytes(bytes, cursor) > 0
        case None:
            true
    }
}

private micro kv_scan_key_before(bytes: [u8], before: Option<[u8]>) -> bool {
    match before {
        case Some(cursor):
            kv_compare_bytes(bytes, cursor) < 0
        case None:
            true
    }
}

private micro kv_replace_at(records: [KvRecord], index: usize, record: KvRecord) -> [KvRecord] {
    let mut rebuilt: [KvRecord] = []
    let mut cursor: usize = 0
    while cursor < records.length() {
        if cursor == index {
            rebuilt = push(rebuilt, record)
        }
        else {
            rebuilt = push(rebuilt, records⁅cursor⁆)
        }
        cursor = cursor + 1
    }
    return rebuilt
}

private micro kv_insert_at(records: [KvRecord], index: usize, record: KvRecord) -> [KvRecord] {
    let mut rebuilt: [KvRecord] = []
    let mut cursor: usize = 0
    while cursor < records.length() {
        if cursor == index {
            rebuilt = push(rebuilt, record)
        }
        rebuilt = push(rebuilt, records⁅cursor⁆)
        cursor = cursor + 1
    }
    if index >= records.length() {
        rebuilt = push(rebuilt, record)
    }
    return rebuilt
}

private micro kv_remove_at(records: [KvRecord], index: usize) -> [KvRecord] {
    let mut rebuilt: [KvRecord] = []
    let mut cursor: usize = 0
    while cursor < records.length() {
        if cursor != index {
            rebuilt = push(rebuilt, records⁅cursor⁆)
        }
        cursor = cursor + 1
    }
    return rebuilt
}
