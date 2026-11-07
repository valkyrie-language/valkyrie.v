namespace plotter;

# PlotSpec 轻量序列化契约（von/JSON 文本），供 legion 等外部工具接入。

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

micro plot_spec_to_json(spec: PlotSpec) -> utf8 {
    let q: utf8 = quote_text()
    let mut geoms_json: utf8 = "["
    let mut index: usize = 0
    while index < spec.geoms.length() {
        if index > 0 {
            geoms_json = geoms_json + ","
        }
        let layer: GeomLayer = spec.geoms[index]
        geoms_json = geoms_json + "{" + q + "kind" + q + ":" + q + geom_kind_name(layer.kind) + q
        geoms_json = geoms_json + "," + q + "bins" + q + ":" + format("{}", layer.bins)
        geoms_json = geoms_json + "," + q + "intercept" + q + ":" + format("{}", layer.intercept) + "}"
        index = index + 1
    }
    geoms_json = geoms_json + "]"

    let mut columns_json: utf8 = "["
    index = 0
    while index < spec.data.columns.length() {
        if index > 0 {
            columns_json = columns_json + ","
        }
        let column: Column = spec.data.columns[index]
        columns_json = columns_json + "{" + q + "name" + q + ":" + q + column.name + q
        let is_numeric_text: utf8 = if column.is_numeric { "true" } else { "false" }
        columns_json = columns_json + "," + q + "is_numeric" + q + ":" + is_numeric_text
        columns_json = columns_json + "," + q + "length" + q + ":"
        columns_json = columns_json + format("{}", if column.is_numeric { column.numbers.length() } else { column.labels.length() }) + "}"
        index = index + 1
    }
    columns_json = columns_json + "]"

    let mut out: utf8 = "{"
    out = out + q + "width" + q + ":" + format("{}", spec.width) + ","
    out = out + q + "height" + q + ":" + format("{}", spec.height) + ","
    out = out + q + "title" + q + ":" + q + spec.title + q + ","
    out = out + q + "subtitle" + q + ":" + q + spec.subtitle + q + ","
    out = out + q + "x_lab" + q + ":" + q + spec.x_lab + q + ","
    out = out + q + "y_lab" + q + ":" + q + spec.y_lab + q + ","
    out = out + q + "theme_id" + q + ":" + format("{}", spec.theme_id) + ","
    out = out + q + "aes" + q + ":{" + q + "x" + q + ":" + q + spec.aes.x + q + ","
    out = out + q + "y" + q + ":" + q + spec.aes.y + q + ","
    out = out + q + "fill" + q + ":" + q + spec.aes.fill + q + ","
    out = out + q + "color" + q + ":" + q + spec.aes.color + q + ","
    out = out + q + "size" + q + ":" + q + spec.aes.size + q + "},"
    let x_continuous_text: utf8 = if spec.x_continuous { "true" } else { "false" }
    let y_continuous_text: utf8 = if spec.y_continuous { "true" } else { "false" }
    let x_discrete_text: utf8 = if spec.x_discrete { "true" } else { "false" }
    let y_discrete_text: utf8 = if spec.y_discrete { "true" } else { "false" }
    out = out + q + "scales" + q + ":{" + q + "x_continuous" + q + ":" + x_continuous_text + ","
    out = out + q + "y_continuous" + q + ":" + y_continuous_text + ","
    out = out + q + "x_discrete" + q + ":" + x_discrete_text + ","
    out = out + q + "y_discrete" + q + ":" + y_discrete_text + "},"
    out = out + q + "geoms" + q + ":" + geoms_json + ","
    out = out + q + "data" + q + ":{" + q + "row_count" + q + ":" + format("{}", spec.data.row_count) + ","
    out = out + q + "columns" + q + ":" + columns_json + "}"
    out = out + "}"
    return out
}

micro plot_spec_to_von(spec: PlotSpec) -> utf8 {
    # von 形态与 JSON 字段同构，外层用花括号与键值。
    return plot_spec_to_json(spec)
        .replace(quote_text() + ":", ": ")
        .replace("," + quote_text(), ", ")
        .replace("{" + quote_text(), "{ ")
}
