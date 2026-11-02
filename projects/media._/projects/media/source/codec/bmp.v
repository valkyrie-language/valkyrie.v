namespace media;

using std.data::{DataOutcome, DataDiagnostic, Error, Warning, data_outcome_of, data_outcome_with, data_outcome_has_errors, data_outcome_diagnostics, data_outcome_value, new_data_diagnostic, new_data_span};
using std.data.binary.codec::{DataByteCursor, Little, data_byte_cursor, data_byte_view_of};

# bmp.v — BMP（Windows V3 / BITMAPINFOHEADER，24 位 BI_RGB）读写适配器。
#
# 布局：14 字节文件头 + 40 字节信息头 + 像素数据；像素行自底向上（正高度），
# 行字节数按 4 字节对齐补零，像素按 BGR 字节序存储。
# 本批范围：仅 24 位无压缩；top-down（负高度）与调色板位深结构化失败，不猜测解析。
#
# 数值纪律：字节/字值一律先 `as u64` 再比较 —— wasm 后端无 u8/u16 比较 provider；
# 右移经 u64 载道（wasm 后端 `u32 >> n` 缺陷）。

micro media_bmp_magic_b() -> u64 {
    return 66
}

micro media_bmp_magic_m() -> u64 {
    return 77
}

# 文件头 14 + 信息头 40。
micro media_bmp_header_total_bytes() -> u64 {
    return 54
}

micro media_bmp_info_header_bytes() -> u64 {
    return 40
}

micro media_bmp_planes_expected() -> u64 {
    return 1
}

micro media_bmp_bit_depth_supported() -> u64 {
    return 24
}

micro media_bmp_compression_rgb() -> u64 {
    return 0
}

# 有符号 32 位字段的正数上界：超过即负值（宽度负值非法，高度负值为 top-down）。
micro media_bmp_signed_positive_limit() -> u64 {
    return 2147483648
}

# 写出时声明的像素密度（72 DPI 换算值，纯展示元数据）。
micro media_bmp_default_resolution_ppm() -> u64 {
    return 2835
}

# u32 小端字段写出（u64 载道右移后逐字节截回）。
micro media_internal_write_u32_le(bytes: [u8], offset: usize, value: u64) -> unit {
    std::collection::array::set(bytes, offset, (value & 255) as u8)
    std::collection::array::set(bytes, offset + 1, ((value >> 8) & 255) as u8)
    std::collection::array::set(bytes, offset + 2, ((value >> 16) & 255) as u8)
    std::collection::array::set(bytes, offset + 3, ((value >> 24) & 255) as u8)
}

micro media_internal_write_u16_le(bytes: [u8], offset: usize, value: u64) -> unit {
    std::collection::array::set(bytes, offset, (value & 255) as u8)
    std::collection::array::set(bytes, offset + 1, ((value >> 8) & 255) as u8)
}

# 行字节数（不含填充）：宽 × 3。
micro media_internal_bmp_row_bytes(width: usize) -> usize {
    return width * 3
}

# 行填充字节数：对齐到 4 字节边界。
micro media_internal_bmp_row_padding(width: usize) -> usize {
    let row_bytes: usize = media_internal_bmp_row_bytes(width)
    let rem: usize = row_bytes % 4
    if rem == 0 {
        return 0
    }
    return 4 - rem
}

# 文件字节总量守卫：BMP 头部声明为 32 位字段，总量不得越 2^32-1。
micro media_internal_bmp_file_too_large(file_bytes: u64) -> bool {
    return file_bytes > media_raster_max_bytes()
}

