namespace document.vector;

# SVG 发射原语。所有元素函数返回完整元素文本；文档由 `svg_document` 收口。
# 几何坐标用 `f64`，经 `svg_number` 落文本；消费方保证传入有限值。

# 逐字符转义：`table` 之外原样保留。文本内容转义 `&` `<` `>`；
# 属性值（单引号拼写）额外转义 `'`。
micro svg_escape_text(text: utf8) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 1
    let length: usize = text.length()
    while position <= length {
        let current: char = text[position]
        if current == '&' {
            out = out + "&amp;"
        } else if current == '<' {
            out = out + "&lt;"
        } else if current == '>' {
            out = out + "&gt;"
        } else {
            out = out + std::text::encode_char_as_utf8(current)
        }
        position = position + 1
    }
    return out
}

micro svg_escape_attribute(text: utf8) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 1
    let length: usize = text.length()
    while position <= length {
        let current: char = text[position]
        if current == '&' {
            out = out + "&amp;"
        } else if current == '<' {
            out = out + "&lt;"
        } else if current == '>' {
            out = out + "&gt;"
        } else if current as u32 == 39 {
            # U+0027 单引号：转义字符字面量拼写不可用，按码点比较
            out = out + "&apos;"
        } else {
            out = out + std::text::encode_char_as_utf8(current)
        }
        position = position + 1
    }
    return out
}

micro svg_number(value: f64) -> utf8 {
    return format("{}", value)
}

micro svg_text(x: f64, y: f64, content: utf8, fill: utf8, font_size: f64) -> utf8 {
    return "<text x='" + svg_number(x)
        + "' y='" + svg_number(y)
        + "' fill='" + svg_escape_attribute(fill)
        + "' font-size='" + svg_number(font_size)
        + "' font-family='monospace'>"
        + svg_escape_text(content)
        + "</text>"
}

micro svg_rect(x: f64, y: f64, width: f64, height: f64, fill: utf8) -> utf8 {
    return "<rect x='" + svg_number(x)
        + "' y='" + svg_number(y)
        + "' width='" + svg_number(width)
        + "' height='" + svg_number(height)
        + "' fill='" + svg_escape_attribute(fill)
        + "'/>"
}

micro svg_line(x1: f64, y1: f64, x2: f64, y2: f64, stroke: utf8, stroke_width: f64) -> utf8 {
    return "<line x1='" + svg_number(x1)
        + "' y1='" + svg_number(y1)
        + "' x2='" + svg_number(x2)
        + "' y2='" + svg_number(y2)
        + "' stroke='" + svg_escape_attribute(stroke)
        + "' stroke-width='" + svg_number(stroke_width)
        + "'/>"
}

# 路径：`data` 是调用方拼好的 path data；装饰用实心路径传 `fill`，描线路径传 `none`。
micro svg_path(data: utf8, stroke: utf8, stroke_width: f64, fill: utf8) -> utf8 {
    return "<path d='" + svg_escape_attribute(data)
        + "' stroke='" + svg_escape_attribute(stroke)
        + "' stroke-width='" + svg_number(stroke_width)
        + "' fill='" + svg_escape_attribute(fill)
        + "'/>"
}

micro svg_circle(cx: f64, cy: f64, radius: f64, fill: utf8) -> utf8 {
    return "<circle cx='" + svg_number(cx)
        + "' cy='" + svg_number(cy)
        + "' r='" + svg_number(radius)
        + "' fill='" + svg_escape_attribute(fill)
        + "'/>"
}

micro svg_group(body: utf8) -> utf8 {
    return "<g>" + body + "</g>"
}

# path data 便捷构造：M/L 段，坐标对经 `svg_number` 落文本。
micro svg_path_move_to(x: f64, y: f64) -> utf8 {
    return "M " + svg_number(x) + " " + svg_number(y)
}

micro svg_path_line_to(data: utf8, x: f64, y: f64) -> utf8 {
    return data + " L " + svg_number(x) + " " + svg_number(y)
}

micro svg_document(width: f64, height: f64, body: utf8) -> utf8 {
    return "<svg xmlns='http://www.w3.org/2000/svg' width='" + svg_number(width)
        + "' height='" + svg_number(height)
        + "' viewBox='0 0 " + svg_number(width) + " " + svg_number(height)
        + "'>" + body + "</svg>"
}
