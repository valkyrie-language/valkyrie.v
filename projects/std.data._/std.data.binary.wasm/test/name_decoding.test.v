namespace std.data.binary.wasm;

# 名字解码链行为测试：`wasm_read_bytes` 曾以裸 `push` 丢弃累积结果，
# 静默产出空数组——任何名字都解码为空文本。本套件钉死非空内容与
# 字节序，防止累积合同回退。

[test]
micro test_wasm_read_bytes_returns_all_bytes() -> unit {
    let data: [i32] = [10, 20, 30, 40, 50]
    match wasm_read_bytes(data, 1, 3) {
        case Fine(decoded):
            let got: [i32] = decoded.value
            if got.length() != 3 {
                panic("wasm_read_bytes 必须返回全部请求字节，不得静默产出空数组")
            }
            if got[0] != 20 || got[1] != 30 || got[2] != 40 {
                panic("wasm_read_bytes 字节内容或顺序不符")
            }
            if decoded.consumed != 3 {
                panic("wasm_read_bytes 消费计数不符")
            }
        case Fail(error):
            panic("合法区间读取不应失败")
    }
}

[test]
micro test_wasm_read_name_ascii() -> unit {
    # uleb128 长度 3 + "a b" 的 UTF-8 字节。
    let data: [i32] = [3, 97, 32, 98]
    match wasm_read_name(data, 0) {
        case Fine(decoded):
            if decoded.value.length() != 3 {
                panic("ascii 名字必须解码为 3 码点")
            }
            if decoded.value != "a b" {
                panic("ascii 名字内容不符")
            }
            if decoded.consumed != 4 {
                panic("名字解码必须消费长度前缀与全部字节")
            }
        case Fail(error):
            panic("合法 ascii 名字不应失败")
    }
}

[test]
micro test_wasm_read_name_utf8_multibyte() -> unit {
    # uleb128 长度 6 + 「模块」的 UTF-8 字节（E6 A8 A1 / E5 9D 97）。
    let data: [i32] = [6, 230, 168, 161, 229, 157, 151]
    match wasm_read_name(data, 0) {
        case Fine(decoded):
            if decoded.value.length() != 2 {
                panic("中文名字必须解码为 2 码点而非空文本")
            }
            if decoded.value != "模块" {
                panic("中文名字内容不符")
            }
        case Fail(error):
            panic("合法 UTF-8 名字不应失败")
    }
}

[test]
micro test_wasm_read_name_invalid_utf8_fails() -> unit {
    # 长度 1 + 孤立续字节 0x80：必须结构化失败，不得静默产出空名。
    let data: [i32] = [1, 128]
    match wasm_read_name(data, 0) {
        case Fine(decoded):
            panic("非法 UTF-8 名字必须失败")
        case Fail(error):
            return
    }
}

[test]
micro test_wasm_name_encode_decode_roundtrip() -> unit {
    let names: [utf8] = ["", "a", "add", "模块", "👍", "x::y/z#w@1"]
    let mut index: usize = 0
    while index < names.length() {
        let name: utf8 = names[index]
        let encoded: [i32] = wasm_encode_name(name)
        match wasm_read_name(encoded, 0) {
            case Fine(decoded):
                if decoded.value != name {
                    panic("名字编解码往返必须一致")
                }
                if decoded.consumed != encoded.length() {
                    panic("往返必须消费全部编码字节")
                }
            case Fail(error):
                panic("自身编码必须可解码")
        }
        index = index + 1
    }
}
