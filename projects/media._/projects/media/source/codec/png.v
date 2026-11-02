namespace media;

using std.data::{DataOutcome, DataDiagnostic, Error, data_outcome_with, data_outcome_has_errors, data_outcome_diagnostics, data_outcome_value, new_data_diagnostic, new_data_span};
using std.data.binary.codec::{DataByteCursor, Big, data_byte_cursor, data_byte_view_of};
using std.data.digest::{digest_crc32};

# png.v — PNG（RFC 2083）容器层与扫描线滤波重建。
#
# 本批落地：签名校验、chunk 遍历、CRC-32 校验（归 `std.data.digest`）、IHDR 模型、
# IDAT 聚合、滤波重建（None/Sub/Up/Average/Paeth）。
#
# IDAT 载荷是 zlib 流：解压归 `std.data.binary.codec` 的 deflate（当前已知缺口，见 readme 缺口清单）。
# `media_png_read` 在 IDAT 聚合后停于 `media.png.inflate_unavailable` 结构化诊断；
# 几何信息（宽/高/像素格式）随部分结果照常返回。不硬编码、不 fallback。
#
# 数值纪律：字节/字段值一律先 `as u64` 再比较；右移经 u64 载道；
# IDAT 聚合为逐字节推入（函数式数组），大块性能随 std.collection 块拷贝能力后续补齐。

# PNG 签名（8 字节，算法固有常数）。
micro media_png_signature() -> [u8] {
    return [137 as u8, 80 as u8, 78 as u8, 71 as u8, 13 as u8, 10 as u8, 26 as u8, 10 as u8]
}

# chunk 类型的大端 32 位值（4 个 ASCII 字节）。
micro media_png_chunk_ihdr() -> u64 {
    return 0x49484452
}

micro media_png_chunk_idat() -> u64 {
    return 0x49444154
}

micro media_png_chunk_iend() -> u64 {
    return 0x49454E44
}

micro media_png_ihdr_data_bytes() -> u64 {
    return 13
}

micro media_png_bit_depth_supported() -> u64 {
    return 8
}

# IHDR 解析结果：几何与像素格式；`seen` 标记是否已遇到合法 IHDR。
structure MediaPngImageHeader {
    seen: bool
    width: usize
    height: usize
    format: MediaPixelFormat
}

micro media_png_header_absent() -> MediaPngImageHeader {
    return MediaPngImageHeader { seen: false, width: 0, height: 0, format: Rgb8 }
}

# chunk CRC-32 的覆盖字节：类型 4 字节（大端）+ 数据。
# `std.data.digest` 是整缓冲合同，类型头与数据在此拼接后一次性计算。
micro media_png_chunk_crc_bytes(chunk_type: u64, data: [u8]) -> [u8] {
    let mut bytes: [u8] = []
    bytes = std::collection::push(bytes, ((chunk_type >> 24) & 255) as u8)
    bytes = std::collection::push(bytes, ((chunk_type >> 16) & 255) as u8)
    bytes = std::collection::push(bytes, ((chunk_type >> 8) & 255) as u8)
    bytes = std::collection::push(bytes, (chunk_type & 255) as u8)
    let mut index: usize = 0
    let total: usize = std::collection::array::length(data)
    while index < total {
        bytes = std::collection::push(bytes, std::collection::array::get(data, index))
        index = index + 1
    }
    return bytes
}

