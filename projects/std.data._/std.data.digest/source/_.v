namespace std.data.digest;

# std.data.digest — 摘要层：hash / checksum / integrity 纯函数。
#
# 合同：本层算法是**纯函数、不会失败**，因此不返回 `DataOutcome`、不产生诊断；
# 消费方（codec 封装校验、zip CRC 校验等）自行把"摘要不匹配"翻译为自己的
# 结构化诊断。本层不做流式态；整缓冲计算即合同。
#
# 常数纪律：多项式、模数、种子一律用具名零参函数表达（语言暂无顶层常量声明），
# 不散落裸数字；数值是算法自身常数，非规避写法。

# CRC-32（ISO 3309 / ITU-T V.42 / gzip / zip 同款反射形）。
# 反射形标准多项式（算法固有常数）。
micro crc32_polynomial() -> u64 {
    return 0xEDB88320
}

# 全 1 掩码：初始值与输出取反共用。VM 无按位取反指令，取反以 `^ 全 1` 表达。
micro crc32_all_ones() -> u64 {
    return 0xFFFFFFFF
}

# 实现载道说明（后端缺陷，非语义绕行）：crc 状态以 u64 承载而非 u32——
# wasm 后端把 `u32 >> n` 错误 lowering 成左旋（最小复现：`0x12345678 >> 3`
# 产出 rol 结果 `0x91A2B3C0` 而非 `0x02468ACF`），u64 `>>` 行为正确。
# 本算法中 crc 全程不超过 32 位（初值/poly 均 < 2^32，右移只缩不扩），
# 宽载道与 u32 语义逐位一致；缺陷修复后可机械改回 u32 载道。
micro digest_crc32(bytes: [u8]) -> u32 {
    let mut crc: u64 = crc32_all_ones()
    let length: usize = std::collection::array::length(bytes)
    let mut index: usize = 0
    while index < length {
        let byte: u64 = std::collection::array::get(bytes, index) as u64
        crc = crc ^ byte
        let mut bit: usize = 0
        while bit < 8 {
            if (crc & 1) == 1 {
                crc = (crc >> 1) ^ crc32_polynomial()
            }
            else {
                crc = crc >> 1
            }
            bit = bit + 1
        }
        index = index + 1
    }
    return (crc ^ crc32_all_ones()) as u32
}

# Adler-32（RFC 1950 zlib 校验）：模数是小于 2^16 的最大素数（算法固有）。
micro adler32_modulus() -> u32 {
    return 65521
}

micro digest_adler32(bytes: [u8]) -> u32 {
    let mut a: u32 = 1
    let mut b: u32 = 0
    let length: usize = std::collection::array::length(bytes)
    let mut index: usize = 0
    while index < length {
        let byte: u32 = std::collection::array::get(bytes, index) as u32
        a = (a + byte) % adler32_modulus()
        b = (b + a) % adler32_modulus()
        index = index + 1
    }
    return (b << 16) | a
}
