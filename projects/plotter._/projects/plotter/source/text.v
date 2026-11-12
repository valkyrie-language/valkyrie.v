namespace plotter;

# 层中立文本工具：数字文本化与引号字符。
#
# L2 用它们拼路径命令，L4 用它们拼属性值，L1 的模型导出也用它们。这里不含
# 任何语义、布局或方言知识。
#
# f64 文本化固定两位小数并去掉尾随零；这是场景坐标的精度合同（不是显示
# 格式选项）。非有限值（NaN / inf）按 `0` 输出，避免生成不可解析的几何。

micro plotter_quote() -> utf8 {
    return std::text::encode_char_as_utf8('"')
}

micro digit_text(digit: i64) -> utf8 {
    let digits: [utf8] = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
    ]
    if digit < 0 || digit > 9 {
        return "0"
    }
    return digits⁅digit as usize⁆
}

micro i64_text(value: i64) -> utf8 {
    if value == 0 {
        return "0"
    }
    let mut magnitude: i64 = value
    let mut negative: bool = false
    if value < 0 {
        negative = true
        magnitude = 0 - value
    }
    let mut out: utf8 = ""
    while magnitude > 0 {
        let digit: i64 = magnitude % 10
        out = digit_text(digit) ++ out
        magnitude = magnitude / 10
    }
    if negative {
        return "-" ++ out
    }
    return out
}

micro plotter_num(value: f64) -> utf8 {
    let self_difference: f64 = value - value
    if self_difference != 0.0 {
        return "0"
    }
    let scaled: i64 = (value * 100.0) as i64
    let mut negative: bool = false
    if scaled < 0 {
        negative = true
    }
    let magnitude: i64 = if negative { 0 - scaled } else { scaled }
    let int_part: i64 = magnitude / 100
    let fraction: i64 = magnitude % 100

    let mut out: utf8 = i64_text(int_part)
    if fraction > 0 {
        out = out ++ "."
        if fraction < 10 {
            out = out ++ "0" ++ i64_text(fraction)
        } else if fraction % 10 == 0 {
            out = out ++ i64_text(fraction / 10)
        } else {
            out = out ++ i64_text(fraction)
        }
    }
    if negative {
        return "-" ++ out
    }
    return out
}
