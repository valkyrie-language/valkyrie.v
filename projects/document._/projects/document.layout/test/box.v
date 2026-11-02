namespace document.layout;

[test]
micro atom_measures_by_codepoint_count() -> unit {
    let font: BoxFont = box_char_cell_font(10.0)
    let atom: BoxNode = box_atom("abc", font)
    let metrics: BoxMetrics = box_metrics(atom)
    if metrics.width != 30.0 {
        panic("atom width is codepoint count times em")
    }
    if metrics.height != 8.0 || metrics.depth != 2.0 {
        panic("atom height and depth follow the font")
    }
}

[test]
micro hbox_sums_width_and_shares_baseline() -> unit {
    let font: BoxFont = box_char_cell_font(10.0)
    let node: BoxNode = box_hbox([box_atom("ab", font), box_glue(5.0), box_atom("c", font)])
    let metrics: BoxMetrics = box_metrics(node)
    if metrics.width != 35.0 {
        panic("hbox width sums children and glue")
    }
    if metrics.height != 8.0 || metrics.depth != 2.0 {
        panic("hbox height and depth take child maxima")
    }
}

[test]
micro vbox_stacks_and_keeps_last_baseline() -> unit {
    let font: BoxFont = box_char_cell_font(10.0)
    let first: BoxNode = box_atom("ab", font)
    let second: BoxNode = box_atom("c", font)
    let node: BoxNode = box_vbox([first, second])
    let metrics: BoxMetrics = box_metrics(node)
    if metrics.width != 20.0 {
        panic("vbox width takes child maximum")
    }
    if metrics.height != 18.0 || metrics.depth != 2.0 {
        panic("vbox height stacks and keeps the last child baseline")
    }
}

[test]
micro shift_moves_baseline() -> unit {
    let font: BoxFont = box_char_cell_font(10.0)
    let raised: BoxNode = box_shift(box_atom("x", font), 3.0)
    let metrics: BoxMetrics = box_metrics(raised)
    if metrics.height != 11.0 || metrics.depth != -1.0 {
        panic("shift raises height and lowers depth")
    }
    if metrics.width != 10.0 {
        panic("shift keeps width")
    }
}

[test]
micro break_folds_at_glue_only() -> unit {
    let font: BoxFont = box_char_cell_font(10.0)
    let material: [BoxNode] = [
        box_atom("ab", font),
        box_glue(5.0),
        box_atom("cd", font),
        box_glue(5.0),
        box_atom("ef", font)
    ]
    let lines: [[BoxNode]] = box_hbox_break(material, 45.0)
    if lines.length() != 2 {
        panic("material folds at glue into two lines")
    }
    if lines⁅0⁆.length() != 3 || lines⁅1⁆.length() != 1 {
        panic("break consumes the glue at the break point")
    }

    let tight: [[BoxNode]] = box_hbox_break([box_atom("abcdef", font)], 20.0)
    if tight.length() != 1 || tight⁅0⁆.length() != 1 {
        panic("material without glue stays one overfull line")
    }
}

[test]
micro place_flattens_hbox_positions() -> unit {
    let font: BoxFont = box_char_cell_font(10.0)
    let node: BoxNode = box_hbox([box_atom("ab", font), box_glue(5.0), box_atom("c", font)])
    let placed: [PlacedBox] = box_place(node, 10.0, 50.0)
    if placed.length() != 2 {
        panic("glue places nothing")
    }
    if placed⁅0⁆.x != 10.0 || placed⁅1⁆.x != 35.0 {
        panic("children advance by measured width")
    }
    if placed⁅0⁆.baseline != 50.0 || placed⁅1⁆.baseline != 50.0 {
        panic("hbox children share the baseline")
    }
}

[test]
micro place_stacks_vbox_and_applies_shift() -> unit {
    let font: BoxFont = box_char_cell_font(10.0)
    let stacked: BoxNode = box_vbox([box_atom("a", font), box_atom("b", font)])
    let placed: [PlacedBox] = box_place(stacked, 0.0, 20.0)
    if placed.length() != 2 {
        panic("vbox places both children")
    }
    if placed⁅0⁆.baseline != 10.0 || placed⁅1⁆.baseline != 20.0 {
        panic("vbox children stack downward to the last baseline")
    }

    let shifted: [PlacedBox] = box_place(box_shift(box_atom("x", font), 3.0), 0.0, 20.0)
    if shifted⁅0⁆.baseline != 17.0 {
        panic("shift raises the placed baseline")
    }
}
