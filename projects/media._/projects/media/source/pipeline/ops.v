namespace media;

using std.data::{DataOutcome, Error, data_outcome_of, data_outcome_with, data_outcome_value, new_data_diagnostic, new_data_span};

# 处理管线：图像 → 图像变换（crop、resize）。
# 入口一律先过源一致性门禁；区域/尺寸非法时结构化失败并返回占位，
# 不裁剪越界区域、不静默吞掉请求。

# 裁剪：源图 (x, y) 起 width × height 区域复制为新栅格。
micro media_pipeline_crop(source: MediaRaster, x: usize, y: usize, width: usize, height: usize) -> DataOutcome<MediaRaster> {
    if !media_raster_is_consistent(source) {
        return data_outcome_with(
            media_raster_placeholder(source.format),
            [new_data_diagnostic("media.image.buffer_length_mismatch", Error, "源栅格几何与像素缓冲长度不符", new_data_span(0, 0))]
        )
    }
    if width == 0 || height == 0 {
        return data_outcome_with(
            media_raster_placeholder(source.format),
            [new_data_diagnostic("media.pipeline.empty_target", Error, "裁剪目标尺寸为 0", new_data_span(0, 0))]
        )
    }
    # u64 载道防 x + width 溢出后误判为界内
    if (x as u64) + (width as u64) > source.width as u64 || (y as u64) + (height as u64) > source.height as u64 {
        return data_outcome_with(
            media_raster_placeholder(source.format),
            [new_data_diagnostic("media.pipeline.crop_out_of_bounds", Error, "裁剪区域越出源图", new_data_span(0, 0))]
        )
    }
    let target: MediaRaster = data_outcome_value(media_raster(width, height, source.format))
    let channels: usize = media_pixel_format_channels(source.format)
    let row_bytes: usize = width * channels
    let mut row: usize = 0
    while row < height {
        let source_row: u64 = (((y + row) as u64) * (source.width as u64) + (x as u64)) * (channels as u64)
        let target_row: usize = row * row_bytes
        let mut column: usize = 0
        while column < row_bytes {
            std::collection::array::set(target.pixels, target_row + column, std::collection::array::get(source.pixels, source_row as usize + column))
            column = column + 1
        }
        row = row + 1
    }
    return data_outcome_of(target)
}

# 最近邻缩放：目标像素 (dx, dy) 取源 ((dx*sw)/dw, (dy*sh)/dh)，乘除在 u64 载道。
micro media_pipeline_resize_nearest(source: MediaRaster, new_width: usize, new_height: usize) -> DataOutcome<MediaRaster> {
    if !media_raster_is_consistent(source) {
        return data_outcome_with(
            media_raster_placeholder(source.format),
            [new_data_diagnostic("media.image.buffer_length_mismatch", Error, "源栅格几何与像素缓冲长度不符", new_data_span(0, 0))]
        )
    }
    if new_width == 0 || new_height == 0 {
        return data_outcome_with(
            media_raster_placeholder(source.format),
            [new_data_diagnostic("media.pipeline.empty_target", Error, "缩放目标尺寸为 0", new_data_span(0, 0))]
        )
    }
    let target: MediaRaster = data_outcome_value(media_raster(new_width, new_height, source.format))
    let channels: usize = media_pixel_format_channels(source.format)
    let mut dy: usize = 0
    while dy < new_height {
        let sy: usize = ((dy as u64) * (source.height as u64) / (new_height as u64)) as usize
        let mut dx: usize = 0
        while dx < new_width {
            let sx: usize = ((dx as u64) * (source.width as u64) / (new_width as u64)) as usize
            let source_base: u64 = (((sy as u64) * (source.width as u64)) + (sx as u64)) * (channels as u64)
            let target_base: usize = (dy * new_width + dx) * channels
            let mut channel: usize = 0
            while channel < channels {
                std::collection::array::set(target.pixels, target_base + channel, std::collection::array::get(source.pixels, source_base as usize + channel))
                channel = channel + 1
            }
            dx = dx + 1
        }
        dy = dy + 1
    }
    return data_outcome_of(target)
}
