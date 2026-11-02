namespace document.layout;

# 贪心断行：把一串水平材料折叠到给定宽度。
#
# 规则（v0）：
# - 断点只在 `BoxGlue` 处；断行消费掉断点处的 glue（不进任一行）。
# - 贪心：逐个加入材料，加入非 glue 材料将超宽时，回退到行内最后一个
#   glue 断点断行；行内没有 glue 则保留超宽行（如实，不硬断）。
# - 行尾暂存 glue 不计入行宽。

micro box_break_is_glue(node: BoxNode) -> bool {
    match node {
        case BoxGlue(payload):
            return true
        else:
            return false
    }
}

# 取 `line` 的前 `count` 项（不含断点 glue 自身）。
micro box_break_prefix(line: [BoxNode], count: usize) -> [BoxNode] {
    let mut out: [BoxNode] = []
    let mut index: usize = 0
    while index < count && index < line.length() {
        out = push(out, line⁅index⁆)
        index = index + 1
    }
    return out
}

micro box_hbox_break(material: [BoxNode], width: f64) -> [[BoxNode]] {
    let mut lines: [[BoxNode]] = []
    let mut line: [BoxNode] = []
    let mut line_width: f64 = 0.0
    # 行内最后一个 glue 的位置（行数组下标）；无 glue 时 glue_at < 0。
    let mut glue_at: i32 = -1

    let mut index: usize = 0
    while index < material.length() {
        let node: BoxNode = material⁅index⁆
        let node_width: f64 = box_metrics(node).width
        if box_break_is_glue(node) {
            glue_at = line.length() as i32
            line = push(line, node)
            index = index + 1
        } else {
            if line_width + node_width > width && glue_at >= 0 {
                let break_at: usize = glue_at as usize
                lines = push(lines, box_break_prefix(line, break_at))
                let mut rest: [BoxNode] = []
                let mut rest_index: usize = break_at + 1
                line_width = 0.0
                while rest_index < line.length() {
                    rest = push(rest, line⁅rest_index⁆)
                    line_width = line_width + box_metrics(line⁅rest_index⁆).width
                    rest_index = rest_index + 1
                }
                line = rest
                glue_at = -1
                glue_width = 0.0
            } else {
                line = push(line, node)
                line_width = line_width + node_width
                index = index + 1
            }
        }
    }
    lines = push(lines, line)
    return lines
}
