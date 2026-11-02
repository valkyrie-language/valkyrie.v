namespace std.data.digest;

# 已知答案测试（KAT）：zlib 参考向量 "123456789"（ASCII 字节 49..57）。
# CRC-32 = 0xCBF43926、Adler-32 = 0x091E01DE。
#
# 阻塞说明：断言依赖 `std::types::panic`，而 `raise` 终止子在各后端尚无目标
# 合同（编译期结构化失败"canonical effect terminator 尚无目标合同"）。
# 最小复现：`valkyrie.v/examples/scratch-neq-probe` 的 raise 探针。
# 本套件的运行时证据当前由 `valkyrie.v/examples/std-data-drive`（node 断言
# 返回值）提供，该驱动器已于 wasm lane 全绿。
#
# 字面量纪律：大于 i32 上限的十六进制期望值先绑定到显式 u32 局部变量再比较，
# 裸字面量在表达式中默认 i64、不会向 u32 归一。

# "123456789" 的字节序列。
micro kat_input() -> [u8] {
    return [49 as u8, 50 as u8, 51 as u8, 52 as u8, 53 as u8, 54 as u8, 55 as u8, 56 as u8, 57 as u8]
}

[test]
micro test_crc32_known_answer() -> unit {
    let expected: u32 = 0xCBF43926
    let actual: u32 = digest_crc32(kat_input())
    if actual != expected {
        std::types::panic("crc32 known answer mismatch")
    }
}

[test]
micro test_crc32_empty_is_zero() -> unit {
    let empty: [u8] = []
    let expected: u32 = 0
    if digest_crc32(empty) != expected {
        std::types::panic("crc32 of empty input must be 0")
    }
}

[test]
micro test_crc32_sensitive_to_single_bit() -> unit {
    let flipped: [u8] = [48 as u8, 50 as u8, 51 as u8, 52 as u8, 53 as u8, 54 as u8, 55 as u8, 56 as u8, 57 as u8]
    if digest_crc32(kat_input()) == digest_crc32(flipped) {
        std::types::panic("crc32 must differ after single-bit flip")
    }
}

[test]
micro test_adler32_known_answer() -> unit {
    let expected: u32 = 0x091E01DE
    let actual: u32 = digest_adler32(kat_input())
    if actual != expected {
        std::types::panic("adler32 known answer mismatch")
    }
}

[test]
micro test_adler32_empty_is_one() -> unit {
    let empty: [u8] = []
    let expected: u32 = 1
    if digest_adler32(empty) != expected {
        std::types::panic("adler32 of empty input must be 1")
    }
}

[test]
micro test_adler32_sensitive_to_order() -> unit {
    let swapped: [u8] = [50 as u8, 49 as u8, 51 as u8, 52 as u8, 53 as u8, 54 as u8, 55 as u8, 56 as u8, 57 as u8]
    if digest_adler32(kat_input()) == digest_adler32(swapped) {
        std::types::panic("adler32 must differ when byte order changes")
    }
}
