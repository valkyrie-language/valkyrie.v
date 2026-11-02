namespace media;

using std.data::{data_outcome_diagnostics, data_outcome_value_or};

# codec_png.v — PNG 容器层与滤波重建正反测试。
#
# 阻塞说明：断言经 `std::types::panic`，而 raise 终止子在各后端尚无目标合同
#（当前编译期结构化失败）。运行时验证由 `examples/media-drive` 的值返回探针执行。

[test]
micro test_png_container_read_stops_at_inflate() -> unit {
    let outcome = media_png_read(media_fixture_png_1x1())
    # IDAT 解压待 codec 落地，必然带 inflate_unavailable；几何随部分结果返回
    if !media_fixture_has_code(data_outcome_diagnostics(outcome), "media.png.inflate_unavailable") {
        std::types::panic("inflate gap must be diagnosed")
    }
    if media_fixture_has_code(data_outcome_diagnostics(outcome), "media.png.crc_mismatch") {
        std::types::panic("fixture CRCs are correct, no mismatch expected")
    }
    let raster: MediaRaster = data_outcome_value_or(outcome, media_raster_empty_sentinel(Rgb8))
    if raster.width != 1 || raster.height != 1 {
        std::types::panic("png geometry must survive the inflate gap")
    }
    if media_pixel_format_channels(raster.format) != 3 {
        std::types::panic("png color type 2 must map to Rgb8")
    }
}

[test]
micro test_png_crc_mismatch() -> unit {
    let outcome = media_png_read(media_fixture_png_1x1_crc_broken())
    if !media_fixture_has_code(data_outcome_diagnostics(outcome), "media.png.crc_mismatch") {
        std::types::panic("flipped CRC must be diagnosed")
    }
}

[test]
micro test_png_bad_signature() -> unit {
    let mutated: [u8] = media_fixture_png_1x1()
    std::collection::array::set(mutated, 0, 0 as u8)
    if !media_fixture_has_code(data_outcome_diagnostics(media_png_read(mutated)), "media.png.bad_signature") {
        std::types::panic("bad signature must be diagnosed")
    }
}

[test]
micro test_png_missing_ihdr() -> unit {
    # 签名 + IDAT + IEND（无 IHDR）
    let no_ihdr: [u8] = [
        137 as u8, 80 as u8, 78 as u8, 71 as u8, 13 as u8, 10 as u8, 26 as u8, 10 as u8,
        0 as u8, 0 as u8, 0 as u8, 4 as u8, 73 as u8, 68 as u8, 65 as u8, 84 as u8, 1 as u8, 2 as u8, 3 as u8, 4 as u8,
        125 as u8, 91 as u8, 195 as u8, 214 as u8,
        0 as u8, 0 as u8, 0 as u8, 0 as u8, 73 as u8, 69 as u8, 78 as u8, 68 as u8, 174 as u8, 66 as u8, 96 as u8, 130 as u8
    ]
    if !media_fixture_has_code(data_outcome_diagnostics(media_png_read(no_ihdr)), "media.png.missing_ihdr") {
        std::types::panic("missing IHDR must be diagnosed")
    }
}

[test]
micro test_png_unfilter_none() -> unit {
    let raw: [u8] = [0 as u8, 10 as u8, 20 as u8, 30 as u8]
    let out: [u8] = data_outcome_value_or(media_png_unfilter(raw, 1, 1, 3), [])
    if (std::collection::array::get(out, 2) as u64) != 30 {
        std::types::panic("filter None must copy through")
    }
}

[test]
micro test_png_unfilter_sub() -> unit {
    # 宽 2：第二像素 = 原始差分 + 左邻重建值
    let raw: [u8] = [1 as u8, 10 as u8, 20 as u8, 30 as u8, 5 as u8, 5 as u8, 5 as u8]
    let out: [u8] = data_outcome_value_or(media_png_unfilter(raw, 2, 1, 3), [])
    if (std::collection::array::get(out, 3) as u64) != 15 {
        std::types::panic("sub filter red channel mismatch")
    }
    if (std::collection::array::get(out, 5) as u64) != 35 {
        std::types::panic("sub filter blue channel mismatch")
    }
}

[test]
micro test_png_unfilter_up() -> unit {
    let raw: [u8] = [0 as u8, 10 as u8, 20 as u8, 30 as u8, 2 as u8, 1 as u8, 1 as u8, 1 as u8]
    let out: [u8] = data_outcome_value_or(media_png_unfilter(raw, 1, 2, 3), [])
    if (std::collection::array::get(out, 3) as u64) != 11 {
        std::types::panic("up filter red channel mismatch")
    }
    if (std::collection::array::get(out, 5) as u64) != 31 {
        std::types::panic("up filter blue channel mismatch")
    }
}

[test]
micro test_png_unfilter_average() -> unit {
    # 行首像素：left=0，up=(10,20,30)，6 + up/2
    let raw: [u8] = [0 as u8, 10 as u8, 20 as u8, 30 as u8, 3 as u8, 6 as u8, 6 as u8, 6 as u8]
    let out: [u8] = data_outcome_value_or(media_png_unfilter(raw, 1, 2, 3), [])
    if (std::collection::array::get(out, 3) as u64) != 11 {
        std::types::panic("average filter red channel mismatch")
    }
    if (std::collection::array::get(out, 4) as u64) != 16 {
        std::types::panic("average filter green channel mismatch")
    }
    if (std::collection::array::get(out, 5) as u64) != 21 {
        std::types::panic("average filter blue channel mismatch")
    }
}

[test]
micro test_png_unfilter_paeth() -> unit {
    # 行首像素：left=0、up=10、up_left=0 → 预测 up → 5 + 10 = 15
    let raw: [u8] = [0 as u8, 10 as u8, 20 as u8, 30 as u8, 4 as u8, 5 as u8, 5 as u8, 5 as u8]
    let out: [u8] = data_outcome_value_or(media_png_unfilter(raw, 1, 2, 3), [])
    if (std::collection::array::get(out, 3) as u64) != 15 {
        std::types::panic("paeth filter red channel mismatch")
    }
    if (std::collection::array::get(out, 5) as u64) != 35 {
        std::types::panic("paeth filter blue channel mismatch")
    }
}

[test]
micro test_png_unfilter_unknown_filter() -> unit {
    let raw: [u8] = [7 as u8, 1 as u8, 2 as u8, 3 as u8]
    let outcome = media_png_unfilter(raw, 1, 1, 3)
    if !media_fixture_has_code(data_outcome_diagnostics(outcome), "media.png.unknown_filter_type") {
        std::types::panic("unknown filter type must be diagnosed")
    }
}

[test]
micro test_png_unfilter_length_mismatch() -> unit {
    let raw: [u8] = [0 as u8, 1 as u8, 2 as u8]
    if !media_fixture_has_code(data_outcome_diagnostics(media_png_unfilter(raw, 1, 1, 3)), "media.png.unfilter_length_mismatch") {
        std::types::panic("length mismatch must be diagnosed")
    }
}
