namespace std.data.digest;

# SHA-256/SHA-512 已知答案测试：FIPS 180-4 标准向量（"abc" 与空串）。
#
# 阻塞说明：断言依赖 `std::types::panic`，而 `raise` 终止子在各后端尚无目标
# 合同（编译期结构化失败）。运行时证据当前由
# `valkyrie.v/examples/std-data-drive`（node 断言返回值）提供，本套件与其
# 共享同一组向量与判等逻辑，缺陷修复后原样可跑。
#
# 比较纪律：u8 在各后端无比较 provider，逐字节 `as u64` 后比较。

micro sha256_abc_vector() -> [u8] {
    return [0xba as u8, 0x78 as u8, 0x16 as u8, 0xbf as u8, 0x8f as u8, 0x01 as u8, 0xcf as u8, 0xea as u8, 0x41 as u8, 0x41 as u8, 0x40 as u8, 0xde as u8, 0x5d as u8, 0xae as u8, 0x22 as u8, 0x23 as u8, 0xb0 as u8, 0x03 as u8, 0x61 as u8, 0xa3 as u8, 0x96 as u8, 0x17 as u8, 0x7a as u8, 0x9c as u8, 0xb4 as u8, 0x10 as u8, 0xff as u8, 0x61 as u8, 0xf2 as u8, 0x00 as u8, 0x15 as u8, 0xad as u8]
}

micro sha256_empty_vector() -> [u8] {
    return [0xe3 as u8, 0xb0 as u8, 0xc4 as u8, 0x42 as u8, 0x98 as u8, 0xfc as u8, 0x1c as u8, 0x14 as u8, 0x9a as u8, 0xfb as u8, 0xf4 as u8, 0xc8 as u8, 0x99 as u8, 0x6f as u8, 0xb9 as u8, 0x24 as u8, 0x27 as u8, 0xae as u8, 0x41 as u8, 0xe4 as u8, 0x64 as u8, 0x9b as u8, 0x93 as u8, 0x4c as u8, 0xa4 as u8, 0x95 as u8, 0x99 as u8, 0x1b as u8, 0x78 as u8, 0x52 as u8, 0xb8 as u8, 0x55 as u8]
}

micro sha512_abc_vector() -> [u8] {
    return [0xdd as u8, 0xaf as u8, 0x35 as u8, 0xa1 as u8, 0x93 as u8, 0x61 as u8, 0x7a as u8, 0xba as u8, 0xcc as u8, 0x41 as u8, 0x73 as u8, 0x49 as u8, 0xae as u8, 0x20 as u8, 0x41 as u8, 0x31 as u8, 0x12 as u8, 0xe6 as u8, 0xfa as u8, 0x4e as u8, 0x89 as u8, 0xa9 as u8, 0x7e as u8, 0xa2 as u8, 0x0a as u8, 0x9e as u8, 0xee as u8, 0xe6 as u8, 0x4b as u8, 0x55 as u8, 0xd3 as u8, 0x9a as u8, 0x21 as u8, 0x92 as u8, 0x99 as u8, 0x2a as u8, 0x27 as u8, 0x4f as u8, 0xc1 as u8, 0xa8 as u8, 0x36 as u8, 0xba as u8, 0x3c as u8, 0x23 as u8, 0xa3 as u8, 0xfe as u8, 0xeb as u8, 0xbd as u8, 0x45 as u8, 0x4d as u8, 0x44 as u8, 0x23 as u8, 0x64 as u8, 0x3c as u8, 0xe8 as u8, 0x0e as u8, 0x2a as u8, 0x9a as u8, 0xc9 as u8, 0x4f as u8, 0xa5 as u8, 0x4c as u8, 0xa4 as u8, 0x9f as u8]
}

micro sha512_empty_vector() -> [u8] {
    return [0xcf as u8, 0x83 as u8, 0xe1 as u8, 0x35 as u8, 0x7e as u8, 0xef as u8, 0xb8 as u8, 0xbd as u8, 0xf1 as u8, 0x54 as u8, 0x28 as u8, 0x50 as u8, 0xd6 as u8, 0x6d as u8, 0x80 as u8, 0x07 as u8, 0xd6 as u8, 0x20 as u8, 0xe4 as u8, 0x05 as u8, 0x0b as u8, 0x57 as u8, 0x15 as u8, 0xdc as u8, 0x83 as u8, 0xf4 as u8, 0xa9 as u8, 0x21 as u8, 0xd3 as u8, 0x6c as u8, 0xe9 as u8, 0xce as u8, 0x47 as u8, 0xd0 as u8, 0xd1 as u8, 0x3c as u8, 0x5d as u8, 0x85 as u8, 0xf2 as u8, 0xb0 as u8, 0xff as u8, 0x83 as u8, 0x18 as u8, 0xd2 as u8, 0x87 as u8, 0x7e as u8, 0xec as u8, 0x2f as u8, 0x63 as u8, 0xb9 as u8, 0x31 as u8, 0xbd as u8, 0x47 as u8, 0x41 as u8, 0x7a as u8, 0x81 as u8, 0xa5 as u8, 0x38 as u8, 0x32 as u8, 0x7a as u8, 0xf9 as u8, 0x27 as u8, 0xda as u8, 0x3e as u8]
}

