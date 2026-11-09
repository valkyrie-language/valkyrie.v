namespace plotter;

# L3 图元：已解析的几何与样式。图元只表达"画成什么"，不表达"为什么"。
#
# 每个图元必须带完整样式；缺省值来自 `style.v` 的构造函数，不允许后端自行
# 兜底。

enums SceneMarkKind {
    Rect
    Line
    Path
    Circle
    Text
}

structure SceneMark {
    kind: SceneMarkKind
    x: f64
    y: f64
    x2: f64
    y2: f64
    width: f64
    height: f64
    radius: f64
    text: utf8
    path: utf8
    style: SceneStyle
}

micro scene_mark_kind_name(kind: SceneMarkKind) -> utf8 {
    match kind {
        case Rect: {
            return "rect"
        }
        case Line: {
            return "line"
        }
        case Path: {
            return "path"
        }
        case Circle: {
            return "circle"
        }
        case Text: {
            return "text"
        }
    }
}

micro kind_rect() -> SceneMarkKind {
    return Rect
}

micro kind_line() -> SceneMarkKind {
    return Line
}

micro kind_path() -> SceneMarkKind {
    return Path
}

micro kind_circle() -> SceneMarkKind {
    return Circle
}

micro kind_text() -> SceneMarkKind {
    return Text
}

micro mark_rect(x: f64, y: f64, width: f64, height: f64, fill: utf8) -> SceneMark {
    return SceneMark {
        kind: kind_rect(),
        x: x,
        y: y,
        x2: 0.0,
        y2: 0.0,
        width: width,
        height: height,
        radius: 0.0,
        text: "",
        path: "",
        style: scene_style(fill, "none", 0.0, 1.0)
    }
}

micro mark_line(x: f64, y: f64, x2: f64, y2: f64, stroke: utf8, stroke_width: f64) -> SceneMark {
    return SceneMark {
        kind: kind_line(),
        x: x,
        y: y,
        x2: x2,
        y2: y2,
        width: 0.0,
        height: 0.0,
        radius: 0.0,
        text: "",
        path: "",
        style: scene_style("none", stroke, stroke_width, 1.0)
    }
}

micro mark_path(path: utf8, stroke: utf8, stroke_width: f64, fill: utf8) -> SceneMark {
    return SceneMark {
        kind: kind_path(),
        x: 0.0,
        y: 0.0,
        x2: 0.0,
        y2: 0.0,
        width: 0.0,
        height: 0.0,
        radius: 0.0,
        text: "",
        path: path,
        style: scene_style(fill, stroke, stroke_width, 1.0)
    }
}

micro mark_circle(x: f64, y: f64, radius: f64, fill: utf8, stroke: utf8) -> SceneMark {
    return SceneMark {
        kind: kind_circle(),
        x: x,
        y: y,
        x2: 0.0,
        y2: 0.0,
        width: 0.0,
        height: 0.0,
        radius: radius,
        text: "",
        path: "",
        style: scene_style(fill, stroke, 1.0, 1.0)
    }
}

micro mark_text(x: f64, y: f64, text: utf8, fill: utf8) -> SceneMark {
    return SceneMark {
        kind: kind_text(),
        x: x,
        y: y,
        x2: 0.0,
        y2: 0.0,
        width: 0.0,
        height: 0.0,
        radius: 0.0,
        text: text,
        path: "",
        style: scene_text_style(fill, 12.0, Start)
    }
}

micro mark_text_anchored(x: f64, y: f64, text: utf8, style: SceneStyle) -> SceneMark {
    return SceneMark {
        kind: kind_text(),
        x: x,
        y: y,
        x2: 0.0,
        y2: 0.0,
        width: 0.0,
        height: 0.0,
        radius: 0.0,
        text: text,
        path: "",
        style: style
    }
}
