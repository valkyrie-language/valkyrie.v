namespace media_drive;

using std.data::{DataDiagnostic, data_diagnostic_code, data_outcome_has_errors, data_outcome_diagnostics, data_outcome_value};
using media::{
    MediaRaster, Rgb8, Gray8, media_raster, media_raster_of_pixels, media_raster_offset_of, media_raster_read_channel,
    media_color_convert, media_pipeline_crop, media_pipeline_resize_nearest,
    media_ppm_read, media_ppm_write, media_bmp_read, media_bmp_write, media_png_read, media_png_unfilter
};

# media 驱动探针：数值可断言的行为证据（编译期 panic 无后端 raise 合同，此为绕行形态）。
# 每个探针返回一个可打包进 u64 的确定值；node 驱动器按已知答案断言。

micro bit_of(value: bool) -> u64 {
    if value {
        return 1
    }
    return 0
}

micro drive_bytes_equal(left: [u8], right: [u8]) -> bool {
    if std::collection::array::length(left) != std::collection::array::length(right) {
        return false
    }
    let mut index: usize = 0
    while index < std::collection::array::length(left) {
        if (std::collection::array::get(left, index) as u64) != (std::collection::array::get(right, index) as u64) {
            return false
        }
        index = index + 1
    }
    return true
}

micro drive_has_code(diagnostics: [DataDiagnostic], code: utf8) -> bool {
    let mut index: usize = 0
    while index < std::collection::array::length(diagnostics) {
        if data_diagnostic_code(std::collection::array::get(diagnostics, index)) == code {
            return true
        }
        index = index + 1
    }
    return false
}

# 2×2 RGB 参考图：行主序 红、绿、蓝、白。
micro drive_raster_2x2() -> MediaRaster {
    return data_outcome_value(media_raster_of_pixels(
        2, 2, Rgb8,
        [
            255 as u8, 0 as u8, 0 as u8,
            0 as u8, 255 as u8, 0 as u8,
            0 as u8, 0 as u8, 255 as u8,
            255 as u8, 255 as u8, 255 as u8
        ]
    ))
}

# PNG 1×1 容器 fixture（真实 CRC-32；canonical 副本在 media 包 test/fixtures.v）。
micro drive_png_1x1() -> [u8] {
    return [
        137 as u8, 80 as u8, 78 as u8, 71 as u8, 13 as u8, 10 as u8, 26 as u8, 10 as u8,
        0 as u8, 0 as u8, 0 as u8, 13 as u8, 73 as u8, 72 as u8, 68 as u8, 82 as u8,
        0 as u8, 0 as u8, 0 as u8, 1 as u8, 0 as u8, 0 as u8, 0 as u8, 1 as u8, 8 as u8, 2 as u8, 0 as u8, 0 as u8, 0 as u8,
        144 as u8, 119 as u8, 83 as u8, 222 as u8,
        0 as u8, 0 as u8, 0 as u8, 4 as u8, 73 as u8, 68 as u8, 65 as u8, 84 as u8, 1 as u8, 2 as u8, 3 as u8, 4 as u8,
        125 as u8, 91 as u8, 195 as u8, 214 as u8,
        0 as u8, 0 as u8, 0 as u8, 0 as u8, 73 as u8, 69 as u8, 78 as u8, 68 as u8, 174 as u8, 66 as u8, 96 as u8, 130 as u8
    ]
}

# ── 图像模型 ─────────────────────────────────────────────────────────

[test]
micro drive_raster_geometry() -> u64 {
    let raster: MediaRaster = data_outcome_value(media_raster(2, 2, Rgb8))
    return (raster.width as u64) * 10000 + (raster.height as u64) * 100 + (std::collection::array::length(raster.pixels) as u64)
}

[test]
micro drive_raster_offset_and_bounds() -> u64 {
    let raster: MediaRaster = data_outcome_value(media_raster(2, 2, Rgb8))
    let inside: u64 = data_outcome_value(media_raster_offset_of(raster, 1, 1)) as u64
    let outside: u64 = bit_of(data_outcome_has_errors(media_raster_offset_of(raster, 2, 0)))
    return inside * 100 + outside
}

# ── 颜色转换 ─────────────────────────────────────────────────────────

