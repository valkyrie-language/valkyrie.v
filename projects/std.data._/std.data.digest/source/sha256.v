namespace std.data.digest;

# SHA-256（FIPS 180-4）。纯计算、无 host 依赖。
#
# 载道说明：u32 逻辑右移在 wasm 后端被错误 lowering 成左旋（见 _.v 载道说明），
# 因此全部 32 位字以 u64 承载、每步显式 `& 0xFFFFFFFF` 掩码；语义与 u32 逐位一致。
#
# 块内布局：消息按 64 字节分块；`pending` 存未满一块的尾巴，`total` 记总字节数
# （finalize 时换算成比特长度写尾）。w 调度、K 表、H 初值均为算法固有常数。

micro sha256_mask() -> u64 {
    return 0xFFFFFFFF
}

# 初始哈希值：前 8 个素数平方根小数部的高 32 位（算法固有常数）。
micro sha256_initial() -> [u64] {
    return [
        0x6a09e667 as u64, 0xbb67ae85 as u64, 0x3c6ef372 as u64, 0xa54ff53a as u64,
        0x510e527f as u64, 0x9b05688c as u64, 0x1f83d9ab as u64, 0x5be0cd19 as u64,
    ]
}

# 轮常数：前 64 个素数立方根小数部的高 32 位（算法固有常数）。
micro sha256_round_constants() -> [u64] {
    return [
        0x428a2f98 as u64, 0x71374491 as u64, 0xb5c0fbcf as u64, 0xe9b5dba5 as u64, 0x3956c25b as u64, 0x59f111f1 as u64, 0x923f82a4 as u64, 0xab1c5ed5 as u64,
        0xd807aa98 as u64, 0x12835b01 as u64, 0x243185be as u64, 0x550c7dc3 as u64, 0x72be5d74 as u64, 0x80deb1fe as u64, 0x9bdc06a7 as u64, 0xc19bf174 as u64,
        0xe49b69c1 as u64, 0xefbe4786 as u64, 0x0fc19dc6 as u64, 0x240ca1cc as u64, 0x2de92c6f as u64, 0x4a7484aa as u64, 0x5cb0a9dc as u64, 0x76f988da as u64,
        0x983e5152 as u64, 0xa831c66d as u64, 0xb00327c8 as u64, 0xbf597fc7 as u64, 0xc6e00bf3 as u64, 0xd5a79147 as u64, 0x06ca6351 as u64, 0x14292967 as u64,
        0x27b70a85 as u64, 0x2e1b2138 as u64, 0x4d2c6dfc as u64, 0x53380d13 as u64, 0x650a7354 as u64, 0x766a0abb as u64, 0x81c2c92e as u64, 0x92722c85 as u64,
        0xa2bfe8a1 as u64, 0xa81a664b as u64, 0xc24b8b70 as u64, 0xc76c51a3 as u64, 0xd192e819 as u64, 0xd6990624 as u64, 0xf40e3585 as u64, 0x106aa070 as u64,
        0x19a4c116 as u64, 0x1e376c08 as u64, 0x2748774c as u64, 0x34b0bcb5 as u64, 0x391c0cb3 as u64, 0x4ed8aa4a as u64, 0x5b9cca4f as u64, 0x682e6ff3 as u64,
        0x748f82ee as u64, 0x78a5636f as u64, 0x84c87814 as u64, 0x8cc70208 as u64, 0x90befffa as u64, 0xa4506ceb as u64, 0xbef9a3f7 as u64, 0xc67178f2 as u64,
    ]
}

# 32 位循环右移（u64 载道 + 掩码）。
micro sha256_rotr(x: u64, n: u64) -> u64 {
    return ((x >> n) | (x << (32 - n))) & sha256_mask()
}

micro sha256_big_sigma0(x: u64) -> u64 {
    return sha256_rotr(x, 2) ^ sha256_rotr(x, 13) ^ sha256_rotr(x, 22)
}

micro sha256_big_sigma1(x: u64) -> u64 {
    return sha256_rotr(x, 6) ^ sha256_rotr(x, 11) ^ sha256_rotr(x, 25)
}

micro sha256_small_sigma0(x: u64) -> u64 {
    return sha256_rotr(x, 7) ^ sha256_rotr(x, 18) ^ (x >> 3)
}

micro sha256_small_sigma1(x: u64) -> u64 {
    return sha256_rotr(x, 17) ^ sha256_rotr(x, 19) ^ (x >> 10)
}

micro sha256_ch(e: u64, f: u64, g: u64) -> u64 {
    return (e & f) ^ ((e ^ sha256_mask()) & g)
}

micro sha256_maj(a: u64, b: u64, c: u64) -> u64 {
    return (a & b) ^ (a & c) ^ (b & c)
}

# SHA-256 流式状态：`lanes` 是 8 个工作变量（u64 载道），`pending` 是未满一块的
# 尾字节，`total` 是已接收总字节数。
structure DigestSha256 {
    lanes: [u64]
    pending: [u8]
    total: usize
}

micro digest_sha256_new() -> DigestSha256 {
    return DigestSha256 { lanes: sha256_initial(), pending: [], total: 0 }
}

