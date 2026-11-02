namespace yyds.kv;

[test]
micro batch_commit_applies_in_order_and_counts_revisions() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let seeded: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1]), kv_inline([1]))
    let mut batch: KvWriteBatch = kv_batch_new()
    let mut staged: Result<bool, KvFault> = batch.put(kv_key("n", [2]), kv_inline([20]))
    staged = batch.put(kv_key("n", [3]), kv_inline([30]))
    staged = batch.delete(kv_key("n", [1]))
    if batch.count() != 3 {
        panic("batch should stage three operations")
    }
    if kv_memory_get(seeded.shard, kv_key("n", [2])).is_some() {
        panic("staged operations must not be visible before commit")
    }
    let committed: Result<KvBatchCommit, KvFault> = kv_memory_commit_batch(seeded.shard, batch)
    let result: KvBatchCommit = kv_outcome_must(committed)
    if result.revision != seeded.revision + 2 {
        panic("batch commit should consume one revision per put; delete here matches an existing key and consumes none")
    }
    if kv_memory_get(result.shard, kv_key("n", [2])).is_none() {
        panic("batch put should be visible after commit")
    }
    if kv_memory_get(result.shard, kv_key("n", [1])).is_some() {
        panic("batch delete should remove the record")
    }
    if kv_memory_length(seeded.shard) != 1 {
        panic("the source shard must not be mutated by a batch commit")
    }
}

[test]
micro empty_batch_is_noop() -> unit {
    let empty: KvMemoryShard = kv_memory_new()
    let seeded: KvPutOutcome = kv_memory_put(empty, kv_key("n", [1]), kv_inline([1]))
    let batch: KvWriteBatch = kv_batch_new()
    let committed: Result<KvBatchCommit, KvFault> = kv_memory_commit_batch(seeded.shard, batch)
    let result: KvBatchCommit = kv_outcome_must(committed)
    if result.revision != seeded.revision {
        panic("empty batch must not consume a revision")
    }
    if kv_memory_length(result.shard) != 1 {
        panic("empty batch must leave the shard unchanged")
    }
}

[test]
micro sealed_batch_rejects_further_use() -> unit {
    let shard: KvMemoryShard = kv_memory_new()
    let mut batch: KvWriteBatch = kv_batch_new()
    let staged: Result<bool, KvFault> = batch.put(kv_key("n", [1]), kv_inline([1]))
    let committed: Result<KvBatchCommit, KvFault> = kv_memory_commit_batch(shard, batch)
    if !kv_outcome_is_fine(committed) {
        panic("first commit should succeed")
    }
    let reuse: Result<bool, KvFault> = batch.put(kv_key("n", [2]), kv_inline([2]))
    if kv_outcome_fault_code(reuse) != kv_fault_batch_sealed() {
        panic("staging on a sealed batch must fail with batch_sealed")
    }
    let recommit: Result<KvBatchCommit, KvFault> = kv_memory_commit_batch(shard, batch)
    if kv_outcome_fault_code(recommit) != kv_fault_batch_sealed() {
        panic("re-commit of a sealed batch must fail with batch_sealed")
    }
}

[test]
micro discarded_batch_applies_nothing() -> unit {
    let shard: KvMemoryShard = kv_memory_new()
    let mut batch: KvWriteBatch = kv_batch_new()
    let staged: Result<bool, KvFault> = batch.put(kv_key("n", [1]), kv_inline([1]))
    batch.discard()
    let after_discard: Result<bool, KvFault> = batch.put(kv_key("n", [2]), kv_inline([2]))
    if kv_outcome_fault_code(after_discard) != kv_fault_batch_sealed() {
        panic("a discarded batch must reject further staging")
    }
    if kv_memory_get(shard, kv_key("n", [1])).is_some() {
        panic("a discarded batch must not affect the shard")
    }
}

[test]
micro durable_commit_boundary_is_refused_structurally() -> unit {
    let shard: KvMemoryShard = kv_memory_new()
    let mut batch: KvWriteBatch = kv_batch_new()
    let staged: Result<bool, KvFault> = batch.put(kv_key("n", [1]), kv_inline([1]))
    let durable: Result<KvBatchCommit, KvFault> = kv_memory_commit_batch_durable(shard, batch)
    if kv_outcome_is_fine(durable) {
        panic("memory shard must refuse a durable atomic commit boundary")
    }
    if kv_outcome_fault_code(durable) != kv_fault_non_atomic_boundary() {
        panic("durable refusal must report non_atomic_boundary")
    }
}