# BMP 写出：RGB8 栅格（Gray8/Rgba8 经 `media_color_convert` 归一到 RGB8）。
# 一次分配整个文件后按偏移填充；保留字段与行填充显式写零，不依赖分配初值。
micro media_bmp_write(source: MediaRaster) -> DataOutcome<[u8]> {
    if !media_raster_is_consistent(source) {
        return data_outcome_with(
            [],
            [new_data_diagnostic("media.image.buffer_length_mismatch", Error, "源栅格几何与像素缓冲长度不符", new_data_span(0, 0))]
        )
    }
    let rgb: MediaRaster = data_outcome_value(media_color_convert(source, Rgb8))
    let row_bytes: usize = media_internal_bmp_row_bytes(rgb.width)
    let padding: usize = media_internal_bmp_row_padding(rgb.width)
    let stride: u64 = ((row_bytes + padding) as u64) * (rgb.height as u64)
    let file_bytes: u64 = media_bmp_header_total_bytes() + stride
    if media_internal_bmp_file_too_large(file_bytes) {
        return data_outcome_with(
            [],
            [new_data_diagnostic("media.image.too_large", Error, "BMP 文件字节总量超过 2^32-1 上限", new_data_span(0, 0))]
        )
    }
    let out: [u8] = std::collection::array::new::<u8>(file_bytes as usize)
    # 魔数 'B' 'M'
    std::collection::array::set(out, 0, media_bmp_magic_b() as u8)
    std::collection::array::set(out, 1, media_bmp_magic_m() as u8)
    media_internal_write_u32_le(out, 2, file_bytes)
    media_internal_write_u32_le(out, 6, 0)
    media_internal_write_u32_le(out, 10, media_bmp_header_total_bytes())
    media_internal_write_u32_le(out, 14, media_bmp_info_header_bytes())
    media_internal_write_u32_le(out, 18, rgb.width as u64)
    media_internal_write_u32_le(out, 22, rgb.height as u64)
    media_internal_write_u16_le(out, 26, media_bmp_planes_expected())
    media_internal_write_u16_le(out, 28, media_bmp_bit_depth_supported())
    media_internal_write_u32_le(out, 30, media_bmp_compression_rgb())
    media_internal_write_u32_le(out, 34, stride)
    media_internal_write_u32_le(out, 38, media_bmp_default_resolution_ppm())
    media_internal_write_u32_le(out, 42, media_bmp_default_resolution_ppm())
    media_internal_write_u32_le(out, 46, 0)
    media_internal_write_u32_le(out, 50, 0)
    let mut file_row: usize = 0
    while file_row < rgb.height {
        let image_row: usize = rgb.height - 1 - file_row
        let row_offset: u64 = media_bmp_header_total_bytes() + ((file_row as u64) * (((row_bytes + padding) as u64)))
        let mut pixel: usize = 0
        while pixel < rgb.width {
            let source_base: u64 = (((image_row as u64) * (rgb.width as u64)) + (pixel as u64)) * 3
            let target_base: usize = row_offset as usize + pixel * 3
            std::collection::array::set(out, target_base, std::collection::array::get(rgb.pixels, source_base as usize + 2))
            std::collection::array::set(out, target_base + 1, std::collection::array::get(rgb.pixels, source_base as usize + 1))
            std::collection::array::set(out, target_base + 2, std::collection::array::get(rgb.pixels, source_base as usize))
            pixel = pixel + 1
        }
        let mut pad: usize = 0
        while pad < padding {
            std::collection::array::set(out, row_offset as usize + row_bytes + pad, 0 as u8)
            pad = pad + 1
        }
        file_row = file_row + 1
    }
    return data_outcome_of(out)
}

