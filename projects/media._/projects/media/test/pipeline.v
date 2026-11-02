namespace media;

using std.data::{data_outcome_has_errors, data_outcome_value};

# pipeline.v — crop / resize 正反测试。
#
# 阻塞说明：断言经 `std::types::panic`，而 raise 终止子在各后端尚无目标合同
#（编译期 SMIR001 结构化失败）。运行时证据由 `examples/media-drive` 的值返回探针产出。

# 2×2 RGB：行主序 红、绿、蓝、白。
micro media_pipeline_test_raster() -> MediaRaster {
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

[test]
micro test_crop_right_column() -> unit {
    let source: MediaRaster = media_pipeline_test_raster()
    let cropped: MediaRaster = data_outcome_value(media_pipeline_crop(source, 1, 0, 1, 2))
    if cropped.width != 1 || cropped.height != 2 {
        std::types::panic("crop dims must be 1x2")
    }
    # 首像素为绿，次像素为白
    if (data_outcome_value(media_raster_read_channel(cropped, 0, 0, 1)) as u64) != 255 {
        std::types::panic("cropped first pixel must be green")
    }
    if (data_outcome_value(media_raster_read_channel(cropped, 0, 1, 0)) as u64) != 255 {
        std::types::panic("cropped second pixel must be white")
    }
}

[test]
micro test_crop_out_of_bounds() -> unit {
    let source: MediaRaster = media_pipeline_test_raster()
    if !data_outcome_has_errors(media_pipeline_crop(source, 1, 1, 2, 2)) {
        std::types::panic("crop beyond source must fail")
    }
}

[test]
micro test_crop_empty_target() -> unit {
    let source: MediaRaster = media_pipeline_test_raster()
    if !data_outcome_has_errors(media_pipeline_crop(source, 0, 0, 0, 1)) {
        std::types::panic("zero-width crop must fail")
    }
}

[test]
micro test_resize_nearest_upscale() -> unit {
    let source: MediaRaster = media_pipeline_test_raster()
    let resized: MediaRaster = data_outcome_value(media_pipeline_resize_nearest(source, 4, 4))
    if resized.width != 4 || resized.height != 4 {
        std::types::panic("resize dims must be 4x4")
    }
    # 最近邻：dst(0,0)=红、dst(2,0)=绿、dst(0,2)=蓝、dst(3,3)=白
    if (data_outcome_value(media_raster_read_channel(resized, 0, 0, 0)) as u64) != 255 {
        std::types::panic("dst(0,0) must be red")
    }
    if (data_outcome_value(media_raster_read_channel(resized, 2, 0, 1)) as u64) != 255 {
        std::types::panic("dst(2,0) must be green")
    }
    if (data_outcome_value(media_raster_read_channel(resized, 0, 2, 2)) as u64) != 255 {
        std::types::panic("dst(0,2) must be blue")
    }
    if (data_outcome_value(media_raster_read_channel(resized, 3, 3, 0)) as u64) != 255 {
        std::types::panic("dst(3,3) must be white")
    }
}

[test]
micro test_resize_empty_target() -> unit {
    let source: MediaRaster = media_pipeline_test_raster()
    if !data_outcome_has_errors(media_pipeline_resize_nearest(source, 4, 0)) {
        std::types::panic("zero-height resize must fail")
    }
}
