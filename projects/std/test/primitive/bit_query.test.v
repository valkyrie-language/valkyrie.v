namespace std.primitive;

# 整数位元查询：置位个数 / 前导零 / 尾随零。
# 结果返回 `u32`；全 0 的前导与尾随零按载体位宽返回。

[test]
micro `test u8 bit queries`() {
    let zero: u8 = 0 as u8
    if zero.count_ones() != 0 {
        std::types::panic("u8 zero count_ones must be 0")
    }
    if zero.leading_zeros() != 8 {
        std::types::panic("u8 zero leading_zeros must be 8")
    }
    if zero.trailing_zeros() != 8 {
        std::types::panic("u8 zero trailing_zeros must be 8")
    }

    let all: u8 = 255 as u8
    if all.count_ones() != 8 {
        std::types::panic("u8 255 count_ones must be 8")
    }
    if all.leading_zeros() != 0 {
        std::types::panic("u8 255 leading_zeros must be 0")
    }
    if all.trailing_zeros() != 0 {
        std::types::panic("u8 255 trailing_zeros must be 0")
    }

    let top: u8 = 128 as u8
    if top.count_ones() != 1 {
        std::types::panic("u8 128 count_ones must be 1")
    }
    if top.leading_zeros() != 0 {
        std::types::panic("u8 128 leading_zeros must be 0")
    }
    if top.trailing_zeros() != 7 {
        std::types::panic("u8 128 trailing_zeros must be 7")
    }

    let low: u8 = 4 as u8
    if low.trailing_zeros() != 2 {
        std::types::panic("u8 4 trailing_zeros must be 2")
    }
    if low.leading_zeros() != 5 {
        std::types::panic("u8 4 leading_zeros must be 5")
    }
}

[test]
micro `test u32 bit queries`() {
    let zero: u32 = 0 as u32
    if zero.count_ones() != 0 {
        std::types::panic("u32 zero count_ones must be 0")
    }
    if zero.leading_zeros() != 32 {
        std::types::panic("u32 zero leading_zeros must be 32")
    }
    if zero.trailing_zeros() != 32 {
        std::types::panic("u32 zero trailing_zeros must be 32")
    }

    let one: u32 = 1 as u32
    if one.count_ones() != 1 {
        std::types::panic("u32 one count_ones must be 1")
    }
    if one.leading_zeros() != 31 {
        std::types::panic("u32 one leading_zeros must be 31")
    }
    if one.trailing_zeros() != 0 {
        std::types::panic("u32 one trailing_zeros must be 0")
    }

    let top: u32 = 0x80000000 as u32
    if top.count_ones() != 1 {
        std::types::panic("u32 top bit count_ones must be 1")
    }
    if top.leading_zeros() != 0 {
        std::types::panic("u32 top bit leading_zeros must be 0")
    }
    if top.trailing_zeros() != 31 {
        std::types::panic("u32 top bit trailing_zeros must be 31")
    }

    let twelve: u32 = 12 as u32
    if twelve.count_ones() != 2 {
        std::types::panic("u32 12 count_ones must be 2")
    }
    if twelve.leading_zeros() != 28 {
        std::types::panic("u32 12 leading_zeros must be 28")
    }
    if twelve.trailing_zeros() != 2 {
        std::types::panic("u32 12 trailing_zeros must be 2")
    }
}

[test]
micro `test u64 bit queries`() {
    let zero: u64 = 0 as u64
    if zero.count_ones() != 0 {
        std::types::panic("u64 zero count_ones must be 0")
    }
    if zero.leading_zeros() != 64 {
        std::types::panic("u64 zero leading_zeros must be 64")
    }
    if zero.trailing_zeros() != 64 {
        std::types::panic("u64 zero trailing_zeros must be 64")
    }

    let one: u64 = 1 as u64
    if one.count_ones() != 1 {
        std::types::panic("u64 one count_ones must be 1")
    }
    if one.leading_zeros() != 63 {
        std::types::panic("u64 one leading_zeros must be 63")
    }
    if one.trailing_zeros() != 0 {
        std::types::panic("u64 one trailing_zeros must be 0")
    }

    # 最高位：hi/lo 组合构造 2^63，不写超 i64 上限的十六进制字面量。
    let top: u64 = (0x80000000 as u64) << 32
    if top.count_ones() != 1 {
        std::types::panic("u64 top bit count_ones must be 1")
    }
    if top.leading_zeros() != 0 {
        std::types::panic("u64 top bit leading_zeros must be 0")
    }
    if top.trailing_zeros() != 63 {
        std::types::panic("u64 top bit trailing_zeros must be 63")
    }
}

[test]
micro `test signed bit queries use bit pattern`() {
    let minus_one: i32 = -1 as i32
    if minus_one.count_ones() != 32 {
        std::types::panic("i32 -1 count_ones must be 32")
    }
    if minus_one.leading_zeros() != 0 {
        std::types::panic("i32 -1 leading_zeros must be 0")
    }
    if minus_one.trailing_zeros() != 0 {
        std::types::panic("i32 -1 trailing_zeros must be 0")
    }

    let minus_two: i32 = -2 as i32
    if minus_two.count_ones() != 31 {
        std::types::panic("i32 -2 count_ones must be 31")
    }
    if minus_two.trailing_zeros() != 1 {
        std::types::panic("i32 -2 trailing_zeros must be 1")
    }

    let minus_four: i8 = -4 as i8
    if minus_four.count_ones() != 6 {
        std::types::panic("i8 -4 count_ones must be 6")
    }
    if minus_four.trailing_zeros() != 2 {
        std::types::panic("i8 -4 trailing_zeros must be 2")
    }

    let i8_zero: i8 = 0 as i8
    if i8_zero.leading_zeros() != 8 {
        std::types::panic("i8 zero leading_zeros must be 8")
    }
    if i8_zero.trailing_zeros() != 8 {
        std::types::panic("i8 zero trailing_zeros must be 8")
    }

    let i8_min: i8 = (1 as i8) << (7 as i8)
    if i8_min.count_ones() != 1 {
        std::types::panic("i8 minimum count_ones must be 1")
    }
    if i8_min.leading_zeros() != 0 {
        std::types::panic("i8 minimum leading_zeros must be 0")
    }
    if i8_min.trailing_zeros() != 7 {
        std::types::panic("i8 minimum trailing_zeros must be 7")
    }

    let i64_zero: i64 = 0 as i64
    if i64_zero.leading_zeros() != 64 {
        std::types::panic("i64 zero leading_zeros must be 64")
    }
    if i64_zero.trailing_zeros() != 64 {
        std::types::panic("i64 zero trailing_zeros must be 64")
    }

    let i64_min: i64 = (1 as i64) << (63 as i64)
    if i64_min.count_ones() != 1 {
        std::types::panic("i64 minimum count_ones must be 1")
    }
    if i64_min.leading_zeros() != 0 {
        std::types::panic("i64 minimum leading_zeros must be 0")
    }
    if i64_min.trailing_zeros() != 63 {
        std::types::panic("i64 minimum trailing_zeros must be 63")
    }
}