# BMP 读入：头字段逐项校验；行数据截断保留已读前缀（其余为零初始化）。
micro media_bmp_read(bytes: [u8]) -> DataOutcome<MediaRaster> {
    let placeholder: MediaRaster = media_raster_placeholder(Rgb8)
    let mut cursor: DataByteCursor = data_byte_cursor(data_byte_view_of(bytes))
    if (cursor.remaining() as u64) < media_bmp_header_total_bytes() {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.truncated_header", Error, "输入不足 54 字节头", new_data_span(0, 0))]
        )
    }
    let magic_b: u64 = data_outcome_value(cursor.read_u8()) as u64
    let magic_m: u64 = data_outcome_value(cursor.read_u8()) as u64
    if magic_b != media_bmp_magic_b() || magic_m != media_bmp_magic_m() {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.bad_magic", Error, "魔数非 BM", new_data_span(0, 2))]
        )
    }
    let declared_file_size: u64 = data_outcome_value(cursor.read_u32(Little)) as u64
    let mut diagnostics: [DataDiagnostic] = []
    if declared_file_size != std::collection::array::length(bytes) as u64 {
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.bmp.size_field_mismatch", Warning, "文件长度与头声明不符", new_data_span(2, 6)))
    }
    let skip_reserved: DataOutcome<usize> = cursor.skip(4)
    if data_outcome_has_errors(skip_reserved) {
        return data_outcome_with(placeholder, data_outcome_diagnostics(skip_reserved))
    }
    let data_offset: u64 = data_outcome_value(cursor.read_u32(Little)) as u64
    let header_size: u64 = data_outcome_value(cursor.read_u32(Little)) as u64
    if header_size != media_bmp_info_header_bytes() {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.unsupported_header_size", Error, "信息头尺寸不是 40（仅支持 BITMAPINFOHEADER）", new_data_span(14, 18))]
        )
    }
    let raw_width: u64 = data_outcome_value(cursor.read_u32(Little)) as u64
    let raw_height: u64 = data_outcome_value(cursor.read_u32(Little)) as u64
    if raw_width == 0 || raw_height == 0 {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.invalid_dimension", Error, "宽度或高度为 0", new_data_span(18, 26))]
        )
    }
    if raw_width >= media_bmp_signed_positive_limit() {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.invalid_dimension", Error, "宽度为负值（非法）", new_data_span(18, 22))]
        )
    }
    if raw_height >= media_bmp_signed_positive_limit() {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.unsupported_layout", Error, "高度为负（top-down 行序）未在第一批落地", new_data_span(22, 26))]
        )
    }
    let planes: u64 = data_outcome_value(cursor.read_u16(Little)) as u64
    if planes != media_bmp_planes_expected() {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.bad_planes", Error, "planes 字段不是 1", new_data_span(26, 28))]
        )
    }
    let bit_depth: u64 = data_outcome_value(cursor.read_u16(Little)) as u64
    if bit_depth != media_bmp_bit_depth_supported() {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.unsupported_bit_depth", Error, "位深不是 24", new_data_span(28, 30))]
        )
    }
    let compression: u64 = data_outcome_value(cursor.read_u32(Little)) as u64
    if compression != media_bmp_compression_rgb() {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.unsupported_compression", Error, "压缩方式不是 0（BI_RGB）", new_data_span(30, 34))]
        )
    }
    # 信息头剩余字段（图像大小、分辨率、色表）无语义消费，跳到数据偏移。
    let skip_rest: DataOutcome<usize> = cursor.skip(18)
    if data_outcome_has_errors(skip_rest) {
        return data_outcome_with(placeholder, data_outcome_diagnostics(skip_rest))
    }
    if data_offset < media_bmp_header_total_bytes() {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.bad_data_offset", Error, "像素数据偏移小于头长", new_data_span(10, 14))]
        )
    }
    let skip_gap: DataOutcome<usize> = cursor.skip((data_offset - media_bmp_header_total_bytes()) as usize)
    if data_outcome_has_errors(skip_gap) {
        return data_outcome_with(
            placeholder,
            [new_data_diagnostic("media.bmp.bad_data_offset", Error, "像素数据偏移越出输入", new_data_span(10, 14))]
        )
    }
    let raster_outcome: DataOutcome<MediaRaster> = media_raster(raw_width as usize, raw_height as usize, Rgb8)
    if data_outcome_has_errors(raster_outcome) {
        return data_outcome_with(placeholder, data_outcome_diagnostics(raster_outcome))
    }
    let raster: MediaRaster = data_outcome_value(raster_outcome)
    let row_bytes: usize = media_internal_bmp_row_bytes(raster.width)
    let padding: usize = media_internal_bmp_row_padding(raster.width)
    let mut file_row: usize = 0
    let mut truncated: bool = false
    while file_row < raster.height && !truncated {
        let image_row: usize = raster.height - 1 - file_row
        let mut pixel: usize = 0
        while pixel < raster.width && !truncated {
            let blue_step: DataOutcome<u8> = cursor.read_u8()
            let green_step: DataOutcome<u8> = cursor.read_u8()
            let red_step: DataOutcome<u8> = cursor.read_u8()
            if data_outcome_has_errors(blue_step) || data_outcome_has_errors(green_step) || data_outcome_has_errors(red_step) {
                truncated = true
            } else {
                let target_base: usize = (image_row * raster.width + pixel) * 3
                std::collection::array::set(raster.pixels, target_base, data_outcome_value(red_step))
                std::collection::array::set(raster.pixels, target_base + 1, data_outcome_value(green_step))
                std::collection::array::set(raster.pixels, target_base + 2, data_outcome_value(blue_step))
                pixel = pixel + 1
            }
        }
        if !truncated {
            let skip_padding: DataOutcome<usize> = cursor.skip(padding)
            if data_outcome_has_errors(skip_padding) {
                truncated = true
            }
        }
        file_row = file_row + 1
    }
    if truncated {
        let at: usize = cursor.position()
        diagnostics = std::collection::push(diagnostics, new_data_diagnostic("media.bmp.truncated_raster", Error, "行数据（含 4 字节对齐填充）不足", new_data_span(at, at)))
    }
    return data_outcome_with(raster, diagnostics)
}
