namespace document.layout;

[test]
micro fold_line_wraps_at_usable_width() -> unit {
    let segments: [utf8] = page_fold_line("abcdefg", 3)
    if segments.length() != 3 {
        panic("line folds into width sized segments")
    }
    if !segments⁅0⁆.equals("abc") || !segments⁅1⁆.equals("def") || !segments⁅2⁆.equals("g") {
        panic("segments keep original order and content")
    }
    let short: [utf8] = page_fold_line("ab", 3)
    if short.length() != 1 || !short⁅0⁆.equals("ab") {
        panic("short line stays one segment")
    }
}

[test]
micro paginate_folds_and_splits_pages() -> unit {
    let spec: PageSpec = page_spec(6, 4, 1, 1, 1, 1)
    let pages: [PageBox] = paginate(["abcd", "abcdefgh", "xy"], spec)
    # 可用宽 4 高 2：abcd | abcdefgh 折成 abcd+efgh | xy → 3 行 → 2 页
    if pages.length() != 2 {
        panic("folded lines split across two pages")
    }
    if pages⁅0⁆.index != 0 || pages⁅1⁆.index != 1 {
        panic("page index follows emission order")
    }
    if pages⁅0⁆.lines.length() != 2 || pages⁅1⁆.lines.length() != 1 {
        panic("pages hold up to usable height")
    }
    if !pages⁅1⁆.lines⁅0⁆.equals("xy") {
        panic("last page keeps remaining line")
    }
}

[test]
micro paginate_keep_with_next_carries_heading() -> unit {
    let spec: PageSpec = page_spec(10, 4, 1, 0, 1, 0)
    let pages: [PageBox] = paginate_marked(["one", "two", "head", "body"], [false, false, true, false], spec)
    # 可用高 3：one two head 满页，head 带 keep-with-next → 推入下页
    if pages.length() != 2 {
        panic("keep with next splits into two pages")
    }
    if pages⁅0⁆.lines.length() != 2 {
        panic("marked heading leaves the page tail")
    }
    if !pages⁅1⁆.lines⁅0⁆.equals("head") {
        panic("heading starts the next page")
    }
    if !pages⁅1⁆.lines⁅1⁆.equals("body") {
        panic("heading stays with its body")
    }
}

[test]
micro paginate_empty_input_yields_one_empty_page() -> unit {
    let spec: PageSpec = page_spec(10, 4, 1, 1, 1, 1)
    let pages: [PageBox] = paginate([], spec)
    if pages.length() != 1 || pages⁅0⁆.lines.length() != 0 {
        panic("empty input yields a single empty page")
    }
}
