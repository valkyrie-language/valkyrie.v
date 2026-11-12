namespace std.data.digest;

# SHA-512（FIPS 180-4）。纯计算、无 host 依赖。
# 64 位字以 u64 原生承载：加法回绕即算法语义的 mod 2^64，右移/旋转移位
# 都是 u64 上的逻辑位移。
#
# 块内布局：消息按 128 字节分块；`pending` 存未满一块的尾巴，`total` 记总字节数
# （finalize 时换算成比特长度写尾，高 64 位恒 0）。

# 初始哈希值：前 8 个素数平方根小数部的高 64 位（算法固有常数）。
micro sha512_initial() -> [u64] {
    return [
        0x6a09e667f3bcc908 as u64, 0xbb67ae8584caa73b as u64,
        0x3c6ef372fe94f82b as u64, 0xa54ff53a5f1d36f1 as u64,
        0x510e527fade682d1 as u64, 0x9b05688c2b3e6c1f as u64,
        0x1f83d9abfb41bd6b as u64, 0x5be0cd19137e2179 as u64,
    ]
}

# 轮常数：前 80 个素数立方根小数部的高 64 位（算法固有常数），数组字面量直写。
micro sha512_round_constants() -> [u64] {
    return [
        0x428a2f98d728ae22 as u64, 0x7137449123ef65cd as u64, 0xb5c0fbcfec4d3b2f as u64, 0xe9b5dba58189dbbc as u64,
        0x3956c25bf348b538 as u64, 0x59f111f1b605d019 as u64, 0x923f82a4af194f9b as u64, 0xab1c5ed5da6d8118 as u64,
        0xd807aa98a3030242 as u64, 0x12835b0145706fbe as u64, 0x243185be4ee4b28c as u64, 0x550c7dc3d5ffb4e2 as u64,
        0x72be5d74f27b896f as u64, 0x80deb1fe3b1696b1 as u64, 0x9bdc06a725c71235 as u64, 0xc19bf174cf692694 as u64,
        0xe49b69c19ef14ad2 as u64, 0xefbe4786384f25e3 as u64, 0x0fc19dc68b8cd5b5 as u64, 0x240ca1cc77ac9c65 as u64,
        0x2de92c6f592b0275 as u64, 0x4a7484aa6ea6e483 as u64, 0x5cb0a9dcbd41fbd4 as u64, 0x76f988da831153b5 as u64,
        0x983e5152ee66dfab as u64, 0xa831c66d2db43210 as u64, 0xb00327c898fb213f as u64, 0xbf597fc7beef0ee4 as u64,
        0xc6e00bf33da88fc2 as u64, 0xd5a79147930aa725 as u64, 0x06ca6351e003826f as u64, 0x142929670a0e6e70 as u64,
        0x27b70a8546d22ffc as u64, 0x2e1b21385c26c926 as u64, 0x4d2c6dfc5ac42aed as u64, 0x53380d139d95b3df as u64,
        0x650a73548baf63de as u64, 0x766a0abb3c77b2a8 as u64, 0x81c2c92e47edaee6 as u64, 0x92722c851482353b as u64,
        0xa2bfe8a14cf10364 as u64, 0xa81a664bbc423001 as u64, 0xc24b8b70d0f89791 as u64, 0xc76c51a30654be30 as u64,
        0xd192e819d6ef5218 as u64, 0xd69906245565a910 as u64, 0xf40e35855771202a as u64, 0x106aa07032bbd1b8 as u64,
        0x19a4c116b8d2d0c8 as u64, 0x1e376c085141ab53 as u64, 0x2748774cdf8eeb99 as u64, 0x34b0bcb5e19b48a8 as u64,
        0x391c0cb3c5c95a63 as u64, 0x4ed8aa4ae3418acb as u64, 0x5b9cca4f7763e373 as u64, 0x682e6ff3d6b2b8a3 as u64,
        0x748f82ee5defb2fc as u64, 0x78a5636f43172f60 as u64, 0x84c87814a1f0ab72 as u64, 0x8cc702081a6439ec as u64,
        0x90befffa23631e28 as u64, 0xa4506cebde82bde9 as u64, 0xbef9a3f7b2c67915 as u64, 0xc67178f2e372532b as u64,
        0xca273eceea26619c as u64, 0xd186b8c721c0c207 as u64, 0xeada7dd6cde0eb1e as u64, 0xf57d4f7fee6ed178 as u64,
        0x06f067aa72176fba as u64, 0x0a637dc5a2c898a6 as u64, 0x113f9804bef90dae as u64, 0x1b710b35131c471b as u64,
        0x28db77f523047d84 as u64, 0x32caab7b40c72493 as u64, 0x3c9ebe0a15c9bebc as u64, 0x431d67c49c100d4c as u64,
        0x4cc5d4becb3e42b6 as u64, 0x597f299cfc657e2a as u64, 0x5fcb6fab3ad6faec as u64, 0x6c44198c4a475817 as u64,
    ]
}

