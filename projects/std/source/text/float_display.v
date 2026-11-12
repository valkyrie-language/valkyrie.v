namespace std.text;

# 浮点 `Display`：最短可回读十进制文本，纯 V 实现（Dragon4 自由格式）。
#
# 口径：
# - 按 IEEE-754 位模式拆分指数与尾数，用精确有理数 `R / S`（配 `mp` / `mm`
#   半 ulp 容差）逐位贪心产出最短可回读尾数；不做「先转 f64、再四舍五入到
#   固定位数」的近似，次正规与 `1e-7` 量级同样按精确算术走。
# - 定点大整数用 40 × u32 limb（小端，容量 1280 bit），只做乘小因子、比较、
#   加减与重复减法求商；不依赖 64×64 乘法高位，也不调用任何宿主浮点格式化。
# - 文本形态：整数值不带 `.0`；不用指数；`-0.0` 输出 `-0`；`NaN` / `inf` /
#   `-inf` 是固定文本且不本地化；不做宽度、精度与命名参数。

# 40 limb = 1280 bit 的定点大整数（小端），覆盖 `2^1075` 与 `10^324` 量级中间量。
class FloatBig {
    _limbs: [u32]
}

imply FloatBig {
    micro new(): Self {
        let mut storage: std::collection::ArrayStorage<u32> = std::collection::ArrayStorage::<u32>::with_capacity(40)
        let mut index: usize = 0
        while index < 40 {
            storage.initialize(0 as u32)
            index = index + 1
        }

        return FloatBig { _limbs: storage.finalize() }
    }

    micro clone(self): Self {
        let mut copied: Self = Self::new()
        let mut index: usize = 0
        while index < 40 {
            copied._limbs⁅index⁆ = self._limbs⁅index⁆
            index = index + 1
        }

        return copied
    }

    micro set_u64(mut self, value: u64): unit {
        let mut index: usize = 0
        while index < 40 {
            self._limbs⁅index⁆ = 0 as u32
            index = index + 1
        }

        self._limbs⁅0⁆ = (value % (4294967296 as u64)) as u32
        self._limbs⁅1⁆ = (value / (4294967296 as u64)) as u32
    }

    # 置为 `2^bit`（bit 非负）；先清零。
    micro set_pow2(mut self, bit: i64): unit {
        let mut index: usize = 0
        while index < 40 {
            self._limbs⁅index⁆ = 0 as u32
            index = index + 1
        }

        self.add_pow2(bit)
    }

    micro add_pow2(mut self, bit: i64): unit {
        let limb: usize = (bit / 32) as usize
        let offset: u32 = (bit % 32) as u32
        self._limbs⁅limb⁆ = self._limbs⁅limb⁆ | ((1 as u32) << offset)
    }

    # 乘一个小因子：逐 limb 用 u64 中间量进位。
    micro mul_small(mut self, factor: u32): unit {
        let mut carry: u64 = 0 as u64
        let mut index: usize = 0
        while index < 40 {
            let product: u64 = (self._limbs⁅index⁆ as u64) * (factor as u64) + carry
            self._limbs⁅index⁆ = (product % (4294967296 as u64)) as u32
            carry = product / (4294967296 as u64)
            index = index + 1
        }

        if carry != 0 as u64 {
            std::types::panic("float display：大整数超出 40 limb 容量")
        }
    }

    # 乘 `2^bits`：先乘低位掩码，再整 limb 左移。
    micro mul_pow2(mut self, bits: i64): unit {
        let limb_shift: usize = (bits / 32) as usize
        let bit_shift: u32 = (bits % 32) as u32
        if bit_shift != 0 as u32 {
            self.mul_small((1 as u32) << bit_shift)
        }

        if limb_shift != 0 {
            let mut index: usize = 40
            while index > 0 {
                index = index - 1
                if index >= limb_shift {
                    self._limbs⁅index⁆ = self._limbs⁅index - limb_shift⁆
                }
                else {
                    self._limbs⁅index⁆ = 0 as u32
                }
            }
        }
    }

    micro mul_pow10(mut self, count: i64): unit {
        let mut step: i64 = 0
        while step < count {
            self.mul_small(10 as u32)
            step = step + 1
        }
    }

    micro compare(self, other: Self): i32 {
        let mut index: usize = 40
        while index > 0 {
            index = index - 1
            let left: u32 = self._limbs⁅index⁆
            let right: u32 = other._limbs⁅index⁆
            if left > right {
                return 1
            }

            if right > left {
                return -1
            }
        }

        return 0
    }

    micro add_into(mut self, other: Self): unit {
        let mut carry: u64 = 0 as u64
        let mut index: usize = 0
        while index < 40 {
            let sum: u64 = (self._limbs⁅index⁆ as u64) + (other._limbs⁅index⁆ as u64) + carry
            self._limbs⁅index⁆ = (sum % (4294967296 as u64)) as u32
            carry = sum / (4294967296 as u64)
            index = index + 1
        }
    }

    # `self -= other`，要求 `self >= other`（Dragon4 的求商循环满足该前提）。
    micro subtract(mut self, other: Self): unit {
        let mut borrow: u64 = 0 as u64
        let limit: u64 = 4294967296 as u64
        let mut index: usize = 0
        while index < 40 {
            let minuend: u64 = self._limbs⁅index⁆ as u64
            let subtrahend: u64 = (other._limbs⁅index⁆ as u64) + borrow
            if minuend >= subtrahend {
                self._limbs⁅index⁆ = (minuend - subtrahend) as u32
                borrow = 0 as u64
            }
            else {
                self._limbs⁅index⁆ = (minuend + limit - subtrahend) as u32
                borrow = 1 as u64
            }

            index = index + 1
        }
    }
}

