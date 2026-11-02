namespace media;

using std.diagnostic::{Diagnostic, diagnostic_code};

# fixtures.v — 内嵌字节 fixture（最小已知答案样本）。
#
# 为什么不落盘：wasm lane 无 `read_file_bytes` host contract（当前未提供，见 readme），
# 测试与驱动器只能消费内存字节；每段字节的推导配方逐行注释，可用十六进制编辑器复核。

# P6 PPM，2×2：`P6\n2 2\n255\n` + 栅格（行主序：红、绿、蓝、白）。
micro media_fixture_ppm_2x2() -> [u8] {
    return [
        80 as u8, 54 as u8, 10 as u8,
        50 as u8, 32 as u8, 50 as u8,
        10 as u8,
        50 as u8, 53 as u8, 53 as u8, 10 as u8,
        255 as u8, 0 as u8, 0 as u8,
        0 as u8, 255 as u8, 0 as u8,
        0 as u8, 0 as u8, 255 as u8,
        255 as u8, 255 as u8, 255 as u8
    ]
}

# BMP 2×2 24 位 BI_RGB（70 字节）：
# 头 54 字节（文件长 70 = 0x46、数据偏移 54 = 0x36、信息头 40 = 0x28、宽 2、高 2、
# planes 1、位深 24 = 0x18、压缩 0、图像数据 16 = 0x10、分辨率 2835 = 0x0B13）；
# 行自底向上、BGR 序、行填充 2 字节：
# 文件行 0 = 图像行 1（蓝、白），文件行 1 = 图像行 0（红、绿）。
micro media_fixture_bmp_2x2() -> [u8] {
    return [
        66 as u8, 77 as u8, 70 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 54 as u8, 0 as u8, 0 as u8, 0 as u8,
        40 as u8, 0 as u8, 0 as u8, 0 as u8, 2 as u8, 0 as u8, 0 as u8, 0 as u8, 2 as u8, 0 as u8, 0 as u8, 0 as u8, 1 as u8, 0 as u8, 24 as u8, 0 as u8,
        0 as u8, 0 as u8, 0 as u8, 0 as u8, 16 as u8, 0 as u8, 0 as u8, 0 as u8, 19 as u8, 11 as u8, 0 as u8, 0 as u8, 19 as u8, 11 as u8, 0 as u8, 0 as u8,
        0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8, 0 as u8,
        255 as u8, 0 as u8, 0 as u8, 255 as u8, 255 as u8, 255 as u8, 0 as u8, 0 as u8,
        0 as u8, 0 as u8, 255 as u8, 0 as u8, 255 as u8, 0 as u8, 0 as u8, 0 as u8
    ]
}

# PNG 1×1 RGB8（61 字节）：签名 + IHDR（宽高 1、位深 8、颜色 2）+ IDAT（载荷 01 02 03 04，
# 非合法 zlib 流——容器层测试不触及解压）+ IEND；CRC-32 为真实计算值
#（IHDR 0x907753DE、IDAT 0x7D5BC3D6、IEND 0xAE426082）。
micro media_fixture_png_1x1() -> [u8] {
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

# 上一样本的 IDAT CRC 末字节翻转变体（0xD6 → 0x29），触发 crc_mismatch。
micro media_fixture_png_1x1_crc_broken() -> [u8] {
    return [
        137 as u8, 80 as u8, 78 as u8, 71 as u8, 13 as u8, 10 as u8, 26 as u8, 10 as u8,
        0 as u8, 0 as u8, 0 as u8, 13 as u8, 73 as u8, 72 as u8, 68 as u8, 82 as u8,
        0 as u8, 0 as u8, 0 as u8, 1 as u8, 0 as u8, 0 as u8, 0 as u8, 1 as u8, 8 as u8, 2 as u8, 0 as u8, 0 as u8, 0 as u8,
        144 as u8, 119 as u8, 83 as u8, 222 as u8,
        0 as u8, 0 as u8, 0 as u8, 4 as u8, 73 as u8, 68 as u8, 65 as u8, 84 as u8, 1 as u8, 2 as u8, 3 as u8, 4 as u8,
        125 as u8, 91 as u8, 195 as u8, 41 as u8,
        0 as u8, 0 as u8, 0 as u8, 0 as u8, 73 as u8, 69 as u8, 78 as u8, 68 as u8, 174 as u8, 66 as u8, 96 as u8, 130 as u8
    ]
}

# 字节数组逐元素相等（断言辅助；无数组相等运算符）。
micro media_fixture_bytes_equal(left: [u8], right: [u8]) -> bool {
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

# 诊断集合中是否存在指定码（断言辅助）。
micro media_fixture_has_code(diagnostics: [Diagnostic], code: utf8) -> bool {
    let mut index: usize = 0
    while index < std::collection::array::length(diagnostics) {
        if diagnostic_code(std::collection::array::get(diagnostics, index)) == code {
            return true
        }
        index = index + 1
    }
    return false
}