micro abc_bytes() -> [u8] {
    return [97 as u8, 98 as u8, 99 as u8]
}

# 逐字节判等：等长且每位一致。
micro digest_bytes_equal(actual: [u8], expected: [u8]) -> bool {
    let actual_length: usize = std::collection::array::length(actual)
    let expected_length: usize = std::collection::array::length(expected)
    if actual_length != expected_length {
        return false
    }
    let mut index: usize = 0
    while index < expected_length {
        let a: u64 = std::collection::array::get(actual, index) as u64
        let b: u64 = std::collection::array::get(expected, index) as u64
        if a != b {
            return false
        }
        index = index + 1
    }
    return true
}

[test]
micro test_sha256_abc_vector() -> unit {
    if !digest_bytes_equal(digest_sha256(abc_bytes()), sha256_abc_vector()) {
        std::types::panic("sha256(\"abc\") must match the FIPS 180-4 vector")
    }
}

[test]
micro test_sha256_empty_vector() -> unit {
    let empty: [u8] = []
    if !digest_bytes_equal(digest_sha256(empty), sha256_empty_vector()) {
        std::types::panic("sha256(\"\") must match the FIPS 180-4 vector")
    }
}

[test]
micro test_sha256_streaming_matches_oneshot() -> unit {
    let mut state: DigestSha256 = digest_sha256_new()
    state.update([97 as u8])
    state.update([98 as u8, 99 as u8])
    let streamed: [u8] = state.finalize()
    if !digest_bytes_equal(streamed, digest_sha256(abc_bytes())) {
        std::types::panic("sha256 streaming must equal one-shot")
    }
}

[test]
micro test_sha256_streaming_across_blocks() -> unit {
    let mut input: [u8] = []
    let mut index: usize = 0
    while index < 200 {
        input = std::collection::push(input, (index % 256) as u8)
        index = index + 1
    }
    let oneshot: [u8] = digest_sha256(input)
    let mut state: DigestSha256 = digest_sha256_new()
    let mut part: [u8] = []
    index = 0
    while index < 70 {
        part = std::collection::push(part, std::collection::array::get(input, index))
        index = index + 1
    }
    state.update(part)
    part = []
    while index < 140 {
        part = std::collection::push(part, std::collection::array::get(input, index))
        index = index + 1
    }
    state.update(part)
    part = []
    while index < 200 {
        part = std::collection::push(part, std::collection::array::get(input, index))
        index = index + 1
    }
    state.update(part)
    let streamed: [u8] = state.finalize()
    if !digest_bytes_equal(streamed, oneshot) {
        std::types::panic("sha256 streaming across block boundaries must equal one-shot")
    }
}

[test]
micro test_sha256_hex_output() -> unit {
    let hex: [u8] = digest_hex(digest_sha256(abc_bytes()))
    if std::collection::array::length(hex) != 64 {
        std::types::panic("sha256 hex must be 64 ascii bytes")
    }
    # "ba7816bf" 前缀。
    let head: [u8] = [0x62 as u8, 0x61 as u8, 0x37 as u8, 0x38 as u8, 0x31 as u8, 0x36 as u8, 0x62 as u8, 0x66 as u8]
    let mut index: usize = 0
    while index < 8 {
        let a: u64 = std::collection::array::get(hex, index) as u64
        let b: u64 = std::collection::array::get(head, index) as u64
        if a != b {
            std::types::panic("sha256 hex head mismatch")
        }
        index = index + 1
    }
}

[test]
micro test_sha512_abc_vector() -> unit {
    if !digest_bytes_equal(digest_sha512(abc_bytes()), sha512_abc_vector()) {
        std::types::panic("sha512(\"abc\") must match the FIPS 180-4 vector")
    }
}

[test]
micro test_sha512_empty_vector() -> unit {
    let empty: [u8] = []
    if !digest_bytes_equal(digest_sha512(empty), sha512_empty_vector()) {
        std::types::panic("sha512(\"\") must match the FIPS 180-4 vector")
    }
}