# 十进制尾数位与小数点位置：值 = `0.<digits> × 10^k`。
class FloatDigits {
    _digits: ArrayList<u8>
    _k: i64
}

imply FloatDigits {
    micro new(k: i64): Self {
        return FloatDigits { _digits: ArrayList::new(24), _k: k }
    }

    micro length(self): usize {
        return self._digits.length()
    }

    micro push(mut self, digit: u32): unit {
        self._digits.push(digit as u8)
    }

    # 追加一位并处理进位；`q == 10` 时向前进一位，全 9 则最前插入 1 且 `k` 加一。
    micro push_with_carry(mut self, q: u32): unit {
        if q < 10 as u32 {
            self._digits.push(q as u8)
            return
        }

        let mut index: usize = self._digits.length()
        while index > 0 {
            index = index - 1
            if self._digits⁅index⁆ == (9 as u8) {
                self._digits⁅index⁆ = 0 as u8
            }
            else {
                self._digits⁅index⁆ = self._digits⁅index⁆ + (1 as u8)
                return
            }
        }

        self._digits.insert(1, 1 as u8)
        self._k = self._k + 1
    }

    # 定点文本：整数值不带 `.0`，小数形态不出现指数；末尾零天然不入表。
    micro to_text(self, negative: bool): utf8 {
        let mut bytes: ArrayList<u8> = ArrayList::new(72)
        if negative {
            bytes.push(45 as u8)
        }

        let count: i64 = self._digits.length() as i64
        if self._k <= 0 {
            bytes.push(48 as u8)
            bytes.push(46 as u8)
            let mut zeros: i64 = -self._k
            while zeros > 0 {
                bytes.push(48 as u8)
                zeros = zeros - 1
            }

            let mut index: usize = 0
            while index < self._digits.length() {
                bytes.push((48 as u8) + self._digits⁅index⁆)
                index = index + 1
            }
        }
        else if count <= self._k {
            let mut index: usize = 0
            while index < self._digits.length() {
                bytes.push((48 as u8) + self._digits⁅index⁆)
                index = index + 1
            }

            let mut zeros: i64 = self._k - count
            while zeros > 0 {
                bytes.push(48 as u8)
                zeros = zeros - 1
            }
        }
        else {
            let split: usize = self._k as usize
            let mut index: usize = 0
            while index < self._digits.length() {
                if index == split {
                    bytes.push(46 as u8)
                }

                bytes.push((48 as u8) + self._digits⁅index⁆)
                index = index + 1
            }
        }

        # 输出只由 ASCII 数字、'-' 与 '.' 构成，构造即合法 UTF-8，免重验证。
        return Utf8Text::from_bytes_unchecked(bytes.to_array())
    }
}

