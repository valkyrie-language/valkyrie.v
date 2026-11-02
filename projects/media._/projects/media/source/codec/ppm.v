namespace media;

using std.data::{DataOutcome, data_outcome_of, data_outcome_partial, data_outcome_failed, data_outcome_has_errors, data_outcome_diagnostics, data_outcome_value_or};
using std.diagnostic::{Diagnostic, Error, Warning, new_diagnostic, new_span};
using std.data.binary.codec::{DataByteCursor, data_byte_cursor, data_byte_view_of};

# ppm.v — PPM（P6 二进制栅格）读写适配器。
#
# P6 头部文法：magic 后各 token 前允许任意空白与 `#` 行注释，maxval 之后恰一个
# 空白字节即进入栅格（规格即此；多出的字节按栅格/尾部处理，不猜测跳过）。
#   "P6" <ws>* <width> <ws> <height> <ws> <maxval=255> <ws:1> <width*height*3 字节>
#
# 字符纪律：字节值拓宽到 u32 后与字符字面量比较（工具链按形参特化），
# 不写数字码点；u8 载体在各后端刻意无比较 provider。

micro media_ppm_maxval_supported() -> u64 {
    return 255
}

micro media_ppm_is_whitespace(byte: u8) -> bool {
    let value: u32 = byte as u32
    # 水平制表 / 换行 / 回车 / 空格（P6 规格的空白集合）
    return value == '\t' || value == '\n' || value == '\r' || value == ' '
}

micro media_ppm_is_digit(byte: u8) -> bool {
    let value: u32 = byte as u32
    return value >= '0' && value <= '9'
}

# 换行字节写出（`\n` 的 u8 形态）。
micro media_internal_lf_byte() -> u8 {
    return ('\n' as u32) as u8
}

# 头段 token 读取结果：十进制值 + 推进后的游标（停在 token 终止空白/注释之后）。
structure MediaPpmToken {
    value: u64
    cursor: DataByteCursor
}

# 读一个十进制头段 token：跳过前导空白与 `#` 注释，累加数字，遇首个空白/注释终止。
# 失败形态：输入耗尽（truncated_header）或非法字节（bad_header_byte），一律 `Failed`。
micro media_ppm_read_token(cursor: DataByteCursor) -> DataOutcome<MediaPpmToken> {
    let mut current: DataByteCursor = cursor
    let mut value: u64 = 0
    let mut in_token: bool = false
    let mut done: bool = false
    let mut failure: usize = 0
    while !done && failure == 0 {
        let step: DataOutcome<u8> = current.read_u8()
        if data_outcome_has_errors(step) {
            failure = 1
        } else {
            let byte: u8 = data_outcome_value_or(step, 0 as u8)
            if media_ppm_is_digit(byte) {
                in_token = true
                value = value * 10 + (((byte as u32) - '0') as u64)
            } else if media_ppm_is_whitespace(byte) {
                if in_token {
                    done = true
                }
            } else if (byte as u32) == '#' {
                if in_token {
                    done = true
                }
                let mut in_comment: bool = true
                while in_comment {
                    let comment_step: DataOutcome<u8> = current.read_u8()
                    if data_outcome_has_errors(comment_step) {
                        in_comment = false
                        failure = 1
                    } else {
                        if (data_outcome_value_or(comment_step, 0 as u8) as u32) == '\n' {
                            in_comment = false
                        }
                    }
                }
            } else {
                failure = 2
            }
        }
    }
    if failure == 1 {
        let at: usize = current.position()
        return data_outcome_failed(
            [new_diagnostic("media.ppm.truncated_header", Error, "头段 token 未读完输入即耗尽", new_span(at, at))]
        )
    }
    if failure == 2 {
        let at: usize = current.position()
        return data_outcome_failed(
            [new_diagnostic("media.ppm.bad_header_byte", Error, "头段出现非数字非空白字节", new_span(at, at))]
        )
    }
    if !in_token {
        let at: usize = current.position()
        return data_outcome_failed(
            [new_diagnostic("media.ppm.truncated_header", Error, "头段 token 缺失（全空白或全注释）", new_span(at, at))]
        )
    }
    return data_outcome_of(MediaPpmToken { value: value, cursor: current })
}

