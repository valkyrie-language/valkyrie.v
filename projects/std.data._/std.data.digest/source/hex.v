namespace std.data.digest;

# 摘要的十六进制输出（小写，OCI digest 文法 sha256=64 hex、sha512=128 hex 同源）。
# 纯计算、无诊断：输入是字节，输出是小写 ASCII hex 字节流；utf8 文本形态由
# `digest_hex_text` 经 `Utf8Text::from_bytes` 包装给出。

# 半字节 -> 小写 hex 字符（'0'..'9' = 48+x，'a'..'f' = 87+x）。
micro digest_hex_digit(nibble: u64) -> u8 {
    if nibble < 10 {
        return (48 + nibble) as u8
    }
    return (87 + nibble) as u8
}

micro digest_hex(bytes: [u8]) -> [u8] {
    let mut out: [u8] = []
    let length: usize = std::collection::array::length(bytes)
    let mut index: usize = 0
    while index < length {
        let byte: u64 = std::collection::array::get(bytes, index) as u64
        out = std::collection::push(out, digest_hex_digit(byte >> 4))
        out = std::collection::push(out, digest_hex_digit(byte & 15))
        index = index + 1
    }
    return out
}

micro digest_hex_text(bytes: [u8]) -> utf8 {
    return std::text::Utf8Text::from_bytes(digest_hex(bytes))
}
