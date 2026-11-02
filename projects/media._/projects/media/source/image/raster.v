namespace media;

using std.data::{DataOutcome, Error, data_outcome_of, data_outcome_with, data_outcome_has_errors, data_outcome_diagnostics, data_outcome_value, new_data_diagnostic, new_data_span};

# 图像栅格：宽度 × 高度 × 像素格式的打包行布局。
# 行主序（row-major），行内像素连续，像素内通道按格式顺序；
# `stride = width × channels`，无行尾填充 —— 填充是编解码层的格式关切，不进模型。

structure MediaRaster {
    width: usize
    height: usize
    format: MediaPixelFormat
    pixels: [u8]
}

# 尺寸上限：单侧不超过 2^24（算法固有之外的防御性上限，挡住溢出与分配风暴）。
micro media_raster_max_side() -> usize {
    return 16777216
}

# 像素字节总量上限 2^32-1：usize32 目标（wasm32）的偏移算术安全界。
micro media_raster_max_bytes() -> u64 {
    return 4294967295
}

# 空占位（poison）：尺寸归零、像素为空；对它的任何坐标访问必然越界报错。
micro media_raster_placeholder(format: MediaPixelFormat) -> MediaRaster {
    return MediaRaster { width: 0, height: 0, format: format, pixels: [] }
}

# 构造并分配零初始化像素缓冲；非法尺寸不产生部分分配，返回占位 + 诊断。
micro media_raster(width: usize, height: usize, format: MediaPixelFormat) -> DataOutcome<MediaRaster> {
    if width == 0 || height == 0 {
        return data_outcome_with(
            media_raster_placeholder(format),
            [new_data_diagnostic("media.image.empty_dimension", Error, "宽度或高度为 0", new_data_span(0, 0))]
        )
    }
    if width > media_raster_max_side() || height > media_raster_max_side() {
        return data_outcome_with(
            media_raster_placeholder(format),
            [new_data_diagnostic("media.image.too_large", Error, "单侧尺寸超过 2^24 上限", new_data_span(0, 0))]
        )
    }
    let total: u64 = (width as u64) * (height as u64) * (media_pixel_format_channels(format) as u64)
    if total > media_raster_max_bytes() {
        return data_outcome_with(
            media_raster_placeholder(format),
            [new_data_diagnostic("media.image.too_large", Error, "像素字节总量超过 2^32-1 上限", new_data_span(0, 0))]
        )
    }
    return data_outcome_of(MediaRaster { width: width, height: height, format: format, pixels: std::collection::array::new::<u8>(total as usize) })
}

# 包装既有像素缓冲；长度与 宽×高×通道 不符时返回占位 + 诊断。
micro media_raster_of_pixels(width: usize, height: usize, format: MediaPixelFormat, pixels: [u8]) -> DataOutcome<MediaRaster> {
    let expected: u64 = (width as u64) * (height as u64) * (media_pixel_format_channels(format) as u64)
    if std::collection::array::length(pixels) as u64 != expected {
        return data_outcome_with(
            media_raster_placeholder(format),
            [new_data_diagnostic("media.image.buffer_length_mismatch", Error, "像素缓冲长度与 宽×高×通道 不符", new_data_span(0, 0))]
        )
    }
    if width == 0 || height == 0 {
        return data_outcome_with(
            media_raster_placeholder(format),
            [new_data_diagnostic("media.image.empty_dimension", Error, "宽度或高度为 0", new_data_span(0, 0))]
        )
    }
    return data_outcome_of(MediaRaster { width: width, height: height, format: format, pixels: pixels })
}

# 一致性门禁：像素缓冲长度与声明几何相符。管线/适配器入口先过此门，
# 之后的内部偏移算术即被真实数组长度界定（usize32 安全）。
micro media_raster_is_consistent(raster: MediaRaster) -> bool {
    let expected: u64 = (raster.width as u64) * (raster.height as u64) * (media_pixel_format_channels(raster.format) as u64)
    return std::collection::array::length(raster.pixels) as u64 == expected
}

# 行字节数。调用方须先过一致性门禁（构造路径已保证 ≤ 2^26，usize32 安全）。
micro media_raster_stride(raster: MediaRaster) -> usize {
    return raster.width * media_pixel_format_channels(raster.format)
}

# 像素 (x, y) 的首通道字节偏移；越界结构化失败，不产生伪偏移。
micro media_raster_offset_of(raster: MediaRaster, x: usize, y: usize) -> DataOutcome<usize> {
    if x >= raster.width || y >= raster.height {
        return data_outcome_with(
            0,
            [new_data_diagnostic("media.image.out_of_bounds", Error, "像素坐标越界", new_data_span(0, 0))]
        )
    }
    let offset: u64 = (((y as u64) * (raster.width as u64)) + (x as u64)) * (media_pixel_format_channels(raster.format) as u64)
    if offset >= std::collection::array::length(raster.pixels) as u64 {
        return data_outcome_with(
            0,
            [new_data_diagnostic("media.image.out_of_bounds", Error, "像素偏移越出缓冲（几何与长度不一致）", new_data_span(0, 0))]
        )
    }
    return data_outcome_of(offset as usize)
}

# 读单个通道值；坐标或通道越界结构化失败。
micro media_raster_read_channel(raster: MediaRaster, x: usize, y: usize, channel: usize) -> DataOutcome<u8> {
    if channel >= media_pixel_format_channels(raster.format) {
        return data_outcome_with(
            0 as u8,
            [new_data_diagnostic("media.image.bad_channel", Error, "通道下标越出像素格式通道数", new_data_span(0, 0))]
        )
    }
    let offset_outcome: DataOutcome<usize> = media_raster_offset_of(raster, x, y)
    if data_outcome_has_errors(offset_outcome) {
        return data_outcome_with(0 as u8, data_outcome_diagnostics(offset_outcome))
    }
    return data_outcome_of(std::collection::array::get(raster.pixels, data_outcome_value(offset_outcome) + channel))
}

# 写单个通道值；返回写入偏移，坐标或通道越界结构化失败（返回 0 + 诊断）。
micro media_raster_write_channel(raster: MediaRaster, x: usize, y: usize, channel: usize, value: u8) -> DataOutcome<usize> {
    if channel >= media_pixel_format_channels(raster.format) {
        return data_outcome_with(
            0,
            [new_data_diagnostic("media.image.bad_channel", Error, "通道下标越出像素格式通道数", new_data_span(0, 0))]
        )
    }
    let offset_outcome: DataOutcome<usize> = media_raster_offset_of(raster, x, y)
    if data_outcome_has_errors(offset_outcome) {
        return data_outcome_with(0, data_outcome_diagnostics(offset_outcome))
    }
    let offset: usize = data_outcome_value(offset_outcome) + channel
    std::collection::array::set(raster.pixels, offset, value)
    return data_outcome_of(offset)
}
