namespace database;

# 有序键编码（memcomparable）与字节比较。
#
# 引擎层只认无符号字节字典序；本模块给 schema/记录层提供保序编码：
# 同类型内编码序等于值序，跨类型按首字节类型码排序。
# 编码全程只用非负 i64 算术（除法/取模提取字节），不依赖位运算。

# 类型码（编码首字节）。
micro database_kind_null() -> i64 {
    return 0
}

micro database_kind_bytes() -> i64 {
    return 1
}

micro database_kind_i64() -> i64 {
    return 2
}

micro database_kind_text() -> i64 {
    return 3
}

# f64 保序编码需要位级访问（符号/尾数变换），当前工具链缺位转换能力，
# 类型码预留，编码器待能力补齐后落地（见 readme 当前限制）。
micro database_kind_f64() -> i64 {
    return 4
}

# bool 键编码：`[tag, 0|1]`，天然保序（false < true）。
micro database_kind_bool() -> i64 {
    return 5
}

micro database_encode_bool(value: bool) -> [u8] {
    if value {
        return [database_kind_bool() as u8, 1]
    }
    return [database_kind_bool() as u8, 0]
}

# f64 保序编码合同：需要 f64 → 64 位整数的位重解释宿主能力（符号翻转/全取反变换
# 都建立在原始位之上）。位访问原语就位前一律 `capability_missing`（fail-closed），
# 不以截断、文本化或近似伪造顺序。
micro database_encode_f64(value: f64) -> Result<[u8], DatabaseFault> {
    return Fail(DatabaseFault { code: database_fault_capability_missing() })
}

# 无符号字节字典序比较：a 小返回负值，相等返回 0，a 大返回正值（i64 口径）。
micro database_compare_bytes(a: [u8], b: [u8]) -> i64 {
    let mut index: i64 = 0
    let a_size: i64 = a.length() as i64
    let b_size: i64 = b.length() as i64
    while index < a_size && index < b_size {
        let left: i64 = std::collection::array::get(a, index as usize) as i64
        let right: i64 = std::collection::array::get(b, index as usize) as i64
        if left < right {
            return -1
        }
        if left > right {
            return 1
        }
        index = index + 1
    }
    if a_size < b_size {
        return -1
    }
    if a_size > b_size {
        return 1
    }
    return 0
}

micro database_bytes_equal(a: [u8], b: [u8]) -> bool {
    return database_compare_bytes(a, b) == 0
}

micro database_bytes_have_prefix(bytes: [u8], prefix: [u8]) -> bool {
    let prefix_size: i64 = prefix.length() as i64
    let bytes_size: i64 = bytes.length() as i64
    if prefix_size > bytes_size {
        return false
    }
    let mut index: i64 = 0
    while index < prefix_size {
        let left: u8 = std::collection::array::get(bytes, index as usize)
        let right: u8 = std::collection::array::get(prefix, index as usize)
        if left != right {
            return false
        }
        index = index + 1
    }
    return true
}

# 取子数组（`start` 起 `count` 个）；越界部分不可达，调用方先验界。
micro database_slice_bytes(data: [u8], start: i64, count: i64) -> [u8] {
    let mut out: [u8] = []
    let mut offset: i64 = 0
    while offset < count {
        out = push(out, std::collection::array::get(data, (start + offset) as usize))
        offset = offset + 1
    }
    return out
}

micro database_encode_null() -> [u8] {
    return [database_kind_null() as u8]
}

