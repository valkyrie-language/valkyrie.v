namespace std.data.binary.codec;

using std.data::{DataOutcome, data_outcome_value_or, data_outcome_has_errors, data_outcome_diagnostics};`nusing std.diagnostic::{Diagnostic, diagnostic_code, diagnostic_span};

# codec 核心行为测试：字节游标、位游标、位写出器，正反成对。
#
# 阻塞说明：断言依赖 `std::types::panic`，而 `raise` 终止子在各后端尚无目标
# 合同；且 `DataOutcome` 的 `diagnostics: [Diagnostic]` 字段因
# `Diagnostic` 含 `utf8` 成员无法冻结布局（CAN033/类型名解析失败）。
# 运行时证据当前由 `valkyrie.v/examples/std-data-drive`（node 断言返回值）提供。
#
# 比较纪律：u8/u16 在各后端无比较 provider，一律 `as u64` 后比较。

# 字节流：01 02 03 04 05 06 07 08。
micro lane_bytes() -> [u8] {
    return [1 as u8, 2 as u8, 3 as u8, 4 as u8, 5 as u8, 6 as u8, 7 as u8, 8 as u8]
}

[test]
micro test_read_u16_endian_pair() -> unit {
    let mut cursor: DataByteCursor = data_byte_cursor(data_byte_view_of(lane_bytes()))
    let little: u64 = data_outcome_value_or(cursor.read_u16(Little), 0 as u16) as u64
    if little != 0x0201 {
        std::types::panic("little-endian u16 mismatch")
    }
    if cursor.position() != 2 {
        std::types::panic("cursor must advance by 2")
    }
    let mut cursor2: DataByteCursor = data_byte_cursor(data_byte_view_of(lane_bytes()))
    let big: u64 = data_outcome_value_or(cursor2.read_u16(Big), 0 as u16) as u64
    if big != 0x0102 {
        std::types::panic("big-endian u16 mismatch")
    }
}

[test]
micro test_read_u32_u64_endian() -> unit {
    let mut cursor: DataByteCursor = data_byte_cursor(data_byte_view_of(lane_bytes()))
    let big32: u32 = data_outcome_value_or(cursor.read_u32(Big), 0 as u32)
    let expected32: u32 = 0x01020304
    if big32 != expected32 {
        std::types::panic("big-endian u32 mismatch")
    }
    let little64: u64 = data_outcome_value_or(cursor.read_u64(Little), 0 as u64)
    if little64 != 0x0807060504030201 {
        std::types::panic("little-endian u64 mismatch")
    }
}

[test]
micro test_read_past_end_keeps_cursor() -> unit {
    let short: [u8] = [1 as u8, 2 as u8, 3 as u8, 4 as u8]
    let mut cursor: DataByteCursor = data_byte_cursor(data_byte_view_of(short))
    let outcome: DataOutcome<u64> = cursor.read_u64(Little)
    if !data_outcome_has_errors(outcome) {
        std::types::panic("out-of-range read must register an error diagnostic")
    }
    if cursor.position() != 0 {
        std::types::panic("cursor must not advance past failed read")
    }
    if cursor.remaining() != 4 {
        std::types::panic("remaining must be unchanged after failed read")
    }
    let first: Diagnostic = data_outcome_diagnostics(outcome)⁅0⁆
    if !diagnostic_code(first).equals("std.data.codec.input_exhausted") {
        std::types::panic("diagnostic code mismatch")
    }
    if diagnostic_span(first).start != 0 {
        std::types::panic("diagnostic span must sit at the failed offset")
    }
}

[test]
micro test_read_view_windows_share_source() -> unit {
    let mut cursor: DataByteCursor = data_byte_cursor(data_byte_view_of(lane_bytes()))
    cursor.skip(2)
    let sub: DataByteView = data_outcome_value_or(cursor.read_view(3), DataByteView { bytes: [], base: 0, length: 0 })
    if sub.base != 2 {
        std::types::panic("subview base must track parent offset")
    }
    if sub.length != 3 {
        std::types::panic("subview length mismatch")
    }
    let mut sub_cursor: DataByteCursor = data_byte_cursor(sub)
    let head: u64 = data_outcome_value_or(sub_cursor.read_u8(), 0 as u8) as u64
    if head != 3 {
        std::types::panic("subview reads must hit the parent bytes")
    }
}

[test]
micro test_align_and_skip() -> unit {
    let mut cursor: DataByteCursor = data_byte_cursor(data_byte_view_of(lane_bytes()))
    cursor.read_u8()
    let at: usize = data_outcome_value_or(cursor.align(4), 0)
    if at != 4 {
        std::types::panic("align must land on the next boundary")
    }
    let skipped: DataOutcome<usize> = cursor.skip(2)
    if !data_outcome_has_errors(skipped) {
        if cursor.position() != 6 {
            std::types::panic("skip must advance within bounds")
        }
    }
}

[test]
micro test_bit_read_orders() -> unit {
    let bytes: [u8] = [0xB6 as u8]
    let mut lsb: DataBitCursor = data_bit_cursor(data_byte_view_of(bytes), LeastSignificantBitFirst)
    if data_outcome_value_or(lsb.read_bits(3), 0 as u64) != 0x6 {
        std::types::panic("lsb-first low bits mismatch")
    }
    if data_outcome_value_or(lsb.read_bits(5), 0 as u64) != 0x16 {
        std::types::panic("lsb-first crossing bits mismatch")
    }
    let mut msb: DataBitCursor = data_bit_cursor(data_byte_view_of(bytes), MostSignificantBitFirst)
    if data_outcome_value_or(msb.read_bits(4), 0 as u64) != 0xB {
        std::types::panic("msb-first high nibble mismatch")
    }
    if data_outcome_value_or(msb.read_bits(4), 0 as u64) != 0x6 {
        std::types::panic("msb-first low nibble mismatch")
    }
}

[test]
micro test_bit_read_past_end_partial_value() -> unit {
    let bytes: [u8] = [0xFF as u8]
    let mut cursor: DataBitCursor = data_bit_cursor(data_byte_view_of(bytes), LeastSignificantBitFirst)
    let outcome: DataOutcome<u64> = cursor.read_bits(9)
    if !data_outcome_has_errors(outcome) {
        std::types::panic("reading past the last bit must register an error")
    }
    if data_outcome_value_or(outcome, 0 as u64) != 0xFF {
        std::types::panic("partial result must keep the bits that were readable")
    }
}

[test]
micro test_bit_write_orders_and_finish() -> unit {
    let mut lsb: DataBitWriter = data_bit_writer(LeastSignificantBitFirst)
    lsb.write_bits(0x6, 3)
    lsb.write_bits(0x36, 6)
    let packed: [u8] = lsb.finish()
    if packed.length() != 2 {
        std::types::panic("lsb packing length mismatch")
    }
    if (packed⁅0⁆ as u64) != 0xB6 {
        std::types::panic("lsb packing first byte mismatch")
    }
    if (packed⁅1⁆ as u64) != 1 {
        std::types::panic("lsb packing must pad the final byte with zeroes")
    }
    let mut msb: DataBitWriter = data_bit_writer(MostSignificantBitFirst)
    msb.write_bits(0xB, 4)
    msb.write_bits(0x6, 4)
    let packed_msb: [u8] = msb.finish()
    if packed_msb.length() != 1 {
        std::types::panic("msb packing length mismatch")
    }
    if (packed_msb⁅0⁆ as u64) != 0xB6 {
        std::types::panic("msb packing byte mismatch")
    }
}

[test]
micro test_bit_write_read_round_trip() -> unit {
    let mut writer: DataBitWriter = data_bit_writer(LeastSignificantBitFirst)
    writer.write_bits(1, 1)
    writer.write_bits(17, 5)
    writer.write_bits(300, 9)
    let bytes: [u8] = writer.finish()
    let mut cursor: DataBitCursor = data_bit_cursor(data_byte_view_of(bytes), LeastSignificantBitFirst)
    if data_outcome_value_or(cursor.read_bits(1), 0 as u64) != 1 {
        std::types::panic("round trip first field mismatch")
    }
    if data_outcome_value_or(cursor.read_bits(5), 0 as u64) != 17 {
        std::types::panic("round trip second field mismatch")
    }
    if data_outcome_value_or(cursor.read_bits(9), 0 as u64) != 300 {
        std::types::panic("round trip third field mismatch")
    }
}
