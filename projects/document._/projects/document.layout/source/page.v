namespace document.layout;

using document::{Inline};

# 页面层：页面规格与分页。本层知道"页面"存在；对已发射的文本行分页，
# 不理解块语义。测量 v0 是字符单元（1 码点 = 1 宽，等宽假设）。
#
# 断行：按可用宽度（`width − margin_left − margin_right`）硬折叠（文本行无
# glue 概念，v0 按码点定长切断）。
# 断页：可用高度 = `height − margin_top − margin_bottom` 行；
# keep-with-next（R13）由 `paginate_marked` 的 `marks` 驱动——标题行归属是
# 渲染侧知识，裸 `paginate` 不猜测；页尾连续标记行整体推入下页。
# 表格行不拆（R14）：每行是原子单位，结构即真。孤行/寡行规则 v0 不实现（R15）。
# `header`/`footer` 是渲染侧插桩面，`paginate` 不注入行内容。

structure PageSpec {
    width: usize
    height: usize
    margin_top: usize
    margin_right: usize
    margin_bottom: usize
    margin_left: usize
    header: Option<[Inline]>
    footer: Option<[Inline]>
}

structure PageBox {
    index: usize
    lines: [utf8]
}

micro page_spec(width: usize, height: usize, margin_top: usize, margin_right: usize, margin_bottom: usize, margin_left: usize) -> PageSpec {
    return PageSpec {
        width: width,
        height: height,
        margin_top: margin_top,
        margin_right: margin_right,
        margin_bottom: margin_bottom,
        margin_left: margin_left,
        header: None,
        footer: None
    }
}

micro page_usable_width(spec: PageSpec) -> usize {
    if spec.width <= spec.margin_left + spec.margin_right {
        return 1
    }
    return spec.width - spec.margin_left - spec.margin_right
}

micro page_usable_height(spec: PageSpec) -> usize {
    if spec.height <= spec.margin_top + spec.margin_bottom {
        return 1
    }
    return spec.height - spec.margin_top - spec.margin_bottom
}

# 定长硬折叠：把一行按 `width` 码点切成连续段；空行保持一行。
micro page_fold_line(line: utf8, width: usize) -> [utf8] {
    let length: usize = line.length()
    if length <= width {
        return [line]
    }
    let mut out: [utf8] = []
    let mut start: usize = 0
    while start < length {
        let mut take: usize = width
        if start + take > length {
            take = length - start
        }
        out = push(out, line.slice(start, take))
        start = start + take
    }
    return out
}

micro paginate(lines: [utf8], spec: PageSpec) -> [PageBox] {
    let mut marks: [bool] = []
    let mut index: usize = 0
    while index < lines.length() {
        marks = push(marks, false)
        index = index + 1
    }
    return paginate_marked(lines, marks, spec)
}

# 带 keep-with-next 标注的分页：`marks[i] = true` 表示该行须与下一行同页。
micro paginate_marked(lines: [utf8], marks: [bool], spec: PageSpec) -> [PageBox] {
    let usable_width: usize = page_usable_width(spec)
    let usable_height: usize = page_usable_height(spec)

    let mut folded: [utf8] = []
    let mut folded_marks: [bool] = []
    let mut index: usize = 0
    while index < lines.length() {
        let segments: [utf8] = page_fold_line(lines⁅index⁆, usable_width)
        let mut segment_index: usize = 0
        while segment_index < segments.length() {
            folded = push(folded, segments⁅segment_index⁆)
            let mut mark: bool = false
            if segment_index == 0 && index < marks.length() {
                mark = marks⁅index⁆
            }
            folded_marks = push(folded_marks, mark)
            segment_index = segment_index + 1
        }
        index = index + 1
    }

    let mut pages: [PageBox] = []
    let mut page_lines: [utf8] = []
    let mut page_marks: [bool] = []
    let mut cursor: usize = 0
    while cursor < folded.length() {
        if page_lines.length() >= usable_height {
            # R13：页尾连续标记行整体推入下页；整页皆标记时无法让位，如实断页。
            let mut carried: [utf8] = []
            let mut carried_marks: [bool] = []
            let mut tail: usize = page_lines.length()
            while tail > 0 && page_marks⁅tail - 1⁆ {
                tail = tail - 1
            }
            if tail == 0 {
                tail = page_lines.length()
            }
            let mut keep: usize = tail
            let mut trimmed: [utf8] = []
            let mut trimmed_marks: [bool] = []
            while keep < page_lines.length() {
                carried = push(carried, page_lines⁅keep⁆)
                carried_marks = push(carried_marks, page_marks⁅keep⁆)
                keep = keep + 1
            }
            let mut hold: usize = 0
            while hold < tail {
                trimmed = push(trimmed, page_lines⁅hold⁆)
                trimmed_marks = push(trimmed_marks, page_marks⁅hold⁆)
                hold = hold + 1
            }
            page_lines = trimmed
            page_marks = trimmed_marks
            pages = push(pages, PageBox {
                index: pages.length(),
                lines: page_lines
            })
            page_lines = carried
            page_marks = carried_marks
        }
        page_lines = push(page_lines, folded⁅cursor⁆)
        page_marks = push(page_marks, folded_marks⁅cursor⁆)
        cursor = cursor + 1
    }
    if page_lines.length() > 0 || pages.length() == 0 {
        pages = push(pages, PageBox {
            index: pages.length(),
            lines: page_lines
        })
    }
    return pages
}
