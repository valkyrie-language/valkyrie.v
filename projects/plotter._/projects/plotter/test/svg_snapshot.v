namespace plotter;

[test]
micro svg_has_axes_and_title() -> unit {
    let data: DataFrame = dataframe_from_xy(["x1", "x2"], [10.0, 20.0])
    let svg: utf8 = render_svg(
        with_size(
            theme_minimal(
                labs(
                    geom_col(
                        aes(plot(data), "x", "y")
                    ),
                    "Coverage Features",
                    "feature",
                    "count"
                )
            ),
            640.0,
            320.0
        )
    )

    if !svg.contains("Coverage Features") {
        panic("title missing in svg text")
    }
    if !svg.contains("<line") {
        panic("axes/grid lines missing")
    }
    if !svg.contains("width=" + quote_text() + "640") {
        panic("width attribute missing")
    }
}

[test]
micro theme_void_hides_axes() -> unit {
    let data: DataFrame = dataframe_from_xy(["a"], [1.0])
    let scene_minimal: PlotScene = build_scene(
        theme_minimal(
            geom_col(
                aes(plot(data), "x", "y")
            )
        )
    )
    let scene_void: PlotScene = build_scene(
        theme_void(
            geom_col(
                aes(plot(data), "x", "y")
            )
        )
    )
    if scene_void.marks.length() >= scene_minimal.marks.length() {
        panic("void theme should emit fewer marks")
    }
}