# 十进制数字位数（u64 载道；零占一位）。
micro media_internal_decimal_digit_count(value: u64) -> usize {
    let mut count: usize = 1
    let mut rest: u64 = value / 10
    while rest > 0 {
        count = count + 1
        rest = rest / 10
    }
    return count
}

# 在 `offset` 起写入恰好 `count` 位十进制数字，返回写完后的偏移。
micro media_internal_write_decimal(bytes: [u8], offset: usize, value: u64, count: usize) -> usize {
    let mut remaining: u64 = value
    let mut written: usize = 0
    while written < count {
        let digit: u32 = (remaining % 10) as u32
        std::collection::array::set(bytes, offset + count - 1 - written, (('0' as u32) + digit) as u8)
        remaining = remaining / 10
        written = written + 1
    }
    return offset + count
}

# P6 写出：RGB8 栅格（Gray8 复制通道、Rgba8 丢 alpha，经 `media_color_convert`）。
# 布局 `P6\n<w> <h>\n255\n<栅格>`；一次分配后顺序填充，无二次拷贝。
micro media_ppm_write(source: MediaRaster) -> DataOutcome<[u8]> {
    if !media_raster_is_consistent(source) {
        return data_outcome_failed(
            [new_diagnostic("media.image.buffer_length_mismatch", Error, "源栅格几何与像素缓冲长度不符", new_span(0, 0))]
        )
    }
    let rgb: MediaRaster = data_outcome_value_or(media_color_convert(source, Rgb8), media_raster_empty_sentinel(Rgb8))
    let width_digits: usize = media_internal_decimal_digit_count(rgb.width as u64)
    let height_digits: usize = media_internal_decimal_digit_count(rgb.height as u64)
    # 头部布局：P6\n(3) + 宽 + 空格(1) + 高 + \n(1) + 255\n(4)
    let header_bytes: usize = 3 + width_digits + 1 + height_digits + 1 + 4
    let raster_bytes: usize = std::collection::array::length(rgb.pixels)
    let out: [u8] = std::collection::array::new::<u8>(header_bytes + raster_bytes)
    std::collection::array::set(out, 0, b'P')
    std::collection::array::set(out, 1, b'6')
    std::collection::array::set(out, 2, media_internal_lf_byte())
    let mut at: usize = media_internal_write_decimal(out, 3, rgb.width as u64, width_digits)
    std::collection::array::set(out, at, b' ')
    at = at + 1
    at = media_internal_write_decimal(out, at, rgb.height as u64, height_digits)
    std::collection::array::set(out, at, media_internal_lf_byte())
    std::collection::array::set(out, at + 1, b'2')
    std::collection::array::set(out, at + 2, b'5')
    std::collection::array::set(out, at + 3, b'5')
    std::collection::array::set(out, at + 4, media_internal_lf_byte())
    at = at + 5
    let mut index: usize = 0
    while index < raster_bytes {
        std::collection::array::set(out, at + index, std::collection::array::get(rgb.pixels, index))
        index = index + 1
    }
    return data_outcome_of(out)
}

