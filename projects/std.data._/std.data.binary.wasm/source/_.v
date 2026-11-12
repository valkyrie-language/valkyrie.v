namespace std.data.binary.wasm;

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};
using std.text::{Utf8Builder};

# 诊断类型收敛到 `std.diagnostic::Diagnostic`（统一合同，不再各自定义）。
# 位置单位合同：本包所有 `offset` / `consumed` / 诊断 span 一律为二进制流字节偏移；
# 产出的 `utf8` 值内部是 UTF-8 存储，其 `length()` / `slice()` 为码点口径。
# 两套坐标系只在 `Utf8Text` 显式视图（`bytes` / `byte_at`）处转换，不得互相冒充。

[tag(WasmBinaryResultKind)]
unite WasmBinaryResult<T> {
    [tag(0)]
    [constructor]
    Fine { value: T }
    [tag(1)]
    [constructor]
    Fail { error: Diagnostic }
}

micro wasm_binary_diagnostic(message: utf8, offset: usize) -> Diagnostic {
    return new_diagnostic("std.data.binary.wasm.defect", Error, message, new_span(offset, offset))
}

structure Leb128Decoded<T> {
    value: T

    consumed: usize
}

micro leb128_decode_u32(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<u32>> {
    let mut result: u32 = 0
    let mut shift: u32 = 0
    let mut pos: usize = offset
    let length: usize = data.length

    while pos < length {
        let byte: i32 = data[pos]
        let byte_val: u32 = byte as u32
        let low_bits: u32 = byte_val % 128
        let has_more: bool = byte_val >= 128

        # 第 5 组（shift=28）只允许保留 4 位：`low_bits` 超出 0x0F 即越过 u32 值域。
        if shift == 28 && low_bits > 15 {
            return Fail(wasm_binary_diagnostic("LEB128 编码溢出，超过 u32 范围", offset))
        }

        # 每组贡献 `low_bits * 2^shift`：移位是位域语义，不是乘 128 的次数。
        result = result + (low_bits << shift)

        pos = pos + 1

        if !has_more {
            return Fine(Leb128Decoded {
                value: result,
                consumed: pos - offset
            })
        }

        shift = shift + 7

        if shift >= 35 {
            return Fail(wasm_binary_diagnostic("LEB128 编码溢出，超过 u32 范围", offset))
        }
    }

    return Fail(wasm_binary_diagnostic("LEB128 编码意外结束", offset))
}

micro leb128_decode_i32(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<i32>> {
    let mut result: i32 = 0
    let mut shift: u32 = 0
    let mut pos: usize = offset
    let length: usize = data.length

    while pos < length {
        let byte: i32 = data[pos]
        let byte_val: u32 = byte as u32
        let low_bits: u32 = byte_val % 128
        let has_more: bool = byte_val >= 128

        # 第 5 组（shift=28）只有 bit 3 以下承载数值：bit 4..6 必须全部等于
        # bit 3（符号扩展位），混合取值即越过 i32 值域。与 unsigned 分支的
        # 末组越界拒收合同一致；非最小编码（多余符号组）两侧同样接受。
        if shift == 28 && low_bits > 7 && low_bits < 120 {
            return Fail(wasm_binary_diagnostic("LEB128 有符号编码溢出，超过 i32 范围", offset))
        }

        # 每组贡献 `low_bits * 2^shift`：移位是位域语义，不是乘 128 的次数。
        # 末组先掩掉符号扩展位——其贡献是 2^32 的整数倍，mod 2^32 消没，
        # 回绕累加即终值，无需再减。
        let mut payload: u32 = low_bits
        if shift == 28 {
            payload = low_bits % 16
        }
        result = result + ((payload << shift) as i32)

        pos = pos + 1

        if !has_more {
            # 符号位是末组 bit 6（不是 bit 5）：置位时真实值 = 累加值 − 2^(shift+7)。
            if shift < 28 && low_bits >= 64 {
                result = result - (((1 as u32) << (shift + 7)) as i32)
            }
            return Fine(Leb128Decoded {
                value: result,
                consumed: pos - offset
            })
        }

        shift = shift + 7

        if shift >= 35 {
            return Fail(wasm_binary_diagnostic("LEB128 有符号编码溢出", offset))
        }
    }

    return Fail(wasm_binary_diagnostic("LEB128 有符号编码意外结束", offset))
}

micro wasm_read_u8(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<i32>> {
    if offset >= data.length {
        return Fail(wasm_binary_diagnostic("读取 u8 时数据不足", offset))
    }
    return Fine(Leb128Decoded {
        value: data[offset],
        consumed: 1
    })
}

micro wasm_read_u32_le(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<u32>> {
    if offset + 4 > data.length {
        return Fail(wasm_binary_diagnostic("读取 u32 时数据不足", offset))
    }
    let b0: u32 = data[offset] as u32
    let b1: u32 = data[offset + 1] as u32
    let b2: u32 = data[offset + 2] as u32
    let b3: u32 = data[offset + 3] as u32
    let value: u32 = b0 + b1 * 256 + b2 * 65536 + b3 * 16777216
    return Fine(Leb128Decoded {
        value: value,
        consumed: 4
    })
}

micro wasm_read_bytes(data: [i32], offset: usize, count: usize) -> WasmBinaryResult<Leb128Decoded<[i32]>> {
    if offset + count > data.length {
        return Fail(wasm_binary_diagnostic("读取字节数组时数据不足", offset))
    }
    let mut result: ArrayList<i32> = ArrayList::new(count)
    let mut i: usize = 0
    while i < count {
        result.push(data[offset + i])
        i = i + 1
    }
    return Fine(Leb128Decoded {
        value: result.to_array(),
        consumed: count
    })
}

# 名字区 = LEB128 长度 + UTF-8 字节。严格解码：逐码点经 `std::text::decode_char_at`
# 消费（唯一 UTF-8 解码事实来源），任何非法序列（代理码位编码、过长编码、
# 截断序列、越界首字节）都结构化失败——不静默跳过、不以占位字符冒充成功。
micro wasm_read_name(data: [i32], offset: usize) -> WasmBinaryResult<Leb128Decoded<utf8>> {
    match leb128_decode_u32(data, offset) {
        case Fine(length_result):
            let length: usize = length_result.value as usize
            let str_offset: usize = offset + length_result.consumed
            match wasm_read_bytes(data, str_offset, length) {
                case Fine(bytes_result):
                    let mut raw: ArrayList<u8> = ArrayList::new(length)
                    let mut i: usize = 0
                    while i < bytes_result.value.length {
                        raw.push(bytes_result.value[i] as u8)
                        i = i + 1
                    }

                    let bytes: [u8] = raw.to_array()
                    let mut builder: Utf8Builder = Utf8Builder::new(length)
                    let mut cursor: usize = 0
                    while cursor < bytes.length {
                        match std::text::decode_char_at(bytes, cursor) {
                            case Fine(decoded):
                                builder.append(decoded.0)
                                cursor = cursor + decoded.1
                            case Fail(error):
                                return Fail(wasm_binary_diagnostic("名字区域不是合法 UTF-8，无法解码为文本", str_offset + cursor))
                        }
                    }

                    return Fine(Leb128Decoded {
                        value: builder.build(),
                        consumed: length_result.consumed + bytes_result.consumed
                    })
                case Fail(error):
                    return Fail(error)
            }
        case Fail(error):
            return Fail(error)
    }
}

structure WasmConstants {
}

micro wasm_check_magic(data: [i32], offset: usize) -> bool {
    if offset + 4 > data.length {
        return false
    }
    return data[offset] == 0
        && data[offset + 1] == b'a'
        && data[offset + 2] == b's'
        && data[offset + 3] == b'm'
}

micro wasm_value_type_name(code: i32) -> utf8 {
    if code == 127 {
        return "i32"
    }
    if code == 126 {
        return "i64"
    }
    if code == 125 {
        return "f32"
    }
    if code == 124 {
        return "f64"
    }
    if code == 112 {
        return "funcref"
    }
    if code == 111 {
        return "externref"
    }
    return "unknown"
}

micro wasm_func_type_form() -> i32 {
    return 96
}

micro wasm_global_mutable() -> i32 {
    return 1
}
