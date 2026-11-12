namespace std.data.digest;

# SHA-256（FIPS 180-4）。纯计算、无 host 依赖。
#
# 32 位字以 u32 原生承载：加法回绕、逻辑右移、循环右移都是 mod 2^32 语义，
# 与 FIPS 180-4 的字定义一致。
#
# 块内布局：消息按 64 字节分块；`pending` 存未满一块的尾巴，`total_bits` 以
# 算法规定的 64 位数值域累计比特长度（finalize 直接写尾；地址与单次缓冲长度
# 才用 usize，32 位目标上 usize 承载不了累计长度，先乘 8 会回绕）。
# w 调度、K 表、H 初值均为算法固有常数。

# 初始哈希值：前 8 个素数平方根小数部的高 32 位（算法固有常数）。
micro sha256_initial() -> [u32] {
    return [
        0x6a09e667 as u32, 0xbb67ae85 as u32, 0x3c6ef372 as u32, 0xa54ff53a as u32,
        0x510e527f as u32, 0x9b05688c as u32, 0x1f83d9ab as u32, 0x5be0cd19 as u32,
    ]
}

# 轮常数：前 64 个素数立方根小数部的高 32 位（算法固有常数）。
micro sha256_round_constants() -> [u32] {
    return [
        0x428a2f98 as u32, 0x71374491 as u32, 0xb5c0fbcf as u32, 0xe9b5dba5 as u32, 0x3956c25b as u32, 0x59f111f1 as u32, 0x923f82a4 as u32, 0xab1c5ed5 as u32,
        0xd807aa98 as u32, 0x12835b01 as u32, 0x243185be as u32, 0x550c7dc3 as u32, 0x72be5d74 as u32, 0x80deb1fe as u32, 0x9bdc06a7 as u32, 0xc19bf174 as u32,
        0xe49b69c1 as u32, 0xefbe4786 as u32, 0x0fc19dc6 as u32, 0x240ca1cc as u32, 0x2de92c6f as u32, 0x4a7484aa as u32, 0x5cb0a9dc as u32, 0x76f988da as u32,
        0x983e5152 as u32, 0xa831c66d as u32, 0xb00327c8 as u32, 0xbf597fc7 as u32, 0xc6e00bf3 as u32, 0xd5a79147 as u32, 0x06ca6351 as u32, 0x14292967 as u32,
        0x27b70a85 as u32, 0x2e1b2138 as u32, 0x4d2c6dfc as u32, 0x53380d13 as u32, 0x650a7354 as u32, 0x766a0abb as u32, 0x81c2c92e as u32, 0x92722c85 as u32,
        0xa2bfe8a1 as u32, 0xa81a664b as u32, 0xc24b8b70 as u32, 0xc76c51a3 as u32, 0xd192e819 as u32, 0xd6990624 as u32, 0xf40e3585 as u32, 0x106aa070 as u32,
        0x19a4c116 as u32, 0x1e376c08 as u32, 0x2748774c as u32, 0x34b0bcb5 as u32, 0x391c0cb3 as u32, 0x4ed8aa4a as u32, 0x5b9cca4f as u32, 0x682e6ff3 as u32,
        0x748f82ee as u32, 0x78a5636f as u32, 0x84c87814 as u32, 0x8cc70208 as u32, 0x90befffa as u32, 0xa4506ceb as u32, 0xbef9a3f7 as u32, 0xc67178f2 as u32,
    ]
}

# 32 位循环右移。
micro sha256_rotr(x: u32, n: u32) -> u32 {
    return (x >> n) | (x << (32 - n))
}

micro sha256_big_sigma0(x: u32) -> u32 {
    return sha256_rotr(x, 2) ^ sha256_rotr(x, 13) ^ sha256_rotr(x, 22)
}

micro sha256_big_sigma1(x: u32) -> u32 {
    return sha256_rotr(x, 6) ^ sha256_rotr(x, 11) ^ sha256_rotr(x, 25)
}

micro sha256_small_sigma0(x: u32) -> u32 {
    return sha256_rotr(x, 7) ^ sha256_rotr(x, 18) ^ (x >> 3)
}

micro sha256_small_sigma1(x: u32) -> u32 {
    return sha256_rotr(x, 17) ^ sha256_rotr(x, 19) ^ (x >> 10)
}

# Ch(e, f, g) = (e ∧ f) ⊕ (¬e ∧ g)。
micro sha256_ch(e: u32, f: u32, g: u32) -> u32 {
    return (e & f) ^ (e.bit_not() & g)
}

# Maj(a, b, c) = (a ∧ b) ⊕ (a ∧ c) ⊕ (b ∧ c)。
micro sha256_maj(a: u32, b: u32, c: u32) -> u32 {
    return (a & b) ^ (a & c) ^ (b & c)
}