[test]
micro drive_color_gray_to_rgb() -> u64 {
    let gray: MediaRaster = data_outcome_value(media_raster_of_pixels(1, 1, Gray8, [7 as u8]))
    let rgb: MediaRaster = data_outcome_value(media_color_convert(gray, Rgb8))
    return (std::collection::array::get(rgb.pixels, 0) as u64) * 100 + (std::collection::array::get(rgb.pixels, 1) as u64) * 10 + (std::collection::array::get(rgb.pixels, 2) as u64)
}

[test]
micro drive_color_rgb_to_gray() -> u64 {
    let rgb: MediaRaster = data_outcome_value(media_raster_of_pixels(1, 1, Rgb8, [255 as u8, 0 as u8, 0 as u8]))
    let gray: MediaRaster = data_outcome_value(media_color_convert(rgb, Gray8))
    return std::collection::array::get(gray.pixels, 0) as u64
}

# ── 管线 ─────────────────────────────────────────────────────────────

[test]
micro drive_crop_right_column() -> u64 {
    let cropped: MediaRaster = data_outcome_value(media_pipeline_crop(drive_raster_2x2(), 1, 0, 1, 2))
    let green_channel: u64 = data_outcome_value(media_raster_read_channel(cropped, 0, 0, 1)) as u64
    let white_red: u64 = data_outcome_value(media_raster_read_channel(cropped, 0, 1, 0)) as u64
    return green_channel * 1000 + white_red
}

[test]
micro drive_crop_out_of_bounds() -> u64 {
    return bit_of(data_outcome_has_errors(media_pipeline_crop(drive_raster_2x2(), 1, 1, 2, 2)))
}

[test]
micro drive_resize_nearest() -> u64 {
    let resized: MediaRaster = data_outcome_value(media_pipeline_resize_nearest(drive_raster_2x2(), 4, 4))
    let corner: u64 = data_outcome_value(media_raster_read_channel(resized, 3, 3, 0)) as u64
    let edge: u64 = data_outcome_value(media_raster_read_channel(resized, 2, 0, 1)) as u64
    return corner * 1000 + edge
}

# ── PPM ──────────────────────────────────────────────────────────────

[test]
micro drive_ppm_round_trip() -> u64 {
    let once: [u8] = data_outcome_value(media_ppm_write(drive_raster_2x2()))
    let raster: MediaRaster = data_outcome_value(media_ppm_read(once))
    let twice: [u8] = data_outcome_value(media_ppm_write(raster))
    return bit_of(drive_bytes_equal(once, twice)) * 1000 + (std::collection::array::length(once) as u64)
}

[test]
micro drive_ppm_bad_magic() -> u64 {
    let bogus: [u8] = [0 as u8, 0 as u8, 10 as u8]
    return bit_of(drive_has_code(data_outcome_diagnostics(media_ppm_read(bogus)), "media.ppm.bad_magic"))
}

[test]
micro drive_ppm_truncated_keeps_prefix() -> u64 {
    let truncated: [u8] = [
        80 as u8, 54 as u8, 10 as u8,
        50 as u8, 32 as u8, 50 as u8,
        10 as u8,
        50 as u8, 53 as u8, 53 as u8, 10 as u8,
        255 as u8, 0 as u8, 0 as u8,
        0 as u8, 255 as u8, 0 as u8,
        0 as u8, 0 as u8, 255 as u8,
        255 as u8
    ]
    let outcome = media_ppm_read(truncated)
    let flagged: u64 = bit_of(drive_has_code(data_outcome_diagnostics(outcome), "media.ppm.truncated_raster"))
    let red: u64 = data_outcome_value(media_raster_read_channel(data_outcome_value(outcome), 0, 0, 0)) as u64
    return flagged * 1000 + red
}

# ── BMP ──────────────────────────────────────────────────────────────

[test]
micro drive_bmp_round_trip() -> u64 {
    let once: [u8] = data_outcome_value(media_bmp_write(drive_raster_2x2()))
    let raster: MediaRaster = data_outcome_value(media_bmp_read(once))
    let twice: [u8] = data_outcome_value(media_bmp_write(raster))
    return bit_of(drive_bytes_equal(once, twice)) * 1000 + (std::collection::array::length(once) as u64)
}

