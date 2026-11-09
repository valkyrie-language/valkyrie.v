namespace plotter;

# SVG 后端：Scene -> utf8，无 DOM 依赖。
#
# 只消费 L3 场景：不读 PlotSpec、不读 GraphModel、不认识任何方言。图层按场景
# 中的顺序发射；带裁剪的图层包在 `<g clip-path>` 里，裁剪矩形进 `<defs>`。

micro escape_xml(text: utf8) -> utf8 {
    return text
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace(plotter_quote(), "&quot;")
}

micro svg_attr(name: utf8, value: utf8) -> utf8 {
    return " " + name + "=" + plotter_quote() + escape_xml(value) + plotter_quote()
}

micro svg_number(name: utf8, value: f64) -> utf8 {
    return " " + name + "=" + plotter_quote() + plotter_num(value) + plotter_quote()
}

micro scene_to_svg(scene: Scene) -> utf8 {
    let mut defs: utf8 = ""
    let mut body: utf8 = ""
    let mut index: usize = 0
    while index < scene.layers.length() {
        let layer: SceneLayer = scene.layers⁅index⁆
        defs = defs + layer_clip_def(layer)
        body = body + layer_open(layer)
        let mut mark_index: usize = 0
        while mark_index < layer.marks.length() {
            body = body + mark_to_svg(layer.marks⁅mark_index⁆)
            mark_index = mark_index + 1
        }
        body = body + "</g>"
        index = index + 1
    }

    let defs_block: utf8 = if defs.equals("") { "" } else { "<defs>" + defs + "</defs>" }
    let mut out: utf8 = "<svg"
    out = out + " xmlns=" + plotter_quote() + "http://www.w3.org/2000/svg" + plotter_quote()
    out = out + svg_number("width", scene.width)
    out = out + svg_number("height", scene.height)
    out = out + " viewBox=" + plotter_quote() + "0 0 " + plotter_num(scene.width) + " " + plotter_num(scene.height) + plotter_quote()
    out = out + ">"
    out = out + "<rect"
    out = out + svg_attr("width", "100%")
    out = out + svg_attr("height", "100%")
    out = out + svg_attr("fill", scene.background)
    out = out + "/>"
    out = out + defs_block
    out = out + body
    out = out + "</svg>"
    return out
}

micro layer_clip_def(layer: SceneLayer) -> utf8 {
    if layer.clip.is_none() {
        return ""
    }
    let clip: ClipRect = layer.clip.unwrap()
    return "<clipPath id=" + plotter_quote() + "clip-" + layer.id + plotter_quote() + ">"
        + "<rect"
        + svg_number("x", clip.x)
        + svg_number("y", clip.y)
        + svg_number("width", clip.width)
        + svg_number("height", clip.height)
        + "/></clipPath>"
}

micro layer_open(layer: SceneLayer) -> utf8 {
    if layer.clip.is_none() {
        return "<g" + svg_attr("id", layer.id) + ">"
    }
    return "<g"
        + svg_attr("id", layer.id)
        + " clip-path=" + plotter_quote() + "url(#clip-" + layer.id + ")" + plotter_quote()
        + ">"
}

micro mark_kind_code(mark: SceneMark) -> i32 {
    match mark.kind {
        case Rect: {
            return 0
        }
        case Line: {
            return 1
        }
        case Path: {
            return 2
        }
        case Circle: {
            return 3
        }
        case Text: {
            return 4
        }
    }
}

micro style_attrs(style: SceneStyle) -> utf8 {
    return svg_attr("fill", style.fill)
        + svg_attr("stroke", style.stroke)
        + svg_number("stroke-width", style.stroke_width)
        + svg_number("fill-opacity", style.opacity)
}

micro mark_to_svg(mark: SceneMark) -> utf8 {
    let code: i32 = mark_kind_code(mark)
    if code == 0 {
        return "<rect"
            + svg_number("x", mark.x)
            + svg_number("y", mark.y)
            + svg_number("width", mark.width)
            + svg_number("height", mark.height)
            + style_attrs(mark.style)
            + "/>"
    }
    if code == 1 {
        return "<line"
            + svg_number("x1", mark.x)
            + svg_number("y1", mark.y)
            + svg_number("x2", mark.x2)
            + svg_number("y2", mark.y2)
            + style_attrs(mark.style)
            + "/>"
    }
    if code == 2 {
        return "<path"
            + svg_attr("d", mark.path)
            + style_attrs(mark.style)
            + "/>"
    }
    if code == 3 {
        return "<circle"
            + svg_number("cx", mark.x)
            + svg_number("cy", mark.y)
            + svg_number("r", mark.radius)
            + style_attrs(mark.style)
            + "/>"
    }
    return "<text"
        + svg_number("x", mark.x)
        + svg_number("y", mark.y)
        + style_attrs(mark.style)
        + svg_attr("font-family", mark.style.font_family)
        + svg_number("font-size", mark.style.font_size)
        + svg_attr("text-anchor", text_anchor_name(mark.style.text_anchor))
        + ">"
        + escape_xml(mark.text)
        + "</text>"
}
