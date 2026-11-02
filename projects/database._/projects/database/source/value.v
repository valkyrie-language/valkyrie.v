namespace database;

# 值编码与类型描述。
#
# 引擎层值是不透明字节；本模块给记录层提供带类型码的值编码：
# `[类型码]` + 载荷。值编码不保序（序语义只在键上），但类型码与键编码一致。
# i64 载荷直接复用 memcomparable 字节（保序无损）。

micro database_value_encode_null() -> [u8] {
    return [database_kind_null() as u8]
}

micro database_value_encode_i64(value: i64) -> [u8] {
    return database_encode_i64(value)
}

micro database_value_encode_bytes(data: [u8]) -> [u8] {
    let mut out: [u8] = [database_kind_bytes() as u8]
    let size: i64 = data.length() as i64
    let mut index: i64 = 0
    while index < size {
        out = push(out, std::collection::array::get(data, index as usize))
        index = index + 1
    }
    return out
}

micro database_value_encode_text(data: [u8]) -> [u8] {
    let mut out: [u8] = [database_kind_text() as u8]
    let size: i64 = data.length() as i64
    let mut index: i64 = 0
    while index < size {
        out = push(out, std::collection::array::get(data, index as usize))
        index = index + 1
    }
    return out
}

# 读取值的类型码；空输入返回 `corrupt_encoding`。
micro database_value_kind(encoded: [u8]) -> Result<i64, DatabaseFault> {
    let size: i64 = encoded.length() as i64
    if size == 0 {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    let tag: i64 = std::collection::array::get(encoded, 0) as i64
    if tag == database_kind_null() {
        return Fine(tag)
    }
    if tag == database_kind_bytes() {
        return Fine(tag)
    }
    if tag == database_kind_i64() {
        return Fine(tag)
    }
    if tag == database_kind_text() {
        return Fine(tag)
    }
    return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
}

# 取值的载荷字节（剥掉类型码）；未知类型码返回 `corrupt_encoding`。
micro database_value_payload(encoded: [u8]) -> Result<[u8], DatabaseFault> {
    let kind: Result<i64, DatabaseFault> = database_value_kind(encoded)
    if !database_outcome_is_fine(kind) {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    let size: i64 = encoded.length() as i64
    return Fine(database_slice_bytes(encoded, 1, size - 1))
}

# 解码 i64 值（类型码不符即 `corrupt_encoding`）。
micro database_value_decode_i64(encoded: [u8]) -> Result<i64, DatabaseFault> {
    let kind: Result<i64, DatabaseFault> = database_value_kind(encoded)
    let expected: i64 = database_kind_i64()
    if database_outcome_fault_code(kind) != 0 {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    let actual: i64 = database_outcome_value_or(kind, 0)
    if actual != expected {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    return database_decode_i64(encoded)
}
