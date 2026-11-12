namespace plotter;

# 组合根：把 L1 语义经 L2 解析成 L3，再交给某个 L4 后端。
#
# 这里只做串联，不做任何语义判断或渲染细节；因此它既不属于语义层也不属于
# 后端层。调用方可以只用 `plot_scene` 拿场景，自己挑选后端。

micro plot_scene(spec: PlotSpec) -> Scene {
    return resolve_stat_scene(spec)
}

micro plot_scene_sized(spec: PlotSpec, width: f64, height: f64) -> Scene {
    return resolve_stat_scene(with_size(spec, width, height))
}

micro render_svg(spec: PlotSpec) -> utf8 {
    return scene_to_svg(plot_scene(spec))
}

micro render_svg_sized(spec: PlotSpec, width: f64, height: f64) -> utf8 {
    return scene_to_svg(plot_scene_sized(spec, width, height))
}