# i64 保序编码：`[tag]` + 8 字节。
# 非负值：首字节 = 大端首字节 + 128（值域 128..=255）；
# 负值：幅度 m = -1 - value 的大端字节逐字节取补（首字节 127 - b0，其余 255 - bi，值域 0..=127）。
# 两组内部字典序均等于值序，且全部负值编码小于全部非负编码。
micro database_encode_i64(value: i64) -> [u8] {
    let mut magnitude: i64 = value
    if value < 0 {
        magnitude = -1 - value
    }
    let mut bytes: [u8] = []
    let mut rest: i64 = magnitude
    let mut filled: i64 = 0
    while filled < 8 {
        bytes = push(bytes, (rest % 256) as u8)
        rest = rest / 256
        filled = filled + 1
    }
    let mut big_endian: [u8] = []
    let mut cursor: i64 = 7
    while cursor >= 0 {
        big_endian = push(big_endian, std::collection::array::get(bytes, cursor as usize))
        cursor = cursor - 1
    }
    let first: i64 = std::collection::array::get(big_endian, 0) as i64
    if value >= 0 {
        let mut encoded: [u8] = [database_kind_i64() as u8, (first + 128) as u8]
        let mut index: i64 = 1
        while index < 8 {
            encoded = push(encoded, std::collection::array::get(big_endian, index as usize))
            index = index + 1
        }
        return encoded
    }
    let mut complemented: [u8] = [database_kind_i64() as u8, (127 - first) as u8]
    let mut index: i64 = 1
    while index < 8 {
        let byte: i64 = std::collection::array::get(big_endian, index as usize) as i64
        complemented = push(complemented, (255 - byte) as u8)
        index = index + 1
    }
    return complemented
}

# 解码 `database_encode_i64` 的产物；格式不符返回 `corrupt_encoding`。
micro database_decode_i64(encoded: [u8]) -> Result<i64, DatabaseFault> {
    let size: i64 = encoded.length() as i64
    if size != 9 {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    let tag: i64 = std::collection::array::get(encoded, 0) as i64
    if tag != database_kind_i64() {
        return Fail(DatabaseFault { code: database_fault_corrupt_encoding() })
    }
    let head: i64 = std::collection::array::get(encoded, 1) as i64
    let mut magnitude: i64 = 0
    let mut index: i64 = 1
    if head >= 128 {
        magnitude = head - 128
        while index < 8 {
            let byte: i64 = std::collection::array::get(encoded, (index + 1) as usize) as i64
            magnitude = magnitude * 256 + byte
            index = index + 1
        }
        return Fine(magnitude)
    }
    magnitude = 127 - head
    while index < 8 {
        let byte: i64 = std::collection::array::get(encoded, (index + 1) as usize) as i64
        magnitude = magnitude * 256 + (255 - byte)
        index = index + 1
    }
    return Fine(-1 - magnitude)
}

# 字节串保序编码：`[tag]` + 转义载荷 + `[0, 0]` 终止。
# 载荷内 0 字节转义为 `[0, 1]`；终止符双零保证：X 是 Y 的真前缀当且仅当
# 编码后 X 的字典序小于 Y（前缀扫描与范围扫描在此编码上成立）。
micro database_encode_bytes(data: [u8]) -> [u8] {
    let mut out: [u8] = [database_kind_bytes() as u8]
    let size: i64 = data.length() as i64
    let mut index: i64 = 0
    while index < size {
        let byte: u8 = std::collection::array::get(data, index as usize)
        if byte == 0 {
            out = push(out, 0)
            out = push(out, 1)
        }
        else {
            out = push(out, byte)
        }
        index = index + 1
    }
    out = push(out, 0)
    out = push(out, 0)
    return out
}

# 文本保序编码：与字节同形但独立类型码（跨类型按类型码排序）。
micro database_encode_text(data: [u8]) -> [u8] {
    let encoded: [u8] = database_encode_bytes(data)
    let mut out: [u8] = [database_kind_text() as u8]
    let size: i64 = encoded.length() as i64
    let mut index: i64 = 1
    while index < size {
        out = push(out, std::collection::array::get(encoded, index as usize))
        index = index + 1
    }
    return out
}

# 复合键：各段已编码产物直接拼接（各段自带终止，拼接不破坏段内序）。
micro database_encode_composite(parts: [[u8]]) -> [u8] {
    let mut out: [u8] = []
    let count: i64 = parts.length() as i64
    let mut index: i64 = 0
    while index < count {
        let part: [u8] = std::collection::array::get(parts, index as usize)
        let part_size: i64 = part.length() as i64
        let mut cursor: i64 = 0
        while cursor < part_size {
            out = push(out, std::collection::array::get(part, cursor as usize))
            cursor = cursor + 1
        }
        index = index + 1
    }
    return out
}
