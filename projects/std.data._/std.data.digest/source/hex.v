namespace std.data.digest;

# 摘要的十六进制输出（小写，OCI digest 文法 sha256=64 hex、sha512=128 hex 同源）。
# 纯计算、无诊断：输入是字节，输出是小写 ASCII hex 字节流；utf8 文本形态由
# `digest_hex_text` 给出——hex 字符全部落在 ASCII（< 0x80），构造即良构，
# 走 `from_bytes_unchecked` 并在此写明不变量。

# 半字节 -> 小写 hex 字符（'0'..'9' 与 'a'..'f'）。
micro digest_hex_digit(nibble: u64) -> u8 {
    if nibble < 10 {
        return b'0' + nibble as u8
    }
    return b'a' + (nibble - 10) as u8
}

micro digest_hex(bytes: [u8]) -> [u8] {
    let mut out: [u8] = []
    let length: usize = bytes.length()
    let mut index: usize = 0
    while index < length {
        let byte: u64 = bytes⁅index⁆ as u64
        out = out.push(digest_hex_digit(byte >> 4))
        out = out.push(digest_hex_digit(byte & 15))
        index = index + 1
    }
    return out
}

micro digest_hex_text(bytes: [u8]) -> utf8 {
    return std::text::Utf8Text::from_bytes_unchecked(digest_hex(bytes))
}
