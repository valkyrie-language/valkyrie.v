namespace media;

using std.data::{data_outcome_has_errors, data_outcome_diagnostics, data_outcome_value};

# codec_bmp.v — BMP 读写正反测试。
#
# 阻塞说明：断言经 `std::types::panic`，而 raise 终止子在各后端尚无目标合同
#（编译期 SMIR001 结构化失败）。运行时证据由 `examples/media-drive` 的值返回探针产出。
#
# 反例构造：基于 `media_fixture_bmp_2x2()` 就地位改（字节偏移见 fixtures.v 注释）。

[test]
micro test_bmp_read_fixture() -> unit {
    let raster: MediaRaster = data_outcome_value(media_bmp_read(media_fixture_bmp_2x2()))
    if raster.width != 2 || raster.height != 2 {
        std::types::panic("bmp dims must be 2x2")
    }
    # 自底向上解序：图像行 0 为红、绿
    if (data_outcome_value(media_raster_read_channel(raster, 0, 0, 0)) as u64) != 255 {
        std::types::panic("bmp pixel (0,0) must be red")
    }
    if (data_outcome_value(media_raster_read_channel(raster, 1, 0, 1)) as u64) != 255 {
        std::types::panic("bmp pixel (1,0) must be green")
    }
    # 图像行 1 为蓝、白（BGR → RGB 换序证据）
    if (data_outcome_value(media_raster_read_channel(raster, 0, 1, 2)) as u64) != 255 {
        std::types::panic("bmp pixel (0,1) must be blue")
    }
    if (data_outcome_value(media_raster_read_channel(raster, 1, 1, 0)) as u64) != 255 {
        std::types::panic("bmp pixel (1,1) must be white")
    }
}

[test]
micro test_bmp_write_round_trip() -> unit {
    let fixture: [u8] = media_fixture_bmp_2x2()
    let raster: MediaRaster = data_outcome_value(media_bmp_read(fixture))
    let written: [u8] = data_outcome_value(media_bmp_write(raster))
    if !media_fixture_bytes_equal(written, fixture) {
        std::types::panic("bmp round trip must reproduce fixture bytes")
    }
}

[test]
micro test_bmp_bad_magic() -> unit {
    let mutated: [u8] = media_fixture_bmp_2x2()
    std::collection::array::set(mutated, 0, 0 as u8)
    if !media_fixture_has_code(data_outcome_diagnostics(media_bmp_read(mutated)), "media.bmp.bad_magic") {
        std::types::panic("bad magic must be diagnosed")
    }
}

[test]
micro test_bmp_unsupported_bit_depth() -> unit {
    let mutated: [u8] = media_fixture_bmp_2x2()
    std::collection::array::set(mutated, 28, 32 as u8)
    if !media_fixture_has_code(data_outcome_diagnostics(media_bmp_read(mutated)), "media.bmp.unsupported_bit_depth") {
        std::types::panic("32 bpp must be diagnosed")
    }
}

[test]
micro test_bmp_top_down_unsupported() -> unit {
    # 高度字段（偏移 22）写 0xFFFFFFFE（-2，top-down）
    let mutated: [u8] = media_fixture_bmp_2x2()
    std::collection::array::set(mutated, 22, 254 as u8)
    std::collection::array::set(mutated, 23, 255 as u8)
    std::collection::array::set(mutated, 24, 255 as u8)
    std::collection::array::set(mutated, 25, 255 as u8)
    if !media_fixture_has_code(data_outcome_diagnostics(media_bmp_read(mutated)), "media.bmp.unsupported_layout") {
        std::types::panic("top-down layout must be diagnosed")
    }
}

[test]
micro test_bmp_bad_planes() -> unit {
    let mutated: [u8] = media_fixture_bmp_2x2()
    std::collection::array::set(mutated, 26, 2 as u8)
    if !media_fixture_has_code(data_outcome_diagnostics(media_bmp_read(mutated)), "media.bmp.bad_planes") {
        std::types::panic("planes != 1 must be diagnosed")
    }
}

[test]
micro test_bmp_unsupported_compression() -> unit {
    let mutated: [u8] = media_fixture_bmp_2x2()
    std::collection::array::set(mutated, 30, 1 as u8)
    if !media_fixture_has_code(data_outcome_diagnostics(media_bmp_read(mutated)), "media.bmp.unsupported_compression") {
        std::types::panic("compression != 0 must be diagnosed")
    }
}