# 处理一个 64 字节块（block 恰为 64 字节由调用点保证）。
micro sha256_compress(mut lanes: [u64], block: [u8]) -> [u64] {
    let round_constants: [u64] = sha256_round_constants()
    let mut w: [u64] = []
    let mut fill: usize = 0
    while fill < 64 {
        w = std::collection::push(w, 0 as u64)
        fill = fill + 1
    }
    let mut t: usize = 0
    while t < 16 {
        let base: usize = t * 4
        let b0: u64 = std::collection::array::get(block, base) as u64
        let b1: u64 = std::collection::array::get(block, base + 1) as u64
        let b2: u64 = std::collection::array::get(block, base + 2) as u64
        let b3: u64 = std::collection::array::get(block, base + 3) as u64
        std::collection::array::set(w, t, (b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
        t = t + 1
    }
    while t < 64 {
        let word: u64 = (sha256_small_sigma1(std::collection::array::get(w, t - 2))
            + std::collection::array::get(w, t - 7)
            + sha256_small_sigma0(std::collection::array::get(w, t - 15))
            + std::collection::array::get(w, t - 16)) & sha256_mask()
        std::collection::array::set(w, t, word)
        t = t + 1
    }

    let mut a: u64 = std::collection::array::get(lanes, 0)
    let mut b: u64 = std::collection::array::get(lanes, 1)
    let mut c: u64 = std::collection::array::get(lanes, 2)
    let mut d: u64 = std::collection::array::get(lanes, 3)
    let mut e: u64 = std::collection::array::get(lanes, 4)
    let mut f: u64 = std::collection::array::get(lanes, 5)
    let mut g: u64 = std::collection::array::get(lanes, 6)
    let mut h: u64 = std::collection::array::get(lanes, 7)

    t = 0
    while t < 64 {
        let t1: u64 = (h + sha256_big_sigma1(e) + sha256_ch(e, f, g)
            + std::collection::array::get(round_constants, t)
            + std::collection::array::get(w, t)) & sha256_mask()
        let t2: u64 = (sha256_big_sigma0(a) + sha256_maj(a, b, c)) & sha256_mask()
        h = g
        g = f
        f = e
        e = (d + t1) & sha256_mask()
        d = c
        c = b
        b = a
        a = (t1 + t2) & sha256_mask()
        t = t + 1
    }

    std::collection::array::set(lanes, 0, (a + std::collection::array::get(lanes, 0)) & sha256_mask())
    std::collection::array::set(lanes, 1, (b + std::collection::array::get(lanes, 1)) & sha256_mask())
    std::collection::array::set(lanes, 2, (c + std::collection::array::get(lanes, 2)) & sha256_mask())
    std::collection::array::set(lanes, 3, (d + std::collection::array::get(lanes, 3)) & sha256_mask())
    std::collection::array::set(lanes, 4, (e + std::collection::array::get(lanes, 4)) & sha256_mask())
    std::collection::array::set(lanes, 5, (f + std::collection::array::get(lanes, 5)) & sha256_mask())
    std::collection::array::set(lanes, 6, (g + std::collection::array::get(lanes, 6)) & sha256_mask())
    std::collection::array::set(lanes, 7, (h + std::collection::array::get(lanes, 7)) & sha256_mask())
    return lanes
}

# 从 pending 头部摘出恰好一个 64 字节块，返回剩余 pending。
micro sha256_take_block(mut pending: [u8]) -> [u8] {
    let mut rest: [u8] = []
    let length: usize = std::collection::array::length(pending)
    let mut index: usize = 64
    while index < length {
        rest = std::collection::push(rest, std::collection::array::get(pending, index))
        index = index + 1
    }
    return rest
}

# 取 pending 前 64 字节为块（调用点保证 length >= 64）。
micro sha256_head_block(pending: [u8]) -> [u8] {
    let mut block: [u8] = []
    let mut index: usize = 0
    while index < 64 {
        block = std::collection::push(block, std::collection::array::get(pending, index))
        index = index + 1
    }
    return block
}

imply DigestSha256 {
    micro update(mut self, bytes: [u8]) -> unit {
        let length: usize = std::collection::array::length(bytes)
        let mut index: usize = 0
        while index < length {
            self.pending = std::collection::push(self.pending, std::collection::array::get(bytes, index))
            index = index + 1
        }
        self.total = self.total + length
        while std::collection::array::length(self.pending) >= 64 {
            self.lanes = sha256_compress(self.lanes, sha256_head_block(self.pending))
            self.pending = sha256_take_block(self.pending)
        }
    }

    # 读出 32 字节原始摘要。填充：0x80、清零至距块尾 8 字节、大端 64 位比特长度。
    micro finalize(mut self) -> [u8] {
        let bit_length: u64 = (self.total * 8) as u64
        self.pending = std::collection::push(self.pending, 0x80 as u8)
        while std::collection::array::length(self.pending) % 64 != 56 {
            self.pending = std::collection::push(self.pending, 0 as u8)
        }
        let mut shift: usize = 0
        while shift < 8 {
            let lane: u64 = (bit_length >> (((7 - shift) * 8) as u64)) & 0xFF
            self.pending = std::collection::push(self.pending, lane as u8)
            shift = shift + 1
        }
        while std::collection::array::length(self.pending) >= 64 {
            self.lanes = sha256_compress(self.lanes, sha256_head_block(self.pending))
            self.pending = sha256_take_block(self.pending)
        }

        let mut out: [u8] = []
        let mut lane_index: usize = 0
        while lane_index < 8 {
            let word: u64 = std::collection::array::get(self.lanes, lane_index)
            let mut byte_index: usize = 0
            while byte_index < 4 {
                let byte: u64 = (word >> (((3 - byte_index) * 8) as u64)) & 0xFF
                out = std::collection::push(out, byte as u8)
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
