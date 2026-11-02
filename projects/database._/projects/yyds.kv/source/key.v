namespace yyds.kv;

# 分片内逻辑键：命名空间 + 命名空间内不透明字节序列。
# 命名空间隔离租户数据，不要求 SQL schema。
# 字段命名为 `space`：`namespace` 是语言关键字，不能用作标识符。
structure KvKey {
    space: utf8
    bytes: [u8]
}

micro kv_key(space: utf8, bytes: [u8]) -> KvKey {
    return KvKey {
        space: space,
        bytes: bytes
    }
}

# 无符号字节字典序比较：a 小返回 -1，相等返回 0，a 大返回 1。
# UTF-8 的字节序与码点序一致，命名空间比较可直接作用于其字节表示。
micro kv_compare_bytes(a: [u8], b: [u8]) -> i32 {
    let mut index: usize = 0
    while index < a.length() && index < b.length() {
        if a⁅index⁆ < b⁅index⁆ {
            return -1
        }
        if a⁅index⁆ > b⁅index⁆ {
            return 1
        }
        index = index + 1
    }
    if a.length() < b.length() {
        return -1
    }
    if a.length() > b.length() {
        return 1
    }
    return 0
}

micro kv_bytes_equal(a: [u8], b: [u8]) -> bool {
    return kv_compare_bytes(a, b) == 0
}

# 键序：先命名空间（按其 UTF-8 字节），再键字节。
micro kv_compare_keys(a: KvKey, b: KvKey) -> i32 {
    let by_space: i32 = kv_compare_bytes(a.space.bytes(), b.space.bytes())
    if by_space != 0 {
        return by_space
    }
    return kv_compare_bytes(a.bytes, b.bytes)
}

micro kv_key_equals(a: KvKey, b: KvKey) -> bool {
    return kv_compare_keys(a, b) == 0
}

micro kv_bytes_have_prefix(bytes: [u8], prefix: [u8]) -> bool {
    if prefix.length() > bytes.length() {
        return false
    }
    let mut index: usize = 0
    while index < prefix.length() {
        if bytes⁅index⁆ != prefix⁅index⁆ {
            return false
        }
        index = index + 1
    }
    return true
}
