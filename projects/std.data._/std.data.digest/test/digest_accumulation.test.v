namespace std.data.digest;

# 累计长度数值域合同：摘要比特长度在算法规定的 u64 域内累计，与 update 的
# 切分方式无关。32 位目标上 usize 只有 32 位——旧实现以 usize 记字节数、
# finalize 先乘 8 再转 u64，512 MiB 流即回绕。流式等价性测试锁定
# 「切分不改变累计长度」这一事实；地址与单次缓冲长度仍按 usize 承载。

micro accumulation_input() -> [u8] {
    let mut out: [u8] = []
    let mut index: usize = 0
    while index < 1000 {
        out = out.push((index % 251) as u8)
        index = index + 1
    }
    return out
}

[test]
micro test_sha256_per_byte_updates_match_oneshot() -> unit {
    let input: [u8] = accumulation_input()
    let mut state: DigestSha256 = digest_sha256_new()
    let mut index: usize = 0
    while index < input.length() {
        state.update([input⁅index⁆])
        index = index + 1
    }
    if !digest_bytes_equal(state.finalize(), digest_sha256(input)) {
        std::types::panic("sha256 per-byte streaming must equal one-shot")
    }
}

[test]
micro test_sha512_streaming_matches_oneshot() -> unit {
    let input: [u8] = accumulation_input()
    let oneshot: [u8] = digest_sha512(input)
    let mut state: DigestSha512 = digest_sha512_new()
    let mut first: [u8] = []
    let mut index: usize = 0
    while index < 129 {
        first = first.push(input⁅index⁆)
        index = index + 1
    }
    state.update(first)
    let mut rest: [u8] = []
    while index < input.length() {
        rest = rest.push(input⁅index⁆)
        index = index + 1
    }
    state.update(rest)
    if !digest_bytes_equal(state.finalize(), oneshot) {
        std::types::panic("sha512 streaming must equal one-shot")
    }
}

[test]
micro test_sha512_per_byte_updates_match_oneshot() -> unit {
    let input: [u8] = accumulation_input()
    let mut state: DigestSha512 = digest_sha512_new()
    let mut index: usize = 0
    while index < input.length() {
        state.update([input⁅index⁆])
        index = index + 1
    }
    if !digest_bytes_equal(state.finalize(), digest_sha512(input)) {
        std::types::panic("sha512 per-byte streaming must equal one-shot")
    }
}