# IHDR 数据解析：13 字节，字段逐项校验；诊断聚合后随结果返回。
micro media_png_parse_ihdr(data: [u8], chunk_start: usize) -> DataOutcome<MediaPngImageHeader> {
    let mut header: MediaPngImageHeader = media_png_header_absent()
    let mut diagnostics: [DataDiagnostic] = []
    if std::collection::array::length(data) as u64 != media_png_ihdr_data_bytes() {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.bad_ihdr_length", Error, "IHDR 数据不是 13 字节", new_data_span(chunk_start, chunk_start)))
        return data_outcome_with(header, diagnostics)
    }
    let mut cursor: DataByteCursor = data_byte_cursor(data_byte_view_of(data))
    let raw_width: u64 = data_outcome_value(cursor.read_u32(Big)) as u64
    let raw_height: u64 = data_outcome_value(cursor.read_u32(Big)) as u64
    let bit_depth: u64 = data_outcome_value(cursor.read_u8()) as u64
    let color_type: u64 = data_outcome_value(cursor.read_u8()) as u64
    let compression: u64 = data_outcome_value(cursor.read_u8()) as u64
    let filter_method: u64 = data_outcome_value(cursor.read_u8()) as u64
    let interlace: u64 = data_outcome_value(cursor.read_u8()) as u64
    let mut valid: bool = true
    if raw_width == 0 || raw_height == 0 {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.invalid_dimension", Error, "IHDR 宽度或高度为 0", new_data_span(chunk_start, chunk_start)))
        valid = false
    }
    if raw_width > media_raster_max_side() as u64 || raw_height > media_raster_max_side() as u64 {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.image.too_large", Error, "IHDR 单侧尺寸超过 2^24 上限", new_data_span(chunk_start, chunk_start)))
        valid = false
    }
    if bit_depth != media_png_bit_depth_supported() {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.unsupported_bit_depth", Error, "位深不是 8", new_data_span(chunk_start, chunk_start)))
        valid = false
    }
    let mut format: MediaPixelFormat = Rgb8
    if color_type == 0 {
        format = Gray8
    } else if color_type == 2 {
        format = Rgb8
    } else if color_type == 6 {
        format = Rgba8
    } else {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.unsupported_color_type", Error, "颜色类型非 0/2/6（调色板与 gray+alpha 未落地）", new_data_span(chunk_start, chunk_start)))
        valid = false
    }
    if compression != 0 {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.bad_compression_method", Error, "压缩方法字节非 0", new_data_span(chunk_start, chunk_start)))
        valid = false
    }
    if filter_method != 0 {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.bad_filter_method", Error, "滤波方法字节非 0", new_data_span(chunk_start, chunk_start)))
        valid = false
    }
    if interlace != 0 {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.unsupported_interlace", Error, "Adam7 隔行未在第一批落地", new_data_span(chunk_start, chunk_start)))
        valid = false
    }
    if valid {
        header = MediaPngImageHeader { seen: true, width: raw_width as usize, height: raw_height as usize, format: format }
    }
    return data_outcome_with(header, diagnostics)
}

