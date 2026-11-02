namespace media;

using std.data::{data_outcome_has_errors, data_outcome_diagnostics, data_outcome_value_or};

# codec_ppm.v — PPM 读写正反测试。
#
# 阻塞说明：断言经 `std::types::panic`，而 raise 终止子在各后端尚无目标合同
#（当前编译期结构化失败）。运行时验证由 `examples/media-drive` 的值返回探针执行。

[test]
micro test_ppm_read_fixture() -> unit {
    let raster: MediaRaster = data_outcome_value_or(media_ppm_read(media_fixture_ppm_2x2()), media_raster_empty_sentinel(Rgb8))
    if raster.width != 2 || raster.height != 2 {
        std::types::panic("ppm dims must be 2x2")
    }
    if (data_outcome_value_or(media_raster_read_channel(raster, 0, 0, 0), 0 as u8) as u64) != 255 {
        std::types::panic("first pixel must be red")
    }
    if (data_outcome_value_or(media_raster_read_channel(raster, 1, 0, 1), 0 as u8) as u64) != 255 {
        std::types::panic("second pixel must be green")
    }
    if (data_outcome_value_or(media_raster_read_channel(raster, 0, 1, 2), 0 as u8) as u64) != 255 {
        std::types::panic("third pixel must be blue")
    }
}

[test]
micro test_ppm_write_round_trip() -> unit {
    let fixture: [u8] = media_fixture_ppm_2x2()
    let raster: MediaRaster = data_outcome_value_or(media_ppm_read(fixture), media_raster_empty_sentinel(Rgb8))
    let written: [u8] = data_outcome_value_or(media_ppm_write(raster), [])
    if !media_fixture_bytes_equal(written, fixture) {
        std::types::panic("ppm round trip must reproduce fixture bytes")
    }
}

[test]
micro test_ppm_bad_magic() -> unit {
    let bogus: [u8] = [0 as u8, 0 as u8, 10 as u8]
    if !media_fixture_has_code(data_outcome_diagnostics(media_ppm_read(bogus)), "media.ppm.bad_magic") {
        std::types::panic("bad magic must be diagnosed")
    }
}

[test]
micro test_ppm_p3_unsupported() -> unit {
    let p3: [u8] = [80 as u8, 51 as u8, 10 as u8]
    if !media_fixture_has_code(data_outcome_diagnostics(media_ppm_read(p3)), "media.ppm.unsupported_variant") {
        std::types::panic("P3 must be diagnosed as unsupported variant")
    }
}

[test]
micro test_ppm_unsupported_maxval() -> unit {
    let maxval_254: [u8] = [
        80 as u8, 54 as u8, 10 as u8,
        49 as u8, 32 as u8, 49 as u8,
        10 as u8,
        50 as u8, 53 as u8, 52 as u8, 10 as u8,
        0 as u8, 0 as u8, 0 as u8
    ]
    if !media_fixture_has_code(data_outcome_diagnostics(media_ppm_read(maxval_254)), "media.ppm.unsupported_maxval") {
        std::types::panic("maxval 254 must be diagnosed")
    }
}

[test]
micro test_ppm_truncated_raster_keeps_prefix() -> unit {
    # 栅格少 2 字节：截断诊断 + 已读前缀（红、绿、蓝三色）仍保留
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
    if !media_fixture_has_code(data_outcome_diagnostics(outcome), "media.ppm.truncated_raster") {
        std::types::panic("truncated raster must be diagnosed")
    }
    let raster: MediaRaster = data_outcome_value_or(outcome, media_raster_empty_sentinel(Rgb8))
    if (data_outcome_value_or(media_raster_read_channel(raster, 0, 0, 0), 0 as u8) as u64) != 255 {
        std::types::panic("truncated read must keep decoded prefix")
    }
}

[test]
micro test_ppm_trailing_bytes_warns_but_fine() -> unit {
    let mut with_tail: [u8] = media_fixture_ppm_2x2()
    with_tail = std::collection::push(with_tail, 0 as u8)
    let outcome = media_ppm_read(with_tail)
    if data_outcome_has_errors(outcome) {
        std::types::panic("trailing bytes must stay Warning, not Error")
    }
    if !media_fixture_has_code(data_outcome_diagnostics(outcome), "media.ppm.trailing_bytes") {
        std::types::panic("trailing bytes must be diagnosed")
    }
}