# 给定拆分后的整数尾数与二进制指数，产出最短可回读尾数与位置。
#
# `mantissa` 是 `hidden`（`2^(p-1)`）量级的整数尾数，值 = `mantissa × 2^exponent`；
# 次正规用 `exponent == minimum_subnormal_exponent` 且 `mantissa < hidden` 表达。
private micro binary_float_digits(
    mantissa: u64,
    exponent: i64,
    minimum_subnormal_exponent: i64,
    hidden: u64,
) -> FloatDigits {
    let even: bool = (mantissa % (2 as u64)) == (0 as u64)
    let mut r: FloatBig = FloatBig::new()
    let mut s: FloatBig = FloatBig::new()
    let mut mp: FloatBig = FloatBig::new()
    let mut mm: FloatBig = FloatBig::new()

    # 初始化精确有理数：`R / S` 即原值，`mp / S` / `mm / S` 是上/下半 ulp 容差。
    # 统一按 4 倍尺度表达，避开通用的次正规分支在半 ulp 上出现非整数。
    if exponent >= 0 {
        r.set_u64(mantissa)
        r.mul_small(4 as u32)
        if exponent != 0 {
            r.mul_pow2(exponent)
        }

        s.set_u64(4 as u64)
        mp.set_pow2(exponent + 1)
        if mantissa == hidden {
            mm.set_pow2(exponent)
        }
        else {
            mm.set_pow2(exponent + 1)
        }
    }
    else if exponent == minimum_subnormal_exponent || mantissa != hidden {
        r.set_u64(mantissa)
        r.mul_small(2 as u32)
        s.set_pow2(1 - exponent)
        mp.set_u64(1 as u64)
        mm.set_u64(1 as u64)
    }
    else {
        r.set_u64(mantissa)
        r.mul_small(4 as u32)
        s.set_pow2(2 - exponent)
        mp.set_u64(2 as u64)
        mm.set_u64(1 as u64)
    }

    # `k` 估计：`floor(log10 v) + 1`，由 `floor(log2 v) + 1` 换底得到，随后绝对值校正。
    let bits_len: i64 = (64 as i64) - (mantissa.leading_zeros() as i64) + exponent
    let product: i64 = (bits_len - 1) * 78913
    let mut k: i64 = 0
    if product < 0 {
        let magnitude: i64 = -product
        let mut quotient: i64 = magnitude / 262144
        if magnitude % 262144 != 0 {
            quotient = quotient + 1
        }

        k = (-quotient) + 1
    }
    else {
        k = (product / 262144) + 1
    }

    if k - 1 >= 0 {
        s.mul_pow10(k - 1)
    }
    else {
        let factor: i64 = 1 - k
        r.mul_pow10(factor)
        mp.mul_pow10(factor)
        mm.mul_pow10(factor)
    }

    # 绝对值校正：把 `R / S` 拨回 `[1, 10)`。
    let mut guard: i64 = 0
    let mut scaled: FloatBig = s.clone()
    scaled.mul_small(10 as u32)
    while r.compare(scaled) >= 0 {
        s.mul_small(10 as u32)
        k = k + 1
        scaled = s.clone()
        scaled.mul_small(10 as u32)
        guard = guard + 1
        if guard > 400 {
            std::types::panic("float display：十进制尺度校正失控")
        }
    }

    while r.compare(s) < 0 {
        r.mul_small(10 as u32)
        mp.mul_small(10 as u32)
        mm.mul_small(10 as u32)
        k = k - 1
        guard = guard + 1
        if guard > 400 {
            std::types::panic("float display：十进制尺度校正失控")
        }
    }

    let mut output: FloatDigits = FloatDigits::new(k)
    let mut finished: bool = false
    while !finished {
        let mut q: u32 = 0 as u32
        while r.compare(s) >= 0 {
            r.subtract(s)
            q = q + (1 as u32)
        }

        # 余数落在下半 ulp 内即向下可取（中点按尾数最低位奇偶决定是否可回读）；
        # 同理 `R + mp` 越过 `S` 即向上可取。
        let low: bool = (r.compare(mm) < 0) || (r.compare(mm) == 0 && even)
        let mut raised: FloatBig = r.clone()
        raised.add_into(mp)
        let high: bool = (raised.compare(s) > 0) || (raised.compare(s) == 0 && even)

        if low && high {
            let mut doubled: FloatBig = r.clone()
            doubled.add_into(r)
            let against: i32 = doubled.compare(s)
            let mut pick: u32 = q
            if against > 0 {
                pick = q + (1 as u32)
            }
            else if against == 0 {
                if (q % (2 as u32)) != (0 as u32) {
                    pick = q + (1 as u32)
                }
            }

            output.push_with_carry(pick)
            finished = true
        }
        else if low {
            output.push_with_carry(q)
            finished = true
        }
        else if high {
            output.push_with_carry(q + (1 as u32))
            finished = true
        }
        else {
            output.push(q)
            r.mul_small(10 as u32)
            mp.mul_small(10 as u32)
            mm.mul_small(10 as u32)
            if output.length() > 40 {
                std::types::panic("float display：尾数位数失控")
            }
        }
    }

    return output
}

