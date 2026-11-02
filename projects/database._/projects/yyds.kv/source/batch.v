namespace yyds.kv;

# KvWriteBatch — 分片批量暂存与提交。
#
# 批量把一串 put/delete 暂存为一次提交边界：暂存对分片不可见；
# commit 依序折叠产出新分片（原分片不被修改，失败/丢弃即整体不生效）。
# 内存分片的批量原子性是结构性的（折叠完成才发布），但**不是持久边界**——
# 持久原子提交仍按 `kv_memory_commit_changes` 合同拒绝；
# 显式持久请求 `kv_memory_commit_batch_durable` 一律 `kv_fault_non_atomic_boundary`。
class KvWriteBatch {
    _sealed: bool
    _ops: [i64]
    _keys: [KvKey]
    _values: [KvStoredValue]
}

micro kv_batch_op_put() -> i64 {
    return 1
}

micro kv_batch_op_delete() -> i64 {
    return 2
}

micro kv_batch_new() -> KvWriteBatch {
    return KvWriteBatch {
        _sealed: false,
        _ops: [],
        _keys: [],
        _values: []
    }
}

imply KvWriteBatch {
    # 暂存写入；已封口即 `kv_fault_batch_sealed`。
    micro put(mut self, key: KvKey, value: KvStoredValue) -> Result<bool, KvFault> {
        if self._sealed {
            return Fail(KvFault { code: kv_fault_batch_sealed() })
        }
        self._ops = push(self._ops, kv_batch_op_put())
        self._keys = push(self._keys, key)
        self._values = push(self._values, value)
        return Fine(true)
    }

    # 暂存删除；已封口即 `kv_fault_batch_sealed`。
    micro delete(mut self, key: KvKey) -> Result<bool, KvFault> {
        if self._sealed {
            return Fail(KvFault { code: kv_fault_batch_sealed() })
        }
        self._ops = push(self._ops, kv_batch_op_delete())
        self._keys = push(self._keys, key)
        self._values = push(self._values, kv_inline([]))
        return Fine(true)
    }

    micro count(self) -> usize {
        return self._ops.length()
    }

    micro is_empty(self) -> bool {
        return self.count() == 0
    }

    # 丢弃：封口且不生效任何暂存项。
    micro discard(mut self) -> unit {
        self._sealed = true
    }
}

# 批量提交结果：新分片与最后写入的 revision。
structure KvBatchCommit {
    shard: KvMemoryShard
    revision: u64
}

# 提交：依序折叠暂存项产出新分片并封口；空批量为幂等空操作（原分片返回）。
micro kv_memory_commit_batch(shard: KvMemoryShard, mut batch: KvWriteBatch) -> Result<KvBatchCommit, KvFault> {
    if batch._sealed {
        return Fail(KvFault { code: kv_fault_batch_sealed() })
    }
    if batch.is_empty() {
        batch._sealed = true
        return Fine(KvBatchCommit {
            shard: shard,
            revision: shard.next_revision
        })
    }
    let mut staged: KvMemoryShard = shard
    let mut applied_revision: u64 = shard.next_revision
    let mut cursor: usize = 0
    let count: usize = batch.count()
    while cursor < count {
        let op: i64 = batch._ops⁅cursor⁆
        let key: KvKey = batch._keys⁅cursor⁆
        if op == kv_batch_op_put() {
            let outcome: KvPutOutcome = kv_memory_put(staged, key, batch._values⁅cursor⁆)
            staged = outcome.shard
            applied_revision = outcome.revision
        }
        else {
            let outcome: KvDeleteOutcome = kv_memory_delete(staged, key)
            staged = outcome.shard
        }
        cursor = cursor + 1
    }
    batch._sealed = true
    return Fine(KvBatchCommit {
        shard: staged,
        revision: applied_revision
    })
}

# 显式持久原子提交请求：内存分片 fail-closed，不伪造持久性。
micro kv_memory_commit_batch_durable(shard: KvMemoryShard, batch: KvWriteBatch) -> Result<KvBatchCommit, KvFault> {
    return Fail(KvFault { code: kv_fault_non_atomic_boundary() })
}