# 64 位循环右移。
micro sha512_rotr(x: u64, n: u64) -> u64 {
    return (x >> n) | (x << (64 - n))
}

micro sha512_big_sigma0(x: u64) -> u64 {
    return sha512_rotr(x, 28) ^ sha512_rotr(x, 34) ^ sha512_rotr(x, 39)
}

micro sha512_big_sigma1(x: u64) -> u64 {
    return sha512_rotr(x, 14) ^ sha512_rotr(x, 18) ^ sha512_rotr(x, 41)
}

micro sha512_small_sigma0(x: u64) -> u64 {
    return sha512_rotr(x, 1) ^ sha512_rotr(x, 8) ^ (x >> 7)
}

micro sha512_small_sigma1(x: u64) -> u64 {
    return sha512_rotr(x, 19) ^ sha512_rotr(x, 61) ^ (x >> 6)
}

# Ch(e, f, g) = (e ∧ f) ⊕ (¬e ∧ g)。
micro sha512_ch(e: u64, f: u64, g: u64) -> u64 {
    return (e & f) ^ (e.bit_not() & g)
}

# Maj(a, b, c) = (a ∧ b) ⊕ (a ∧ c) ⊕ (b ∧ c)。
micro sha512_maj(a: u64, b: u64, c: u64) -> u64 {
    return (a & b) ^ (a & c) ^ (b & c)
}

# SHA-512 流式状态：`lanes` 是 8 个 64 位工作变量，`pending` 是未满一块的
# 尾字节，`total` 是已接收总字节数。
structure DigestSha512 {
    lanes: [u64]
    pending: [u8]
    total: usize
}

micro digest_sha512_new() -> DigestSha512 {
    return DigestSha512 { lanes: sha512_initial(), pending: [], total: 0 }
}

# 处理一个 128 字节块（block 恰为 128 字节由调用点保证）。
micro sha512_compress(mut lanes: [u64], block: [u8]) -> [u64] {
    let round_constants: [u64] = sha512_round_constants()
    let mut w: [u64] = []
    let mut fill: usize = 0
    while fill < 80 {
        w = w.push(0 as u64)
        fill = fill + 1
    }
    let mut t: usize = 0
    while t < 16 {
        let base: usize = t * 8
        let b0: u64 = block⁅base⁆ as u64
        let b1: u64 = block⁅base + 1⁆ as u64
        let b2: u64 = block⁅base + 2⁆ as u64
        let b3: u64 = block⁅base + 3⁆ as u64
        let b4: u64 = block⁅base + 4⁆ as u64
        let b5: u64 = block⁅base + 5⁆ as u64
        let b6: u64 = block⁅base + 6⁆ as u64
        let b7: u64 = block⁅base + 7⁆ as u64
        let word: u64 = (b0 << 56) | (b1 << 48) | (b2 << 40) | (b3 << 32) | (b4 << 24) | (b5 << 16) | (b6 << 8) | b7
        w⁅t⁆ = word
        t = t + 1
    }
    while t < 80 {
        let word: u64 = sha512_small_sigma1(w⁅t - 2⁆)
            + w⁅t - 7⁆
            + sha512_small_sigma0(w⁅t - 15⁆)
            + w⁅t - 16⁆
        w⁅t⁆ = word
        t = t + 1
    }

    let mut a: u64 = lanes⁅0⁆
    let mut b: u64 = lanes⁅1⁆
    let mut c: u64 = lanes⁅2⁆
    let mut d: u64 = lanes⁅3⁆
    let mut e: u64 = lanes⁅4⁆
    let mut f: u64 = lanes⁅5⁆
    let mut g: u64 = lanes⁅6⁆
    let mut h: u64 = lanes⁅7⁆

    t = 0
    while t < 80 {
        let t1: u64 = h + sha512_big_sigma1(e) + sha512_ch(e, f, g)
            + round_constants⁅t⁆
            + w⁅t⁆
        let t2: u64 = sha512_big_sigma0(a) + sha512_maj(a, b, c)
        h = g
        g = f
        f = e
        e = d + t1
        d = c
        c = b
        b = a
        a = t1 + t2
        t = t + 1
    }

    lanes⁅0⁆ = a + lanes⁅0⁆
    lanes⁅1⁆ = b + lanes⁅1⁆
    lanes⁅2⁆ = c + lanes⁅2⁆
    lanes⁅3⁆ = d + lanes⁅3⁆
    lanes⁅4⁆ = e + lanes⁅4⁆
    lanes⁅5⁆ = f + lanes⁅5⁆
    lanes⁅6⁆ = g + lanes⁅6⁆
    lanes⁅7⁆ = h + lanes⁅7⁆
    return lanes
}