[test]
micro drive_bmp_pixel_order() -> u64 {
    # 写出→读回：BGR/自底向上换序的正确性证据
    let raster: MediaRaster = data_outcome_value(media_bmp_read(data_outcome_value(media_bmp_write(drive_raster_2x2()))))
    let red: u64 = data_outcome_value(media_raster_read_channel(raster, 0, 0, 0)) as u64
    let blue: u64 = data_outcome_value(media_raster_read_channel(raster, 0, 1, 2)) as u64
    return red * 1000 + blue
}

[test]
micro drive_bmp_top_down_rejected() -> u64 {
    let bytes: [u8] = data_outcome_value(media_bmp_write(drive_raster_2x2()))
    std::collection::array::set(bytes, 22, 254 as u8)
    std::collection::array::set(bytes, 23, 255 as u8)
    std::collection::array::set(bytes, 24, 255 as u8)
    std::collection::array::set(bytes, 25, 255 as u8)
    return bit_of(drive_has_code(data_outcome_diagnostics(media_bmp_read(bytes)), "media.bmp.unsupported_layout"))
}

# ── PNG ──────────────────────────────────────────────────────────────

[test]
micro drive_png_container_stops_at_inflate() -> u64 {
    let outcome = media_png_read(drive_png_1x1())
    let flagged: u64 = bit_of(drive_has_code(data_outcome_diagnostics(outcome), "media.png.inflate_unavailable"))
    let no_crc_error: u64 = bit_of(!drive_has_code(data_outcome_diagnostics(outcome), "media.png.crc_mismatch"))
    let raster: MediaRaster = data_outcome_value(outcome)
    return flagged * 10000 + no_crc_error * 100 + (raster.width as u64) * 10 + (raster.height as u64)
}

[test]
micro drive_png_crc_mismatch() -> u64 {
    let broken: [u8] = drive_png_1x1()
    std::collection::array::set(broken, 48, 41 as u8)
    return bit_of(drive_has_code(data_outcome_diagnostics(media_png_read(broken)), "media.png.crc_mismatch"))
}

[test]
micro drive_png_bad_signature() -> u64 {
    let broken: [u8] = drive_png_1x1()
    std::collection::array::set(broken, 0, 0 as u8)
    return bit_of(drive_has_code(data_outcome_diagnostics(media_png_read(broken)), "media.png.bad_signature"))
}

[test]
micro drive_png_unfilter_sub() -> u64 {
    let raw: [u8] = [1 as u8, 10 as u8, 20 as u8, 30 as u8, 5 as u8, 5 as u8, 5 as u8]
    let out: [u8] = data_outcome_value(media_png_unfilter(raw, 2, 1, 3))
    return (std::collection::array::get(out, 3) as u64) * 100 + (std::collection::array::get(out, 5) as u64)
}

[test]
micro drive_png_unfilter_average() -> u64 {
    let raw: [u8] = [0 as u8, 10 as u8, 20 as u8, 30 as u8, 3 as u8, 6 as u8, 6 as u8, 6 as u8]
    let out: [u8] = data_outcome_value(media_png_unfilter(raw, 1, 2, 3))
    return (std::collection::array::get(out, 3) as u64) * 10000 + (std::collection::array::get(out, 4) as u64) * 100 + (std::collection::array::get(out, 5) as u64)
}

[test]
micro drive_png_unfilter_paeth() -> u64 {
    let raw: [u8] = [0 as u8, 10 as u8, 20 as u8, 30 as u8, 4 as u8, 5 as u8, 5 as u8, 5 as u8]
    let out: [u8] = data_outcome_value(media_png_unfilter(raw, 1, 2, 3))
    return (std::collection::array::get(out, 3) as u64) * 100 + (std::collection::array::get(out, 5) as u64)
}

[test]
micro drive_png_unfilter_unknown_filter() -> u64 {
    let raw: [u8] = [7 as u8, 1 as u8, 2 as u8, 3 as u8]
    return bit_of(drive_has_code(data_outcome_diagnostics(media_png_unfilter(raw, 1, 1, 3)), "media.png.unknown_filter_type"))
}
