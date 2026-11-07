namespace plotter;

# SVG 渲染后端：PlotScene -> utf8，无 DOM 依赖。

micro escape_xml(text: utf8) -> utf8 {
    return text
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace(quote_text(), "&quot;")
}

micro render_svg(spec: PlotSpec) -> utf8 {
    return render_svg_sized(spec, spec.width, spec.height)
}

micro render_svg_sized(spec: PlotSpec, width: f64, height: f64) -> utf8 {
    let sized: PlotSpec = with_size(spec, width, height)
    let scene: PlotScene = build_scene(sized)
    return scene_to_svg(scene)
}

micro scene_to_svg(scene: PlotScene) -> utf8 {
    let mut body: utf8 = ""
    let mut index: usize = 0
    while index < scene.marks.length() {
        body = body + mark_to_svg(scene.marks⁅index⁆)
        index = index + 1
    }

    let q: utf8 = quote_text()
    let mut out: utf8 = "<svg xmlns=" + q + "http://www.w3.org/2000/svg" + q
    out = out + " width=" + q + format("{}", scene.width) + q
    out = out + " height=" + q + format("{}", scene.height) + q
    out = out + " viewBox=" + q + "0 0 " + format("{}", scene.width) + " " + format("{}", scene.height) + q
    out = out + ">"
    out = out + "<rect width=" + q + "100%" + q
    out = out + " height=" + q + "100%" + q
    out = out + " fill=" + q + "#ffffff" + q + "/>"
    out = out + body
    out = out + "</svg>"
    return out
}

micro mark_to_svg(mark: Mark) -> utf8 {
    let q: utf8 = quote_text()
    if mark.kind == 0 {
        let mut out: utf8 = "<rect x=" + q + format("{}", mark.x)
        out = out + q + " y=" + q + format("{}", mark.y)
        out = out + q + " width=" + q + format("{}", mark.width)
        out = out + q + " height=" + q + format("{}", mark.height)
        out = out + q + " fill=" + q + mark.fill
        out = out + q + "/>"
        return out
    }
    if mark.kind == 1 {
        let mut out: utf8 = "<line x1=" + q + format("{}", mark.x)
        out = out + q + " y1=" + q + format("{}", mark.y)
        out = out + q + " x2=" + q + format("{}", mark.x2)
        out = out + q + " y2=" + q + format("{}", mark.y2)
        out = out + q + " stroke=" + q + mark.stroke
        out = out + q + " stroke-width=" + q + format("{}", mark.stroke_width)
        out = out + q + "/>"
        return out
    }
    if mark.kind == 2 {
        let mut out: utf8 = "<path d=" + q + mark.path
        out = out + q + " fill=" + q + mark.fill
        out = out + q + " stroke=" + q + mark.stroke
        out = out + q + " stroke-width=" + q + format("{}", mark.stroke_width)
        out = out + q + " fill-opacity=" + q + "0"
        out = out + q + "/>"
        return out
    }
    if mark.kind == 3 {
        let mut out: utf8 = "<circle cx=" + q + format("{}", mark.x)
        out = out + q + " cy=" + q + format("{}", mark.y)
        out = out + q + " r=" + q + format("{}", mark.radius)
        out = out + q + " fill=" + q + mark.fill
        out = out + q + " stroke=" + q + mark.stroke
        out = out + q + "/>"
        return out
    }
    if mark.kind == 4 {
        let mut out: utf8 = "<text x=" + q + format("{}", mark.x)
        out = out + q + " y=" + q + format("{}", mark.y)
        out = out + q + " fill=" + q + mark.fill
        out = out + q + " font-family=" + q + "system-ui,sans-serif"
        out = out + q + " font-size=" + q + "12"
        out = out + q + ">"
        out = out + escape_xml(mark.text)
        out = out + "</text>"
        return out
    }
    return ""
}
