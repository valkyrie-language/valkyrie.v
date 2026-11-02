namespace media;

using std.data::{data_outcome_has_errors, data_outcome_value_or};

# color_convert.v — 颜色格式转换正反测试。
#
# 阻塞说明：断言经 `std::types::panic`，而 raise 终止子在各后端尚无目标合同
#（当前编译期结构化失败）。运行时验证由 `examples/media-drive` 的值返回探针执行。

[test]
micro test_gray_to_rgb_replicates() -> unit {
    let gray: MediaRaster = data_outcome_value_or(media_raster_of_pixels(1, 1, Gray8, [7 as u8]), media_raster_empty_sentinel(Gray8))
    let rgb: MediaRaster = data_outcome_value_or(media_color_convert(gray, Rgb8), media_raster_empty_sentinel(Rgb8))
    if (std::collection::array::get(rgb.pixels, 0) as u64) != 7 {
        std::types::panic("red channel must replicate gray")
    }
    if (std::collection::array::get(rgb.pixels, 1) as u64) != 7 {
        std::types::panic("green channel must replicate gray")
    }
    if (std::collection::array::get(rgb.pixels, 2) as u64) != 7 {
        std::types::panic("blue channel must replicate gray")
    }
}

[test]
micro test_rgb_to_gray_luma() -> unit {
    let rgb: MediaRaster = data_outcome_value_or(media_raster_of_pixels(1, 1, Rgb8, [255 as u8, 0 as u8, 0 as u8]), media_raster_empty_sentinel(Rgb8))
    let gray: MediaRaster = data_outcome_value_or(media_color_convert(rgb, Gray8), media_raster_empty_sentinel(Gray8))
    # (255 * 77) >> 8 = 76
    if (std::collection::array::get(gray.pixels, 0) as u64) != 76 {
        std::types::panic("luma of pure red must be 76")
    }
}

[test]
micro test_rgb_to_rgba_adds_opaque_alpha() -> unit {
    let rgb: MediaRaster = data_outcome_value_or(media_raster_of_pixels(1, 1, Rgb8, [1 as u8, 2 as u8, 3 as u8]), media_raster_empty_sentinel(Rgb8))
    let rgba: MediaRaster = data_outcome_value_or(media_color_convert(rgb, Rgba8), media_raster_empty_sentinel(Rgba8))
    if (std::collection::array::get(rgba.pixels, 3) as u64) != 255 {
        std::types::panic("alpha must be opaque 255")
    }
    if (std::collection::array::get(rgba.pixels, 1) as u64) != 2 {
        std::types::panic("green channel must pass through")
    }
}

[test]
micro test_rgba_to_rgb_drops_alpha() -> unit {
    let rgba: MediaRaster = data_outcome_value_or(media_raster_of_pixels(1, 1, Rgba8, [1 as u8, 2 as u8, 3 as u8, 4 as u8]), media_raster_empty_sentinel(Rgba8))
    let rgb: MediaRaster = data_outcome_value_or(media_color_convert(rgba, Rgb8), media_raster_empty_sentinel(Rgb8))
    if std::collection::array::length(rgb.pixels) != 3 {
        std::types::panic("rgb buffer must be 3 bytes")
    }
    if (std::collection::array::get(rgb.pixels, 2) as u64) != 3 {
        std::types::panic("blue channel must pass through")
    }
}

[test]
micro test_convert_inconsistent_source_fails() -> unit {
    let bogus: MediaRaster = MediaRaster { width: 2, height: 2, format: Rgb8, pixels: [1 as u8] }
    if !data_outcome_has_errors(media_color_convert(bogus, Gray8)) {
        std::types::panic("inconsistent source must fail")
    }
}