# 从 pending 头部摘出恰好一个 128 字节块，返回剩余 pending。
micro sha512_take_block(pending: [u8]) -> [u8] {
    let mut rest: [u8] = []
    let length: usize = pending.length()
    let mut index: usize = 128
    while index < length {
        rest = rest.push(pending⁅index⁆)
        index = index + 1
    }
    return rest
}

# 取 pending 前 128 字节为块（调用点保证 length >= 128）。
micro sha512_head_block(pending: [u8]) -> [u8] {
    let mut block: [u8] = []
    let mut index: usize = 0
    while index < 128 {
        block = block.push(pending⁅index⁆)
        index = index + 1
    }
    return block
}

imply DigestSha512 {
    micro update(mut self, bytes: [u8]) -> unit {
        let length: usize = bytes.length()
        let mut index: usize = 0
        while index < length {
            self.pending = self.pending.push(bytes⁅index⁆)
            index = index + 1
        }
        self.total = self.total + length
        while self.pending.length() >= 128 {
            self.lanes = sha512_compress(self.lanes, sha512_head_block(self.pending))
            self.pending = sha512_take_block(self.pending)
        }
    }

    # 读出 64 字节原始摘要。填充：0x80、清零至距块尾 16 字节、128 位大端比特
    # 长度（高 64 位恒 0，低 64 位为 total*8）。
    micro finalize(mut self) -> [u8] {
        let bit_length: u64 = (self.total * 8) as u64
        self.pending = self.pending.push(0x80 as u8)
        while self.pending.length() % 128 != 112 {
            self.pending = self.pending.push(0 as u8)
        }
        let mut shift: usize = 0
        while shift < 8 {
            self.pending = self.pending.push(0 as u8)
            shift = shift + 1
        }
        shift = 0
        while shift < 8 {
            let lane: u64 = (bit_length >> (((7 - shift) * 8) as u64)) & 0xFF
            self.pending = self.pending.push(lane as u8)
            shift = shift + 1
        }
        while self.pending.length() >= 128 {
            self.lanes = sha512_compress(self.lanes, sha512_head_block(self.pending))
            self.pending = sha512_take_block(self.pending)
        }

        let mut out: [u8] = []
        let mut lane_index: usize = 0
        while lane_index < 8 {
            let word: u64 = self.lanes⁅lane_index⁆
            let mut byte_index: usize = 0
            while byte_index < 8 {
                let byte: u64 = (word >> (((7 - byte_index) * 8) as u64)) & 0xFF
                out = out.push(byte as u8)
                byte_index = byte_index + 1
            }
            lane_index = lane_index + 1
        }
        return out
    }
}

micro digest_sha512(bytes: [u8]) -> [u8] {
    let mut state: DigestSha512 = digest_sha512_new()
    state.update(bytes)
    return state.finalize()
}
