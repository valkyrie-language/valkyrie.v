namespace std.data;

# 缓存槽位：产物在或不在的可区分联合（实质需求，非规避）。
unite DataCacheSlot<T> {
    [constructor]
    Filled {
        value: T
    }
    Empty
}

# 三层产物（token stream / CST）的缓存。
#
# 键 = 源内容指纹 + 设置指纹；不使用路径、时间戳或任何环境值。
# 命中直接复用槽内产物；任一半键不等即整体失效，由调用方重算后重建缓存。
# 一层一个实例：token 缓存与 CST 缓存各自独立持有。
structure DataCache<T> {
    source_digest: usize
    settings_fingerprint: usize
    value: DataCacheSlot<T>
}

# 空缓存（无命中可能，首次计算后由 `data_cache_store` 填充）。
# 指纹字段取 0 仅为占位：`Empty` 槽位下命中判定先行短路，两字段不参与比较。
micro data_cache_empty<T>() -> DataCache<T> {
    return DataCache {
        source_digest: 0,
        settings_fingerprint: 0,
        value: Empty
    }
}

# 命中判定：槽位非空，且源内容指纹与设置指纹同时相等。
micro data_cache_matches<T>(cache: DataCache<T>, source_digest: usize, settings_fingerprint: usize) -> bool {
    match cache.value {
        case Filled(payload):
            return cache.source_digest == source_digest && cache.settings_fingerprint == settings_fingerprint
        case Empty:
            return false
    }
}

# 写入缓存产物（重算完成后调用）。
micro data_cache_store<T>(source_digest: usize, settings_fingerprint: usize, value: T) -> DataCache<T> {
    return DataCache {
        source_digest: source_digest,
        settings_fingerprint: settings_fingerprint,
        value: Filled { value: value }
    }
}

# 取缓存槽位；命中与否由调用方 match 判定。
micro data_cache_value<T>(cache: DataCache<T>) -> DataCacheSlot<T> {
    return cache.value
}
