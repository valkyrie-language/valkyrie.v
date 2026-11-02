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

micro database_value_encode_bool(value: bool) -> [u8] {
    return database_encode_bool(value)
}

# f64 值编码合同：与键编码同缺口——位重解释宿主能力就位前 fail-closed。
micro database_value_encode_f64(value: f64) -> Result<[u8], DatabaseFault> {
    return database_encode_f64(value)
}

# 读取 bool 值（类型码不符即 `corrupt_encoding`）。
micro database_value_decode_bool(encoded: [u8]) -> Result<bool, DatabaseFault> {
    let size: i64 = encoded.length() as i64
    if size != 2 {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    let tag: i64 = std::collection::array::get(encoded, 0) as i64
    if tag != database_kind_bool() {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    let flag: i64 = std::collection::array::get(encoded, 1) as i64
    if flag == 0 {
        return Fine(false)
    }
    if flag == 1 {
        return Fine(true)
    }
    return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
}

# 值全序：先类型码、后同类型内载荷序（i64 载荷为 memcomparable 字节，
# 字典序即数值序；bytes/text 载荷字典序；bool 0<1；null 无载荷相等）。
# 未登记类型码或形态不符即 `corrupt_encoding`，不猜测顺序。
micro database_compare_values(a: [u8], b: [u8]) -> Result<i64, DatabaseFault> {
    let kind_a: Result<i64, DatabaseFault> = database_value_kind(a)
    let kind_b: Result<i64, DatabaseFault> = database_value_kind(b)
    if !database_outcome_is_fine(kind_a) || !database_outcome_is_fine(kind_b) {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    let tag_a: i64 = database_outcome_value_or(kind_a, -1)
    let tag_b: i64 = database_outcome_value_or(kind_b, -1)
    if tag_a < tag_b {
        return Fine(-1)
    }
    if tag_a > tag_b {
        return Fine(1)
    }
    if tag_a == database_kind_null() {
        return Fine(0)
    }
    if !database_value_well_formed(a, tag_a) || !database_value_well_formed(b, tag_b) {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    let payload_a: [u8] = database_outcome_must(database_value_payload(a))
    let payload_b: [u8] = database_outcome_must(database_value_payload(b))
    return Fine(database_compare_bytes(payload_a, payload_b))
}

# 各类型码的载荷形态校验（f64 预留未落地，任何 f64 载荷均不可构造即不合形态）。
micro database_value_well_formed(encoded: [u8], kind: i64) -> bool {
    let size: i64 = encoded.length() as i64
    if kind == database_kind_null() {
        return size == 1
    }
    if kind == database_kind_bool() {
        if size != 2 {
            return false
        }
        let flag: i64 = std::collection::array::get(encoded, 1) as i64
        return flag == 0 || flag == 1
    }
    if kind == database_kind_i64() {
        return size == 9
    }
    if kind == database_kind_bytes() || kind == database_kind_text() {
        return size >= 1
    }
    return false
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
    if tag == database_kind_bool() {
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
