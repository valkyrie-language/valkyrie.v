namespace plotter;

# L3 场景：前后端唯一接缝。
#
# 场景只持有已解析的像素空间内容：尺寸、背景、图层。图层数组的顺序就是绘制
# 顺序；`clip` 是可选裁剪矩形，`None` 表示不裁剪。
#
# 场景不含数据列、标度、美学映射、方言结构；任何上层概念要进入渲染，必须先
# 被解析成这里的图层与图元。

structure ClipRect {
    x: f64
    y: f64
    width: f64
    height: f64
}

structure SceneLayer {
    id: utf8
    clip: Option<ClipRect>
    marks: [SceneMark]
}

structure Scene {
    width: f64
    height: f64
    background: utf8
    layers: [SceneLayer]
}

micro clip_rect(x: f64, y: f64, width: f64, height: f64) -> ClipRect {
    return ClipRect {
        x: x,
        y: y,
        width: width,
        height: height
    }
}

micro scene_layer(id: utf8, clip: Option<ClipRect>) -> SceneLayer {
    return SceneLayer {
        id: id,
        clip: clip,
        marks: []
    }
}

micro scene_layer_of(id: utf8, clip: Option<ClipRect>, marks: [SceneMark]) -> SceneLayer {
    return SceneLayer {
        id: id,
        clip: clip,
        marks: marks
    }
}

micro scene_mark_count(scene: Scene) -> usize {
    let mut count: usize = 0
    let mut index: usize = 0
    while index < scene.layers.length() {
        count = count + scene.layers⁅index⁆.marks.length()
        index = index + 1
    }
    return count
}