# PNG 读入（容器层）。签名 → chunk 遍历（CRC 校验）→ IHDR/IDAT 聚合 →
# 停于 inflate 缺口。错误容许：CRC 不符与未知关键 chunk 只聚合诊断，不中断遍历。
micro media_png_read(bytes: [u8]) -> DataOutcome<MediaRaster> {
    let placeholder: MediaRaster = media_raster_placeholder(Rgb8)
    let signature: [u8] = media_png_signature()
    let total: usize = std::collection::array::length(bytes)
    if (total as u64) < 8 {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.png.truncated_signature", Error, "输入不足 8 字节签名", new_data_span(0, 0))]
        )
    }
    let mut signature_index: usize = 0
    while signature_index < 8 {
        if (std::collection::array::get(bytes, signature_index) as u64) != (std::collection::array::get(signature, signature_index) as u64) {
            return data_outcome_with(
                placeholder,
                [new_data_diagnostic("media.png.bad_signature", Error, "签名不符", new_data_span(0, 8))]
            )
        }
        signature_index = signature_index + 1
    }
    let mut cursor: DataByteCursor = data_byte_cursor(data_byte_view_of(bytes))
    # 游标越过签名 8 字节（长度已校验，不会失败），之后 position() 即文件绝对偏移
    let signature_skip: DataOutcome<usize> = cursor.skip(8)
    if data_outcome_has_errors(signature_skip) {
        return data_outcome_with(placeholder, data_outcome_diagnostics(signature_skip))
    }
    let mut diagnostics: [DataDiagnostic] = []
    let mut header: MediaPngImageHeader = media_png_header_absent()
    let mut idat: [u8] = []
    let mut iend_seen: bool = false
    let mut walking: bool = true
    while walking {
        if (cursor.remaining() as u64) < 8 {
            if cursor.remaining() > 0 {
                let at: usize = cursor.position()
                diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.truncated_chunk", Error, "尾部不足 chunk 头（4+4）", new_data_span(at, at)))
            }
            walking = false
        } else {
            let chunk_start: usize = cursor.position()
            let chunk_length: u64 = data_outcome_value(cursor.read_u32(Big)) as u64
            let chunk_type: u64 = data_outcome_value(cursor.read_u32(Big)) as u64
            if (cursor.remaining() as u64) < chunk_length + 4 {
                diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.truncated_chunk", Error, "chunk 数据或 CRC 截断", new_data_span(chunk_start, chunk_start)))
                walking = false
            } else {
                let mut data: [u8] = []
                let mut data_index: usize = 0
                let data_total: usize = chunk_length as usize
                while data_index < data_total {
                    data = std::collection::push(data, data_outcome_value(cursor.read_u8()))
                    data_index = data_index + 1
                }
                let crc_read: u64 = data_outcome_value(cursor.read_u32(Big)) as u64
                let crc_actual: u64 = digest_crc32(media_png_chunk_crc_bytes(chunk_type, data)) as u64
                if crc_actual != crc_read {
                    diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.crc_mismatch", Error, "chunk CRC-32 校验不符", new_data_span(chunk_start, chunk_start)))
                }
                if chunk_type == media_png_chunk_ihdr() {
                    if !header.seen {
                        let ihdr_outcome: DataOutcome<MediaPngImageHeader> = media_png_parse_ihdr(data, chunk_start)
                        header = data_outcome_value(ihdr_outcome)
                        let inner: [DataDiagnostic] = data_outcome_diagnostics(ihdr_outcome)
                        let mut inner_index: usize = 0
                        while inner_index < std::collection::array::length(inner) {
                            diagnostics = std::collection::push(diagnostics, std::collection::array::get(inner, inner_index))
                            inner_index = inner_index + 1
                        }
                    }
                } else if chunk_type == media_png_chunk_idat() {
                    let mut append_index: usize = 0
                    while append_index < data_total {
                        idat = std::collection::push(idat, std::collection::array::get(data, append_index))
                        append_index = append_index + 1
                    }
                } else if chunk_type == media_png_chunk_iend() {
                    iend_seen = true
                    walking = false
                } else {
                    # 关键位：类型首字节的第 5 位（大端 32 位值的第 29 位）为 0 即关键 chunk
                    if ((chunk_type >> 29) & 1) == 0 {
                        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.unknown_critical_chunk", Error, "未知关键 chunk", new_data_span(chunk_start, chunk_start)))
                    }
                }
            }
        }
    }
    if !header.seen {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.missing_ihdr", Error, "首个 chunk 非 IHDR 或 IHDR 非法", new_data_span(8, 8)))
    }
    if header.seen && std::collection::array::length(idat) == 0 {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.missing_idat", Error, "无 IDAT", new_data_span(8, 8)))
    }
    if header.seen && !iend_seen {
        let at: usize = cursor.position()
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.missing_iend", Error, "流结束于 IEND 之前", new_data_span(at, at)))
    }
    if !header.seen {
        return data_outcome_with(placeholder, diagnostics)
    }
    # 几何已知：分配零初始化栅格承载部分结果
    let raster_outcome: DataOutcome<MediaRaster> = media_raster(header.width, header.height, header.format)
    if data_outcome_has_errors(raster_outcome) {
        return data_outcome_with(placeholder, data_outcome_diagnostics(raster_outcome))
    }
    let raster: MediaRaster = data_outcome_value(raster_outcome)
    if std::collection::array::length(idat) == 0 {
        return data_outcome_with(raster, diagnostics)
    }
    # 当前已知缺口：IDAT 是 zlib 流，解压归 `std.data.binary.codec` 的 deflate。
    # codec 落地前如实停在结构化诊断，几何信息随上面的零初始化栅格返回。
    let at: usize = cursor.position()
    diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.inflate_unavailable", Error, "IDAT 解压依赖 std.data.binary.codec 的 deflate（当前已知缺口，见 readme 缺口清单）", new_data_span(at, at)))
    return data_outcome_with(raster, diagnostics)
}

