namespace plotter;

# PlotSpec 轻量序列化契约（JSON 文本），供 legion 等外部工具接入。
#
# 这是语义模型的导出，不是渲染后端：不含坐标、不含场景图元。

micro json_escape(text: utf8) -> utf8 {
    return text
        .replace("\\", "\\\\")
        .replace(plotter_quote(), "\\" + plotter_quote())
}

micro json_string(value: utf8) -> utf8 {
    return plotter_quote() + json_escape(value) + plotter_quote()
}

micro json_bool(value: bool) -> utf8 {
    if value {
        return "true"
    }
    return "false"
}

micro geom_kind_name(kind: i32) -> utf8 {
    if kind == 0 { return "col" }
    if kind == 1 { return "bar" }
    if kind == 2 { return "point" }
    if kind == 3 { return "line" }
    if kind == 4 { return "histogram" }
    if kind == 5 { return "hline" }
    if kind == 6 { return "vline" }
    return "unknown"
}

micro geom_layer_json(layer: GeomLayer) -> utf8 {
    let mut body: utf8 = "{"
    body = body + json_string("kind") + ":"
    body = body + json_string(geom_kind_name(layer.kind)) + ","
    body = body + json_string("bins") + ":" + i64_text(layer.bins as i64) + ","
    body = body + json_string("intercept") + ":" + plotter_num(layer.intercept)
    body = body + "}"
    return body
}

micro column_json(column: Column) -> utf8 {
    let mut body: utf8 = "{"
    body = body + json_string("name") + ":" + json_string(column.name) + ","
    body = body + json_string("is_numeric") + ":" + json_bool(column.is_numeric) + ","
    body = body + json_string("length") + ":"
    if column.is_numeric {
        body = body + i64_text(column.numbers.length() as i64)
    } else {
        body = body + i64_text(column.labels.length() as i64)
    }
    body = body + "}"
    return body
}

micro geoms_json(spec: PlotSpec) -> utf8 {
    let mut body: utf8 = "["
    let mut index: usize = 0
    while index < spec.geoms.length() {
        if index > 0 {
            body = body + ","
        }
        body = body + geom_layer_json(spec.geoms⁅index⁆)
        index = index + 1
    }
    body = body + "]"
    return body
}

micro columns_json(spec: PlotSpec) -> utf8 {
    let mut body: utf8 = "["
    let mut index: usize = 0
    while index < spec.data.columns.length() {
        if index > 0 {
            body = body + ","
        }
        body = body + column_json(spec.data.columns⁅index⁆)
        index = index + 1
    }
    body = body + "]"
    return body
}

micro aes_json(spec: PlotSpec) -> utf8 {
    let mut body: utf8 = "{"
    body = body + json_string("x") + ":" + json_string(spec.aes.x) + ","
    body = body + json_string("y") + ":" + json_string(spec.aes.y) + ","
    body = body + json_string("fill") + ":" + json_string(spec.aes.fill) + ","
    body = body + json_string("color") + ":" + json_string(spec.aes.color) + ","
    body = body + json_string("size") + ":" + json_string(spec.aes.size)
    body = body + "}"
    return body
}

micro scales_json(spec: PlotSpec) -> utf8 {
    let mut body: utf8 = "{"
    body = body + json_string("x_continuous") + ":" + json_bool(spec.x_continuous) + ","
    body = body + json_string("y_continuous") + ":" + json_bool(spec.y_continuous) + ","
    body = body + json_string("x_discrete") + ":" + json_bool(spec.x_discrete) + ","
    body = body + json_string("y_discrete") + ":" + json_bool(spec.y_discrete)
    body = body + "}"
    return body
}

micro data_json(spec: PlotSpec) -> utf8 {
    let mut body: utf8 = "{"
    body = body + json_string("row_count") + ":" + i64_text(spec.data.row_count as i64) + ","
    body = body + json_string("columns") + ":" + columns_json(spec)
    body = body + "}"
    return body
}

micro plot_spec_to_json(spec: PlotSpec) -> utf8 {
    let mut body: utf8 = "{"
    body = body + json_string("width") + ":" + plotter_num(spec.width) + ","
    body = body + json_string("height") + ":" + plotter_num(spec.height) + ","
    body = body + json_string("title") + ":" + json_string(spec.title) + ","
    body = body + json_string("subtitle") + ":" + json_string(spec.subtitle) + ","
    body = body + json_string("x_lab") + ":" + json_string(spec.x_lab) + ","
    body = body + json_string("y_lab") + ":" + json_string(spec.y_lab) + ","
    body = body + json_string("theme_id") + ":" + i64_text(spec.theme_id as i64) + ","
    body = body + json_string("aes") + ":" + aes_json(spec) + ","
    body = body + json_string("scales") + ":" + scales_json(spec) + ","
    body = body + json_string("geoms") + ":" + geoms_json(spec) + ","
    body = body + json_string("data") + ":" + data_json(spec)
    body = body + "}"
    return body
}
