namespace std.data.binary.codec;

# 声明层验证：类型可构造、变体可引用。
# trait（DataByteReader/DataBitReader）随源码组编译即被检查，无 impl 属于本轮刻意留白。

[test]
micro test_codec_bit_position_constructible() -> unit {
    let position: DataBitPosition = DataBitPosition { byte_offset: 1, bit_offset: 3 }
    if position.byte_offset != 1 {
        panic("bit position byte offset mismatch")
    }
    if position.bit_offset != 3 {
        panic("bit position bit offset mismatch")
    }
}

[test]
micro test_codec_byte_view_constructible() -> unit {
    let view: DataByteView = DataByteView { bytes: [1, 2, 3, 4], base: 0, length: 4 }
    if view.length != 4 {
        panic("view length mismatch")
    }
    if view.base != 0 {
        panic("view base mismatch")
    }
}

[test]
micro test_codec_endian_variants() -> unit {
    let little: DataEndian = Little
    let big: DataEndian = Big
    if little == big {
        panic("endian variants must differ")
    }
}
