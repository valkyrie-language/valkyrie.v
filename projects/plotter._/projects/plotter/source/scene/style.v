namespace plotter;

# L3 样式：几何之外的视觉属性。后端只按这里的字段发射，不从上层推断。
#
# 颜色采用 CSS 颜色文本；`none` 表示不着色。文本锚点与字体族是文本图元的
# 排版合同，不是某后端的私有选项。

enums TextAnchor {
    Start
    Middle
    End
}

structure SceneStyle {
    fill: utf8
    stroke: utf8
    stroke_width: f64
    opacity: f64
    font_family: utf8
    font_size: f64
    text_anchor: TextAnchor
}

micro scene_style(fill: utf8, stroke: utf8, stroke_width: f64, opacity: f64) -> SceneStyle {
    return SceneStyle {
        fill: fill,
        stroke: stroke,
        stroke_width: stroke_width,
        opacity: opacity,
        font_family: "system-ui, sans-serif",
        font_size: 12.0,
        text_anchor: text_anchor_start()
    }
}

micro scene_text_style(fill: utf8, font_size: f64, anchor: TextAnchor) -> SceneStyle {
    return SceneStyle {
        fill: fill,
        stroke: "none",
        stroke_width: 0.0,
        opacity: 1.0,
        font_family: "system-ui, sans-serif",
        font_size: font_size,
        text_anchor: anchor
    }
}

micro scene_style_with_opacity(style: SceneStyle, opacity: f64) -> SceneStyle {
    return SceneStyle {
        fill: style.fill,
        stroke: style.stroke,
        stroke_width: style.stroke_width,
        opacity: opacity,
        font_family: style.font_family,
        font_size: style.font_size,
        text_anchor: style.text_anchor
    }
}

micro text_anchor_start() -> TextAnchor {
    return Start
}

micro text_anchor_middle() -> TextAnchor {
    return Middle
}

micro text_anchor_end() -> TextAnchor {
    return End
}

micro text_anchor_name(anchor: TextAnchor) -> utf8 {
    match anchor {
        case Start: {
            return "start"
        }
        case Middle: {
            return "middle"
        }
        case End: {
            return "end"
        }
    }
}
