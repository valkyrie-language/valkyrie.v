namespace media;

# 像素格式：像素的通道组成与字节排布。
# 打包（packed）布局，通道按变体列出顺序存放；位深固定 8。
# `unite` 而非 `enums`：与 std.data 体系同口径，变体 match 是已验证形态。
unite MediaPixelFormat {
    Gray8
    Rgb8
    Rgba8
}

# 每像素通道数（位深 8，通道数即每像素字节数）。
micro media_pixel_format_channels(format: MediaPixelFormat) -> usize {
    match format {
        case Gray8:
            return 1
        case Rgb8:
            return 3
        case Rgba8:
            return 4
    }
}
