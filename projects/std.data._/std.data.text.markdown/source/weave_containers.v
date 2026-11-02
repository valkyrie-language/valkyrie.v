namespace std.data.text.markdown;

using std.diagnostic::{Diagnostic};
using document::{Block, DocumentIndex, ListItem, TableCell, TableRow};
using document.render::{render_number};
using document.vector::{svg_escape_text};

# 容器块的镜像发射（仅包装结构，行内走 `weave_emit_inlines` 通道）。

micro weave_emit_list_block(block: Block, ordered: bool, start: usize, items: [ListItem], index: DocumentIndex, diagnostics: [Diagnostic]) -> WeaveOut {
    let mut tag: utf8 = "ul"
    let mut open: utf8 = "<ul"
    if ordered {
        tag = "ol"
        open = "<ol"
    }
    if ordered && start != 1 {
        open = open + " start='" + render_number(start) + "'"
    }
    let mut out: utf8 = open + ">"
    let mut collected: [Diagnostic] = diagnostics
    let mut position: usize = 0
    while position < items.length() {
        let step: WeaveOut = weave_emit_blocks(items⁅position⁆.blocks, index, collected)
        collected = step.diagnostics
        out = out + "<li>" + step.text + "</li>"
        position = position + 1
    }
    return weave_out(out + "</" + tag + ">", collected)
}

micro weave_emit_table(block: Block, caption: Option<utf8>, header: [TableRow], rows: [TableRow], index: DocumentIndex, diagnostics: [Diagnostic]) -> WeaveOut {
    let mut out: utf8 = "<table>"
    if caption.is_some() {
        out = out + "<caption>" + svg_escape_text(caption.unwrap()) + "</caption>"
    }
    let mut collected: [Diagnostic] = diagnostics
    if header.length() > 0 {
        let head_step: WeaveOut = weave_emit_table_rows(header, true, index, collected)
        collected = head_step.diagnostics
        out = out + "<thead>" + head_step.text + "</thead>"
    }
    let body_step: WeaveOut = weave_emit_table_rows(rows, false, index, collected)
    collected = body_step.diagnostics
    out = out + "<tbody>" + body_step.text + "</tbody></table>"
    return weave_out(out, collected)
}

micro weave_emit_table_rows(rows: [TableRow], head: bool, index: DocumentIndex, diagnostics: [Diagnostic]) -> WeaveOut {
    let mut out: utf8 = ""
    let mut collected: [Diagnostic] = diagnostics
    let mut position: usize = 0
    while position < rows.length() {
        out = out + "<tr>"
        let row: TableRow = rows⁅position⁆
        let mut cell_index: usize = 0
        while cell_index < row.cells.length() {
            let cell: TableCell = row.cells⁅cell_index⁆
            let mut tag: utf8 = "td"
            if head || row.is_header {
                tag = "th"
            }
            let mut open: utf8 = "<" + tag
            if cell.colspan > 1 {
                open = open + " colspan='" + render_number(cell.colspan) + "'"
            }
            if cell.rowspan > 1 {
                open = open + " rowspan='" + render_number(cell.rowspan) + "'"
            }
            let step: WeaveOut = weave_emit_blocks(cell.content, index, collected)
            collected = step.diagnostics
            out = out + open + ">" + step.text + "</" + tag + ">"
            cell_index = cell_index + 1
        }
        out = out + "</tr>"
        position = position + 1
    }
    return weave_out(out, collected)
}
