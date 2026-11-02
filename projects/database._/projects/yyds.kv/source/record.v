namespace yyds.kv;

# 分片内一条带版本的 KV 记录：revision 在分片内单调递增，
# 每次成功写入消耗一个新 revision。
structure KvRecord {
    key: KvKey
    value: KvStoredValue
    revision: u64
}

micro kv_record(key: KvKey, value: KvStoredValue, revision: u64) -> KvRecord {
    return KvRecord {
        key: key,
        value: value,
        revision: revision
    }
}