# SHA-256 流式状态：`lanes` 是 8 个 32 位工作变量，`pending` 是未满一块的
# 尾字节，`total_bits` 是已接收输入的累计比特长度（算法规定的 u64 数值域，
# 与指针位宽无关）。
structure DigestSha256 {
    lanes: [u32]
    pending: [u8]
    total_bits: u64
}

micro digest_sha256_new() -> DigestSha256 {
    return DigestSha256 { lanes: sha256_initial(), pending: [], total_bits: 0 }
}

# 处理一个 64 字节块（block 恰为 64 字节由调用点保证）。
micro sha256_compress(mut lanes: [u32], block: [u8]) -> [u32] {
    let round_constants: [u32] = sha256_round_constants()
    let mut w: [u32] = []
    let mut fill: usize = 0
    while fill < 64 {
        w = w.push(0 as u32)
        fill = fill + 1
    }
    let mut t: usize = 0
    while t < 16 {
        let base: usize = t * 4
        let b0: u32 = block⁅base⁆ as u32
        let b1: u32 = block⁅base + 1⁆ as u32
        let b2: u32 = block⁅base + 2⁆ as u32
        let b3: u32 = block⁅base + 3⁆ as u32
        w⁅t⁆ = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
        t = t + 1
    }
    while t < 64 {
        let word: u32 = sha256_small_sigma1(w⁅t - 2⁆)
            + w⁅t - 7⁆
            + sha256_small_sigma0(w⁅t - 15⁆)
            + w⁅t - 16⁆
        w⁅t⁆ = word
        t = t + 1
    }

    let mut a: u32 = lanes⁅0⁆
    let mut b: u32 = lanes⁅1⁆
    let mut c: u32 = lanes⁅2⁆
    let mut d: u32 = lanes⁅3⁆
    let mut e: u32 = lanes⁅4⁆
    let mut f: u32 = lanes⁅5⁆
    let mut g: u32 = lanes⁅6⁆
    let mut h: u32 = lanes⁅7⁆

    t = 0
    while t < 64 {
        let t1: u32 = h + sha256_big_sigma1(e) + sha256_ch(e, f, g)
            + round_constants⁅t⁆
            + w⁅t⁆
        let t2: u32 = sha256_big_sigma0(a) + sha256_maj(a, b, c)
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

# 从 pending 头部摘出恰好一个 64 字节块，返回剩余 pending。
micro sha256_take_block(mut pending: [u8]) -> [u8] {
    let mut rest: [u8] = []
    let length: usize = pending.length()
    let mut index: usize = 64
    while index < length {
        rest = rest.push(pending⁅index⁆)
        index = index + 1
    }
    return rest
}

# 取 pending 前 64 字节为块（调用点保证 length >= 64）。
micro sha256_head_block(pending: [u8]) -> [u8] {
    let mut block: [u8] = []
    let mut index: usize = 0
    while index < 64 {
        block = block.push(pending⁅index⁆)
        index = index + 1
    }
    return block
}

imply DigestSha256 {
    micro update(mut self, bytes: [u8]) -> unit {
        let length: usize = bytes.length()
        let mut index: usize = 0
        while index < length {
            self.pending = self.pending.push(bytes⁅index⁆)
            index = index + 1
        }
        self.total_bits = self.total_bits + (length as u64) * 8
        while self.pending.length() >= 64 {
            self.lanes = sha256_compress(self.lanes, sha256_head_block(self.pending))
            self.pending = sha256_take_block(self.pending)
        }
    }

    # 读出 32 字节原始摘要。填充：0x80、清零至距块尾 8 字节、大端 64 位比特长度。
    micro finalize(mut self) -> [u8] {
        let bit_length: u64 = self.total_bits
        self.pending = self.pending.push(0x80 as u8)
        while self.pending.length() % 64 != 56 {
            self.pending = self.pending.push(0 as u8)
        }
        let mut shift: usize = 0
        while shift < 8 {
            let lane: u64 = (bit_length >> (((7 - shift) * 8) as u64)) & 0xFF
            self.pending = self.pending.push(lane as u8)
            shift = shift + 1
        }
        while self.pending.length() >= 64 {
            self.lanes = sha256_compress(self.lanes, sha256_head_block(self.pending))
            self.pending = sha256_take_block(self.pending)
        }

        let mut out: [u8] = []
        let mut lane_index: usize = 0
        while lane_index < 8 {
            let word: u32 = self.lanes⁅lane_index⁆
            let mut byte_index: usize = 0
            while byte_index < 4 {
                let byte: u32 = (word >> (((3 - byte_index) * 8) as u32)) & 0xFF
                out = out.push(byte as u8)
                byte_index = byte_index + 1
            }
            lane_index = lane_index + 1
        }
        return out
    }
}

micro digest_sha256(bytes: [u8]) -> [u8] {
    let mut state: DigestSha256 = digest_sha256_new()
    state.update(bytes)
    return state.finalize()
}
