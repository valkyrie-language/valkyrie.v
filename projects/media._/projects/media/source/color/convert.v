namespace media;

using std.data::{DataOutcome, Error, data_outcome_of, data_outcome_with, data_outcome_value, new_data_diagnostic, new_data_span};

# 颜色格式转换：Gray8 / Rgb8 / Rgba8 之间的像素级映射。
#
# 灰度化用 ITU-R BT.601 的整数近似 (r*77 + g*150 + b*29) >> 8：
# 系数为算法固有常数；乘加在 u64 载道进行（wasm 后端 `u32 >> n` 缺陷，见包头说明）。

micro media_color_luma_weight_red() -> u64 {
    return 77
}

micro media_color_luma_weight_green() -> u64 {
    return 150
}

micro media_color_luma_weight_blue() -> u64 {
    return 29
}

micro media_color_alpha_opaque() -> u8 {
    return 255
}

# 格式转换入口。同格式直通（不复制）；跨格式分配新栅格逐像素映射。
# 源不一致（几何与缓冲长度不符）时不产生部分结果，返回占位 + 诊断。
micro media_color_convert(source: MediaRaster, target: MediaPixelFormat) -> DataOutcome<MediaRaster> {
    if !media_raster_is_consistent(source) {
        return data_outcome_with(
            media_raster_placeholder(target),
            [new_data_diagnostic("media.image.buffer_length_mismatch", Error, "源栅格几何与像素缓冲长度不符", new_data_span(0, 0))]
        )
    }
    match source.format {
        case Gray8:
            match target {
                case Gray8:
                    return data_outcome_of(source)
                case Rgb8:
                    return media_internal_gray_to_rgb(source)
                case Rgba8:
                    return media_internal_gray_to_rgba(source)
            }
        case Rgb8:
            match target {
                case Gray8:
                    return media_internal_rgb_to_gray(source)
                case Rgb8:
                    return data_outcome_of(source)
                case Rgba8:
                    return media_internal_rgb_to_rgba(source)
            }
        case Rgba8:
            match target {
                case Gray8:
                    return media_internal_rgba_to_gray(source)
                case Rgb8:
                    return media_internal_rgba_to_rgb(source)
                case Rgba8:
                    return data_outcome_of(source)
            }
    }
}

# 灰度 → RGB：三通道复制同一灰度值。
micro media_internal_gray_to_rgb(source: MediaRaster) -> DataOutcome<MediaRaster> {
    let target: MediaRaster = data_outcome_value(media_raster(source.width, source.height, Rgb8))
    let total: usize = std::collection::array::length(source.pixels)
    let mut source_offset: usize = 0
    let mut target_offset: usize = 0
    while source_offset < total {
        let gray: u8 = std::collection::array::get(source.pixels, source_offset)
        std::collection::array::set(target.pixels, target_offset, gray)
        std::collection::array::set(target.pixels, target_offset + 1, gray)
        std::collection::array::set(target.pixels, target_offset + 2, gray)
        source_offset = source_offset + 1
        target_offset = target_offset + 3
    }
    return data_outcome_of(target)
}

# 灰度 → RGBA：三通道复制 + 不透明 alpha。
micro media_internal_gray_to_rgba(source: MediaRaster) -> DataOutcome<MediaRaster> {
    let target: MediaRaster = data_outcome_value(media_raster(source.width, source.height, Rgba8))
    let total: usize = std::collection::array::length(source.pixels)
    let mut source_offset: usize = 0
    let mut target_offset: usize = 0
    while source_offset < total {
        let gray: u8 = std::collection::array::get(source.pixels, source_offset)
        std::collection::array::set(target.pixels, target_offset, gray)
        std::collection::array::set(target.pixels, target_offset + 1, gray)
        std::collection::array::set(target.pixels, target_offset + 2, gray)
        std::collection::array::set(target.pixels, target_offset + 3, media_color_alpha_opaque())
        source_offset = source_offset + 1
        target_offset = target_offset + 4
    }
    return data_outcome_of(target)
}

