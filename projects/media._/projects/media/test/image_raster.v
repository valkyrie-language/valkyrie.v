namespace media;

using std.data::{DataOutcome, data_outcome_has_errors, data_outcome_value_or};

# image_raster.v — 图像模型正反测试。
#
# 阻塞说明：断言经 `std::types::panic`，而 raise 终止子在各后端尚无目标合同
#（当前编译期结构化失败）。运行时验证由 `examples/media-drive` 的值返回探针执行。

[test]
micro test_raster_geometry() -> unit {
    let raster: MediaRaster = data_outcome_value_or(media_raster(2, 2, Rgb8), media_raster_empty_sentinel(Rgb8))
    if raster.width != 2 || raster.height != 2 {
        std::types::panic("raster dims mismatch")
    }
    if media_raster_stride(raster) != 6 {
        std::types::panic("raster stride must be 6")
    }
    if std::collection::array::length(raster.pixels) != 12 {
        std::types::panic("raster buffer must be 12 bytes")
    }
}

[test]
micro test_raster_offset_row_major() -> unit {
    let raster: MediaRaster = data_outcome_value_or(media_raster(2, 2, Rgb8), media_raster_empty_sentinel(Rgb8))
    if data_outcome_value_or(media_raster_offset_of(raster, 1, 0), 0) != 3 {
        std::types::panic("offset (1,0) must be 3")
    }
    if data_outcome_value_or(media_raster_offset_of(raster, 0, 1), 0) != 6 {
        std::types::panic("offset (0,1) must be 6")
    }
    if data_outcome_value_or(media_raster_offset_of(raster, 1, 1), 0) != 9 {
        std::types::panic("offset (1,1) must be 9")
    }
}

[test]
micro test_raster_out_of_bounds() -> unit {
    let raster: MediaRaster = data_outcome_value_or(media_raster(2, 2, Rgb8), media_raster_empty_sentinel(Rgb8))
    if !data_outcome_has_errors(media_raster_offset_of(raster, 2, 0)) {
        std::types::panic("x == width must fail")
    }
    if !data_outcome_has_errors(media_raster_offset_of(raster, 0, 2)) {
        std::types::panic("y == height must fail")
    }
}

[test]
micro test_raster_empty_dimension() -> unit {
    if !data_outcome_has_errors(media_raster(0, 2, Rgb8)) {
        std::types::panic("zero width must fail")
    }
    if !data_outcome_has_errors(media_raster(2, 0, Rgb8)) {
        std::types::panic("zero height must fail")
    }
}

[test]
micro test_raster_too_large() -> unit {
    if !data_outcome_has_errors(media_raster(16777217, 1, Gray8)) {
        std::types::panic("side beyond 2^24 must fail")
    }
}

[test]
micro test_raster_write_read_round_trip() -> unit {
    let raster: MediaRaster = data_outcome_value_or(media_raster(2, 2, Rgb8), media_raster_empty_sentinel(Rgb8))
    if data_outcome_has_errors(media_raster_write_channel(raster, 1, 1, 2, 200 as u8)) {
        std::types::panic("write channel failed")
    }
    if (data_outcome_value_or(media_raster_read_channel(raster, 1, 1, 2), 0 as u8) as u64) != 200 {
        std::types::panic("read back mismatch")
    }
}

[test]
micro test_raster_bad_channel() -> unit {
    let raster: MediaRaster = data_outcome_value_or(media_raster(2, 2, Rgb8), media_raster_empty_sentinel(Rgb8))
    if !data_outcome_has_errors(media_raster_read_channel(raster, 0, 0, 3)) {
        std::types::panic("channel 3 on Rgb8 must fail")
    }
}

[test]
micro test_raster_buffer_length_mismatch() -> unit {
    if !data_outcome_has_errors(media_raster_of_pixels(2, 2, Rgb8, [1 as u8, 2 as u8, 3 as u8])) {
        std::types::panic("3 bytes for 2x2 Rgb8 must fail")
    }
}
