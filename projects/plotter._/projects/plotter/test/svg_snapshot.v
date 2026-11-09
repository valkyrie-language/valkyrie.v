namespace plotter;

[test]
micro svg_has_axes_and_title() -> unit {
    let labels: [utf8] = ["x1", "x2"]
    let values: [f64] = [10.0, 20.0]
    let data: DataFrame = dataframe_from_xy(labels, values)
    let mapped: PlotSpec = aes(plot(data), "x", "y")
    let labelled: PlotSpec = labs(geom_col(mapped), "Coverage Features", "feature", "count")
    let sized: PlotSpec = with_size(theme_minimal(labelled), 640.0, 320.0)
    let svg: utf8 = render_svg(sized)

    if !svg.contains("Coverage Features") {
        panic("title missing in svg text")
    }
    if !svg.contains("<line") {
        panic("axes/grid lines missing")
    }
    if !svg.contains("width=" + plotter_quote() + "640") {
        panic("width attribute missing")
    }
}

[test]
micro theme_void_hides_axes() -> unit {
    let labels: [utf8] = ["a"]
    let values: [f64] = [1.0]
    let data: DataFrame = dataframe_from_xy(labels, values)
    let mapped: PlotSpec = aes(plot(data), "x", "y")
    let with_geom: PlotSpec = geom_col(mapped)
    let scene_minimal: Scene = plot_scene(theme_minimal(with_geom))
    let scene_void: Scene = plot_scene(theme_void(with_geom))
    if scene_mark_count(scene_void) >= scene_mark_count(scene_minimal) {
        panic("void theme should emit fewer marks")
    }
}
