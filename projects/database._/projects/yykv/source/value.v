namespace yykv;

# 记录载荷：小或热的值内联保存在分片索引中；大或冷的值以内容散列
# 引用共享对象面（内容寻址存储），散列语义与上面对象层对齐，
# 但放置归分片所有，不是单行文件存储。
unite KvStoredValue {
    [constructor]
    Inline {
        bytes: [u8]
    }
    [constructor]
    Object {
        digest_text: utf8
    }
}

micro kv_inline(bytes: [u8]) -> KvStoredValue {
    return Inline {
        bytes: bytes
    }
}

micro kv_object(digest_text: utf8) -> KvStoredValue {
    return Object {
        digest_text: digest_text
    }
}

micro kv_stored_value_is_object(value: KvStoredValue) -> bool {
    match value {
        case Inline(payload):
            false
        case Object(payload):
            true
    }
}

# 内联载荷字节；对象引用返回 `None`，调用方不得借此取对象内容。
micro kv_stored_value_inline_bytes(value: KvStoredValue) -> Option<[u8]> {
    match value {
        case Inline(payload):
            Some(payload.bytes)
        case Object(payload):
            None
    }
}
