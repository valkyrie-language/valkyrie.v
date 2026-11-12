namespace std.data.binary.clr;

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};
using std.text::{Utf8Builder};

# 诊断类型收敛到 `std.diagnostic::Diagnostic`（统一合同，不再各自定义）。
# 位置单位合同：本包所有 `offset` / 诊断 span 一律为 PE/元数据流字节偏移；
# 产出的 `utf8` 值内部是 UTF-8 存储，其 `length()` / `slice()` 为码点口径。
# 两套坐标系只在 `Utf8Text` 显式视图（`bytes` / `byte_at`）处转换，不得互相冒充。

[tag(ClrBinaryResultKind)]
unite ClrBinaryResult<T> {
    [tag(0)]
    [constructor]
    Fine { value: T }
    [tag(1)]
    [constructor]
    Fail { error: Diagnostic }
}

micro clr_binary_diagnostic(message: utf8, offset: usize) -> Diagnostic {
    return new_diagnostic("std.data.binary.clr.defect", Error, message, new_span(offset, offset))
}

micro clr_read_u8(data: [i32], offset: usize) -> ClrBinaryResult<i32> {
    if offset >= data.length {
        return Fail(clr_binary_diagnostic("读取 u8 时数据不足", offset))
    }
    return Fine(data[offset])
}

micro clr_read_u16_le(data: [i32], offset: usize) -> ClrBinaryResult<u16> {
    if offset + 2 > data.length {
        return Fail(clr_binary_diagnostic("读取 u16 时数据不足", offset))
    }
    let b0: u16 = data[offset] as u16
    let b1: u16 = data[offset + 1] as u16
    let value: u16 = b0 + b1 * 256
    return Fine(value)
}

micro clr_read_u32_le(data: [i32], offset: usize) -> ClrBinaryResult<u32> {
    if offset + 4 > data.length {
        return Fail(clr_binary_diagnostic("读取 u32 时数据不足", offset))
    }
    let b0: u32 = data[offset] as u32
    let b1: u32 = data[offset + 1] as u32
    let b2: u32 = data[offset + 2] as u32
    let b3: u32 = data[offset + 3] as u32
    let value: u32 = b0 + b1 * 256 + b2 * 65536 + b3 * 16777216
    return Fine(value)
}

micro clr_read_bytes(data: [i32], offset: usize, count: usize) -> ClrBinaryResult<[i32]> {
    if offset + count > data.length {
        return Fail(clr_binary_diagnostic("读取字节数组时数据不足", offset))
    }
    let mut result: [i32] = []
    let mut i: usize = 0
    while i < count {
        push(result, data[offset + i])
        i = i + 1
    }
    return Fine(result)
}

# 严格 UTF-8 解码：`[offset, offset+length)` 区域逐码点经 `std::text::decode_char_at`
# 消费（唯一 UTF-8 解码事实来源），任何非法序列（代理码位编码、过长编码、
# 截断序列、越界首字节）都结构化失败——不做 ASCII 白名单映射、不以占位字符冒充成功。
micro clr_read_utf8(data: [i32], offset: usize, length: usize) -> ClrBinaryResult<utf8> {
    match clr_read_bytes(data, offset, length) {
        case Fine(bytes_i32):
            let mut raw: ArrayList<u8> = ArrayList::new(length)
            let mut i: usize = 0
            while i < bytes_i32.length {
                raw.push(bytes_i32[i] as u8)
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
                        return Fail(clr_binary_diagnostic("UTF-8 区域不是合法编码，无法解码为文本", offset + cursor))
                }
            }

            return Fine(builder.build())
        case Fail(error):
            return Fail(error)
    }
}

micro clr_check_pe_magic(data: [i32], offset: usize) -> bool {
    if offset + 4 > data.length {
        return false
    }
    return data[offset] == b'P'
        && data[offset + 1] == b'E'
        && data[offset + 2] == 0
        && data[offset + 3] == 0
}

micro clr_check_dos_magic(data: [i32], offset: usize) -> bool {
    if offset + 2 > data.length {
        return false
    }
    return data[offset] == b'M'
        && data[offset + 1] == b'Z'
}

micro clr_metadata_signature() -> u32 {
    return 0x42534A42
}

micro clr_data_directory_index() -> i32 {
    return 14
}
