namespace std.data.digest;

# std.data.digest — 摘要层：hash / checksum / integrity 纯函数。
#
# 合同：本层算法是**纯函数、不会失败**，因此不返回 `DataOutcome`、不产生诊断；
# 消费方（codec 封装校验、zip CRC 校验、OCI digest 比对等）自行把"摘要不匹配"
# 翻译为自己的结构化诊断。
#
# 流式合同（同构四个算法族，不另造平行接口）：
#   digest_<alg>_new() -> Digest<Alg>      构造初始状态
#   .update(mut self, bytes: [u8]) -> unit 追加一段输入（可多次）
#   .finalize(self) -> <word>              读出摘要；finalize 后状态不可复用
# 校验和族（crc32/adler32）的 word 是 u32；SHA-2 族的 word 是 [u8]（原始摘要字节）。
# 一次性形态 digest_<alg>(bytes) 全部委托流式三件套，不维护第二套实现。
#
# 常数纪律：多项式、模数、种子、K 表一律用具名零参函数表达（语言暂无顶层常量
# 声明），不散落裸数字；数值是算法自身常数（SHA K 表为前若干素数立方根小数部
# 的高 32/64 位，生成规则属算法定义），非规避写法。
#
# 载道说明（后端缺陷，非语义绕行）：wasm 后端把 `u32 >> n` 错误 lowering 成左旋
# （最小复现：`0x12345678 >> 3` 产出 rol 结果 `0x91A2B3C0` 而非 `0x02468ACF`）。
# 凡含逻辑右移的 32 位算法（crc32、sha256）一律以 u64 载道并显式掩码保持 32 位
# 语义；缺陷修复后可机械改回 u32 载道。

# CRC-32（ISO 3309 / ITU-T V.42 / gzip / zip 同款反射形）。
# 反射形标准多项式（算法固有常数）。
micro crc32_polynomial() -> u64 {
    return 0xEDB88320
}

# 全 1 掩码：初始值与输出取反共用。VM 无按位取反指令，取反以 `^ 全 1` 表达。
micro crc32_all_ones() -> u64 {
    return 0xFFFFFFFF
}

# CRC-32 流式状态：`crc` 是已并入初值、未取反的工作寄存器（u64 载道，值域 < 2^32）。
structure DigestCrc32 {
    crc: u64
}

micro digest_crc32_new() -> DigestCrc32 {
    return DigestCrc32 { crc: crc32_all_ones() }
}

imply DigestCrc32 {
    micro update(mut self, bytes: [u8]) -> unit {
        let length: usize = bytes.length()
        let mut index: usize = 0
        while index < length {
            let byte: u64 = bytes⁅index⁆ as u64
            self.crc = self.crc ^ byte
            let mut bit: usize = 0
            while bit < 8 {
                if (self.crc & 1) == 1 {
                    self.crc = (self.crc >> 1) ^ crc32_polynomial()
                }
                else {
                    self.crc = self.crc >> 1
                }
                bit = bit + 1
            }
            index = index + 1
        }
    }

    micro finalize(self) -> u32 {
        return (self.crc ^ crc32_all_ones()) as u32
    }
}

micro digest_crc32(bytes: [u8]) -> u32 {
    let mut state: DigestCrc32 = digest_crc32_new()
    state.update(bytes)
    return state.finalize()
}

# Adler-32（RFC 1950 zlib 校验）：模数是小于 2^16 的最大素数（算法固有）。
micro adler32_modulus() -> u32 {
    return 65521
}

# Adler-32 流式状态：`a` 为累加和（种子 1），`b` 为 a 的累加和。
structure DigestAdler32 {
    a: u32
    b: u32
}

micro digest_adler32_new() -> DigestAdler32 {
    return DigestAdler32 { a: 1, b: 0 }
}

imply DigestAdler32 {
    micro update(mut self, bytes: [u8]) -> unit {
        let length: usize = bytes.length()
        let mut index: usize = 0
        while index < length {
            let byte: u32 = bytes⁅index⁆ as u32
            self.a = (self.a + byte) % adler32_modulus()
            self.b = (self.b + self.a) % adler32_modulus()
            index = index + 1
        }
    }

    micro finalize(self) -> u32 {
        return (self.b << 16) | self.a
    }
}

micro digest_adler32(bytes: [u8]) -> u32 {
    let mut state: DigestAdler32 = digest_adler32_new()
    state.update(bytes)
    return state.finalize()
}
