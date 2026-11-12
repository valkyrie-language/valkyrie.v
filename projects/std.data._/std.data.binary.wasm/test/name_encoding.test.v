namespace std.data.binary.wasm;

# 名字编码合同：LEB128 字节长度 + 原样 UTF-8 字节序列。
# 不设字符白名单——中文、emoji 与曾落入 '?' 兜底的 ASCII（如空格）都必须
# 逐字节保留，长度按字节计而非按码点计。

micro wasm_name_bytes_equal(actual: [i32], expected: [i32]) -> bool {
    if actual.length() != expected.length() {
        return false
    }
    let mut index: usize = 0
    while index < expected.length() {
        if actual⁅index⁆ != expected⁅index⁆ {
            return false
        }
        index = index + 1
    }
    return true
}

[test]
micro test_wasm_encode_name_ascii_passthrough() -> unit {
    # 空格曾被兜底替换为 63（'?'）：必须原样保留。
    let encoded: [i32] = wasm_encode_name("a b")
    let expected: [i32] = [3, 97, 32, 98]
    if !wasm_name_bytes_equal(encoded, expected) {
        panic("ASCII 名字必须原样编码，空格不得被替换")
    }
}

[test]
micro test_wasm_encode_name_utf8_bytes_and_byte_length() -> unit {
    # 「模块」U+6A21 U+5757 → E6 A8 A1 / E5 9D 97：长度前缀是 6 字节而非 2 码点。
    let encoded: [i32] = wasm_encode_name("模块")
    let expected: [i32] = [6, 230, 168, 161, 229, 157, 151]
    if !wasm_name_bytes_equal(encoded, expected) {
        panic("中文名字必须按 UTF-8 字节编码并以字节数计长度")
    }
}

[test]
micro test_wasm_encode_name_emoji_passthrough() -> unit {
    # 👍 U+1F44D → F0 9F 91 8D。
    let encoded: [i32] = wasm_encode_name("👍")
    let expected: [i32] = [4, 240, 159, 145, 141]
    if !wasm_name_bytes_equal(encoded, expected) {
        panic("emoji 名字必须原样编码")
    }
}

[test]
micro test_wasm_encode_name_empty_is_zero_length() -> unit {
    let encoded: [i32] = wasm_encode_name("")
    let expected: [i32] = [0]
    if !wasm_name_bytes_equal(encoded, expected) {
        panic("空名字必须编码为单个零长度前缀")
    }
}