# P6 读入：完整头段文法 + 栅格长度校验。硬性失败一律 `Failed`（无值）；
# 错误容许：栅格截断时保留已读前缀（其余为零初始化）走 `Partial`，
# 栅格后多余字节记 Warning `media.ppm.trailing_bytes`，不影响结果置信度。
micro media_ppm_read(bytes: [u8]) -> DataOutcome<MediaRaster> {
    let mut cursor: DataByteCursor = data_byte_cursor(data_byte_view_of(bytes))
    if (cursor.remaining() as u64) < 2 {
        return data_outcome_failed(
            [new_diagnostic("media.ppm.bad_magic", Error, "输入不足 2 字节，无 PPM 魔数", new_span(0, 0))]
        )
    }
    let magic_head: u32 = data_outcome_value_or(cursor.read_u8(), 0 as u8) as u32
    let magic_tail: u32 = data_outcome_value_or(cursor.read_u8(), 0 as u8) as u32
    if magic_head != 'P' {
        return data_outcome_failed(
            [new_diagnostic("media.ppm.bad_magic", Error, "魔数非 P6/P3", new_span(0, 2))]
        )
    }
    if magic_tail == '3' {
        return data_outcome_failed(
            [new_diagnostic("media.ppm.unsupported_variant", Error, "P3（ASCII 栅格）暂不提供", new_span(0, 2))]
        )
    }
    if magic_tail != '6' {
        return data_outcome_failed(
            [new_diagnostic("media.ppm.bad_magic", Error, "魔数非 P6/P3", new_span(0, 2))]
        )
    }
    let width_outcome: DataOutcome<MediaPpmToken> = media_ppm_read_token(cursor)
    if data_outcome_has_errors(width_outcome) {
        return data_outcome_failed(data_outcome_diagnostics(width_outcome))
    }
    cursor = data_outcome_value_or(width_outcome, MediaPpmToken { value: 0, cursor: cursor }).cursor
    let height_outcome: DataOutcome<MediaPpmToken> = media_ppm_read_token(cursor)
    if data_outcome_has_errors(height_outcome) {
        return data_outcome_failed(data_outcome_diagnostics(height_outcome))
    }
    cursor = data_outcome_value_or(height_outcome, MediaPpmToken { value: 0, cursor: cursor }).cursor
    let maxval_outcome: DataOutcome<MediaPpmToken> = media_ppm_read_token(cursor)
    if data_outcome_has_errors(maxval_outcome) {
        return data_outcome_failed(data_outcome_diagnostics(maxval_outcome))
    }
    cursor = data_outcome_value_or(maxval_outcome, MediaPpmToken { value: 0, cursor: cursor }).cursor
    if data_outcome_value_or(maxval_outcome, MediaPpmToken { value: 0, cursor: cursor }).value != media_ppm_maxval_supported() {
        let at: usize = cursor.position()
        return data_outcome_failed(
            [new_diagnostic("media.ppm.unsupported_maxval", Error, "maxval 不等于 255", new_span(at, at))]
        )
    }
    let width: u64 = data_outcome_value_or(width_outcome, MediaPpmToken { value: 0, cursor: cursor }).value
    let height: u64 = data_outcome_value_or(height_outcome, MediaPpmToken { value: 0, cursor: cursor }).value
    let raster_outcome: DataOutcome<MediaRaster> = media_raster(width as usize, height as usize, Rgb8)
    if data_outcome_has_errors(raster_outcome) {
        return data_outcome_failed(data_outcome_diagnostics(raster_outcome))
    }
    let raster: MediaRaster = data_outcome_value_or(raster_outcome, media_raster_empty_sentinel(Rgb8))
    let mut diagnostics: [Diagnostic] = []
    let wanted: usize = std::collection::array::length(raster.pixels)
    let mut index: usize = 0
    let mut truncated: bool = false
    while index < wanted && !truncated {
        let step: DataOutcome<u8> = cursor.read_u8()
        if data_outcome_has_errors(step) {
            truncated = true
        } else {
            std::collection::array::set(raster.pixels, index, data_outcome_value_or(step, 0 as u8))
            index = index + 1
        }
    }
    if truncated {
        diagnostics = std::collection::push(diagnostics, new_diagnostic("media.ppm.truncated_raster", Error, "栅格字节数不足 宽×高×3", new_span(index, index)))
    } else {
        if cursor.remaining() > 0 {
            let at: usize = cursor.position()
            diagnostics = std::collection::push(diagnostics, new_diagnostic("media.ppm.trailing_bytes", Warning, "栅格后有多余字节", new_span(at, at)))
        }
    }
    return data_outcome_partial(raster, diagnostics)
}