# Paeth 预测器（RFC 2083）：a 左、b 上、c 左上（均已重建的字节值）。
micro media_png_paeth_predictor(a: u64, b: u64, c: u64) -> u64 {
    let left: i64 = a as i64
    let up: i64 = b as i64
    let up_left: i64 = c as i64
    let estimate: i64 = left + up - up_left
    let distance_left: i64 = media_internal_abs_i64(estimate - left)
    let distance_up: i64 = media_internal_abs_i64(estimate - up)
    let distance_up_left: i64 = media_internal_abs_i64(estimate - up_left)
    if distance_left <= distance_up && distance_left <= distance_up_left {
        return a
    }
    if distance_up <= distance_up_left {
        return b
    }
    return c
}

micro media_internal_abs_i64(value: i64) -> i64 {
    if value < 0 {
        return 0 - value
    }
    return value
}

# 扫描线滤波重建：输入 `高 × (1 + 行字节)` 的原始滤波流，输出 `高 × 行字节` 像素。
# `channels` 即每像素字节数（位深 8）。加法均为模 256（u64 载道累加后 & 255）。
# 错误容许：未知滤波类型的行保留为零，附诊断后继续后续行。
micro media_png_unfilter(raw: [u8], width: usize, height: usize, channels: usize) -> DataOutcome<[u8]> {
    let row_bytes: u64 = (width as u64) * (channels as u64)
    let expected: u64 = (height as u64) * (1 + row_bytes)
    if std::collection::array::length(raw) as u64 != expected {
        return data_outcome_with(
            [],
            [new_data_diagnostic("media.png.unfilter_length_mismatch", Error, "滤波流长度不等于 高×(1+行字节)", new_data_span(0, 0))]
        )
    }
    if expected > media_raster_max_bytes() {
        return data_outcome_with(
            [],
            [new_data_diagnostic("media.image.too_large", Error, "重建像素字节总量超过 2^32-1 上限", new_data_span(0, 0))]
        )
    }
    let out: [u8] = std::collection::array::new::<u8>(((height as u64) * row_bytes) as usize)
    let row_size: usize = row_bytes as usize
    let mut diagnostics: [DataDiagnostic] = []
    let row_pitch: u64 = 1 + row_bytes
    let mut row: usize = 0
    while row < height {
        let raw_base: usize = ((row as u64) * row_pitch) as usize
        let out_base: usize = ((row as u64) * row_bytes) as usize
        let filter_type: u64 = std::collection::array::get(raw, raw_base) as u64
        if filter_type > 4 {
            diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.png.unknown_filter_type", Error, "扫描线滤波类型大于 4", new_data_span(raw_base, raw_base)))
        } else {
            let mut column: usize = 0
            while column < row_size {
                let current: u64 = std::collection::array::get(raw, raw_base + 1 + column) as u64
                let mut left: u64 = 0
                if column >= channels {
                    left = std::collection::array::get(out, out_base + column - channels) as u64
                }
                let mut up: u64 = 0
                let mut up_left: u64 = 0
                if row > 0 {
                    up = std::collection::array::get(out, out_base + column - row_size) as u64
                    if column >= channels {
                        up_left = std::collection::array::get(out, out_base + column - row_size - channels) as u64
                    }
                }
                let mut reconstructed: u64 = current
                if filter_type == 1 {
                    reconstructed = current + left
                } else if filter_type == 2 {
                    reconstructed = current + up
                } else if filter_type == 3 {
                    reconstructed = current + ((left + up) >> 1)
                } else if filter_type == 4 {
                    reconstructed = current + media_png_paeth_predictor(left, up, up_left)
                }
                std::collection::array::set(out, out_base + column, (reconstructed & 255) as u8)
                column = column + 1
            }
        }
        row = row + 1
    }
    return data_outcome_with(out, diagnostics)
}