private micro display_float64(value: f64) -> utf8 {
    let bits: u64 = value.to_bits()
    # 符号位以 `2^62` 常量分块拆位：全部中间量保持在可表示范围内，
    # 不构造会越出无符号 64 位表示的乘积。
    let half: u64 = 4611686018427387904 as u64
    let fraction_scale: u64 = 4503599627370496 as u64
    let block: u64 = bits / half
    let negative: bool = block >= (2 as u64)
    let magnitude: u64 = (bits % half) + (block % (2 as u64)) * half
    let exponent_field: u64 = magnitude / fraction_scale
    let fraction: u64 = magnitude % fraction_scale

    if exponent_field == (2047 as u64) {
        if fraction != 0 as u64 {
            return "NaN"
        }

        if negative {
            return "-inf"
        }

        return "inf"
    }

    if exponent_field == (0 as u64) && fraction == 0 as u64 {
        if negative {
            return "-0"
        }

        return "0"
    }

    let mut mantissa: u64 = fraction
    let mut exponent: i64 = -1074
    if exponent_field != 0 as u64 {
        mantissa = fraction | (4503599627370496 as u64)
        exponent = (exponent_field as i64) - 1075
    }

    let digits: FloatDigits = binary_float_digits(mantissa, exponent, -1074, 4503599627370496 as u64)
    return digits.to_text(negative)
}

private micro display_float32(value: f32) -> utf8 {
    let bits: u32 = value.to_bits()
    let top: u32 = 0x80000000 as u32
    let fraction_scale: u32 = 0x800000 as u32
    let negative: bool = bits >= top
    let magnitude: u32 = bits % top
    let exponent_field: u32 = magnitude / fraction_scale
    let fraction: u32 = magnitude % fraction_scale

    if exponent_field == (0xff as u32) {
        if fraction != 0 as u32 {
            return "NaN"
        }

        if negative {
            return "-inf"
        }

        return "inf"
    }

    if exponent_field == (0 as u32) && fraction == 0 as u32 {
        if negative {
            return "-0"
        }

        return "0"
    }

    let mut mantissa: u64 = fraction as u64
    let mut exponent: i64 = -149
    if exponent_field != 0 as u32 {
        mantissa = (fraction | (0x800000 as u32)) as u64
        exponent = (exponent_field as i64) - 150
    }

    let digits: FloatDigits = binary_float_digits(mantissa, exponent, -149, 8388608 as u64)
    return digits.to_text(negative)
}

imply f32: Display {
    micro display(self): utf8 {
        return display_float32(self)
    }
}

imply f64: Display {
    micro display(self): utf8 {
        return display_float64(self)
    }
}
