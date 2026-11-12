namespace std.data.binary.wasm;

# SLEB128 有符号解码合同：符号位是末组 bit 6（不是 bit 5）；第 5 组只允许
# 符号扩展位，越界与截断编码结构化失败。含账本点名的两组向量：
# [0x20] → 32、[0x40] → -64。

micro leb128_signed_expect(data: [i32], expected: i32) -> unit {
    match leb128_decode_i32(data, 0) {
        case Fine(decoded):
            if decoded.value != expected {
                panic("SLEB128 有符号解码值不符")
            }
            if decoded.consumed != data.length() {
                panic("SLEB128 有符号解码消费长度不符")
            }
        case Fail(error):
            panic("合法 SLEB128 编码不应失败")
    }
}

micro leb128_signed_is_fail(data: [i32]) -> bool {
    match leb128_decode_i32(data, 0) {
        case Fine(decoded):
            return false
        case Fail(error):
            return true
    }
}

[test]
micro test_leb128_signed_ledger_vectors() -> unit {
    leb128_signed_expect([0x20], 32)
    leb128_signed_expect([0x40], -64)
}

[test]
micro test_leb128_signed_single_byte_boundaries() -> unit {
    leb128_signed_expect([0x00], 0)
    leb128_signed_expect([0x01], 1)
    leb128_signed_expect([0x3F], 63)
    leb128_signed_expect([0x41], -63)
    leb128_signed_expect([0x7F], -1)
}

[test]
micro test_leb128_signed_multi_byte_and_extremes() -> unit {
    let i32_max: i32 = 2147483647
    let i32_min: i32 = 0 - 2147483647 - 1
    leb128_signed_expect([0xE0, 0x00], 96)
    leb128_signed_expect([0x80, 0x7F], -128)
    leb128_signed_expect([0x81, 0x7F], -127)
    leb128_signed_expect([0x80, 0x40], -8192)
    leb128_signed_expect([0xFF, 0xFF, 0xFF, 0xFF, 0x07], i32_max)
    leb128_signed_expect([0x80, 0x80, 0x80, 0x80, 0x78], i32_min)
}

[test]
micro test_leb128_signed_last_group_limits() -> unit {
    # 第 5 组 bit3=1 而 bit 4..6 全 0：值越过 i32 上界，必须拒收。
    if !leb128_signed_is_fail([0x80, 0x80, 0x80, 0x80, 0x08]) {
        panic("第 5 组符号扩展位混合必须拒收")
    }
    # 第 5 组 bit3=0 而高位有 1：同样越界。
    if !leb128_signed_is_fail([0x80, 0x80, 0x80, 0x80, 0x77]) {
        panic("第 5 组符号扩展位混合必须拒收")
    }
    # 第 6 组越过 i32 的 5 组预算。
    if !leb128_signed_is_fail([0x80, 0x80, 0x80, 0x80, 0x80, 0x00]) {
        panic("超过 5 组必须拒收")
    }
    # 截断编码（续位后无末组）必须拒收。
    if !leb128_signed_is_fail([0x80]) {
        panic("截断编码必须拒收")
    }
    let empty: [i32] = []
    if !leb128_signed_is_fail(empty) {
        panic("空输入必须拒收")
    }
}

[test]
micro test_leb128_signed_non_minimal_matches_unsigned_contract() -> unit {
    # 与 unsigned 分支合同一致：非最简但值域内的编码接受。
    leb128_signed_expect([0x80, 0x00], 0)
    leb128_signed_expect([0xFF, 0x7F], -1)
    leb128_signed_expect([0x80, 0x80, 0x80, 0x80, 0x7F], -268435456)
}

[test]
micro test_leb128_signed_encode_decode_roundtrip() -> unit {
    let i32_max: i32 = 2147483647
    let i32_min: i32 = 0 - 2147483647 - 1
    let values: [i32] = [0, 1, -1, 63, 64, -64, 32, 96, -128, 127, -127, 8191, -8192, 12345678, -87654321, i32_max, i32_min]
    let mut index: usize = 0
    while index < values.length() {
        let value: i32 = values⁅index⁆
        let encoded: [i32] = wasm_encode_sleb128_i32(value)
        match leb128_decode_i32(encoded, 0) {
            case Fine(decoded):
                if decoded.value != value {
                    panic("SLEB128 编解码往返不一致")
                }
                if decoded.consumed != encoded.length() {
                    panic("SLEB128 往返必须消费全部编码字节")
                }
            case Fail(error):
                panic("自身编码必须可解码")
        }
        index = index + 1
    }
}