# RGB → RGBA：补不透明 alpha。
micro media_internal_rgb_to_rgba(source: MediaRaster) -> DataOutcome<MediaRaster> {
    let target: MediaRaster = data_outcome_value(media_raster(source.width, source.height, Rgba8))
    let total: usize = std::collection::array::length(source.pixels)
    let mut source_offset: usize = 0
    let mut target_offset: usize = 0
    while source_offset < total {
        std::collection::array::set(target.pixels, target_offset, std::collection::array::get(source.pixels, source_offset))
        std::collection::array::set(target.pixels, target_offset + 1, std::collection::array::get(source.pixels, source_offset + 1))
        std::collection::array::set(target.pixels, target_offset + 2, std::collection::array::get(source.pixels, source_offset + 2))
        std::collection::array::set(target.pixels, target_offset + 3, media_color_alpha_opaque())
        source_offset = source_offset + 3
        target_offset = target_offset + 4
    }
    return data_outcome_of(target)
}

# RGBA → RGB：丢弃 alpha。
micro media_internal_rgba_to_rgb(source: MediaRaster) -> DataOutcome<MediaRaster> {
    let target: MediaRaster = data_outcome_value(media_raster(source.width, source.height, Rgb8))
    let total: usize = std::collection::array::length(source.pixels)
    let mut source_offset: usize = 0
    let mut target_offset: usize = 0
    while source_offset < total {
        std::collection::array::set(target.pixels, target_offset, std::collection::array::get(source.pixels, source_offset))
        std::collection::array::set(target.pixels, target_offset + 1, std::collection::array::get(source.pixels, source_offset + 1))
        std::collection::array::set(target.pixels, target_offset + 2, std::collection::array::get(source.pixels, source_offset + 2))
        source_offset = source_offset + 4
        target_offset = target_offset + 3
    }
    return data_outcome_of(target)
}

# RGB → 灰度：BT.601 整数 luma。
micro media_internal_rgb_to_gray(source: MediaRaster) -> DataOutcome<MediaRaster> {
    let target: MediaRaster = data_outcome_value(media_raster(source.width, source.height, Gray8))
    let total: usize = std::collection::array::length(source.pixels)
    let mut source_offset: usize = 0
    let mut target_index: usize = 0
    while source_offset < total {
        let red: u64 = std::collection::array::get(source.pixels, source_offset) as u64
        let green: u64 = std::collection::array::get(source.pixels, source_offset + 1) as u64
        let blue: u64 = std::collection::array::get(source.pixels, source_offset + 2) as u64
        let luma: u8 = ((red * media_color_luma_weight_red() + green * media_color_luma_weight_green() + blue * media_color_luma_weight_blue()) >> 8) as u8
        std::collection::array::set(target.pixels, target_index, luma)
        target_index = target_index + 1
        source_offset = source_offset + 3
    }
    return data_outcome_of(target)
}

# RGBA → 灰度：BT.601 整数 luma（忽略 alpha）。
micro media_internal_rgba_to_gray(source: MediaRaster) -> DataOutcome<MediaRaster> {
    let target: MediaRaster = data_outcome_value(media_raster(source.width, source.height, Gray8))
    let total: usize = std::collection::array::length(source.pixels)
    let mut source_offset: usize = 0
    let mut target_index: usize = 0
    while source_offset < total {
        let red: u64 = std::collection::array::get(source.pixels, source_offset) as u64
        let green: u64 = std::collection::array::get(source.pixels, source_offset + 1) as u64
        let blue: u64 = std::collection::array::get(source.pixels, source_offset + 2) as u64
        let luma: u8 = ((red * media_color_luma_weight_red() + green * media_color_luma_weight_green() + blue * media_color_luma_weight_blue()) >> 8) as u8
        std::collection::array::set(target.pixels, target_index, luma)
        target_index = target_index + 1
        source_offset = source_offset + 4
    }
    return data_outcome_of(target)
}
