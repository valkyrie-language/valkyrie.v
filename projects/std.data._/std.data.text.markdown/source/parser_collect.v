namespace std.data.text.markdown;

using std.data::{DataCstNode, data_cst_node, data_cst_span};
using std.diagnostic::{Span, new_span};

# 块收集器：段落 / fence / 表格 / 列表的连续行归并。

structure MarkdownParagraphOut {
    node: DataCstNode<MarkdownTokenKind>
    next: usize
}

structure MarkdownFenceOut {
    node: DataCstNode<MarkdownTokenKind>
    next: usize
}

structure MarkdownTableOut {
    node: DataCstNode<MarkdownTokenKind>
    next: usize
}

structure MarkdownListOut {
    node: DataCstNode<MarkdownTokenKind>
    next: usize
}

micro markdown_line_is_block_start(line: MarkdownLine) -> bool {
    let first: Option<MarkdownToken> = markdown_first_significant(line)
    if first.is_none() {
        return true
    }
    let token: MarkdownToken = first.unwrap()
    match token.kind {
        case Hash:
            return true
        case Backtick:
            return token.span.stop - token.span.start >= 3
        case Pipe:
            return true
        case Minus:
            return true
        case BracketOpen:
            return true
        else:
            return false
    }
}

micro markdown_collect_paragraph(lines: [MarkdownLine], start: usize) -> MarkdownParagraphOut {
    let mut children: [DataCstNode<MarkdownTokenKind>] = []
    let mut index: usize = start
    let mut running: bool = true
    while index < lines.length() && running {
        if index > start && markdown_line_is_block_start(lines⁅index⁆) {
            running = false
        } else {
            let line: MarkdownLine = lines⁅index⁆
            let first: Option<MarkdownToken> = markdown_first_significant(line)
            if first.is_none() {
                running = false
            } else {
                children = push(children, data_cst_token(new_data_token(Text, line.start, line.stop)))
                index = index + 1
            }
        }
    }
    let start_span: usize = lines⁅start⁆.start
    let stop_span: usize = lines⁅index - 1⁆.stop
    return MarkdownParagraphOut {
        node: data_cst_node(NodeParagraph, new_span(start_span, stop_span), children),
        next: index
    }
}

micro markdown_collect_fence(lines: [MarkdownLine], start: usize) -> MarkdownFenceOut {
    let mut children: [DataCstNode<MarkdownTokenKind>] = []
    let open: MarkdownLine = lines⁅start⁆
    children = push(children, data_cst_token(new_data_token(Backtick, open.start, open.stop)))
    let mut index: usize = start + 1
    let mut closed: bool = false
    while index < lines.length() && !closed {
        let line: MarkdownLine = lines⁅index⁆
        let first: Option<MarkdownToken> = markdown_first_significant(line)
        let mut is_close: bool = false
        if first.is_some() {
            let token: MarkdownToken = first.unwrap()
            match token.kind {
                case Backtick:
                    if token.span.stop - token.span.start >= 3 {
                        is_close = true
                    }
                else:
                    is_close = false
            }
        }
        if is_close {
            children = push(children, data_cst_token(new_data_token(Backtick, line.start, line.stop)))
            closed = true
            index = index + 1
        } else {
            children = push(children, data_cst_token(new_data_token(Text, line.start, line.stop)))
            index = index + 1
        }
    }
    return MarkdownFenceOut {
        node: data_cst_node(NodeFence, new_span(open.start, lines⁅index - 1⁆.stop), children),
        next: index
    }
}

micro markdown_collect_table(lines: [MarkdownLine], start: usize) -> MarkdownTableOut {
    let mut children: [DataCstNode<MarkdownTokenKind>] = []
    let mut index: usize = start
    let mut running: bool = true
    while index < lines.length() && running {
        let line: MarkdownLine = lines⁅index⁆
        let first: Option<MarkdownToken> = markdown_first_significant(line)
        let mut is_row: bool = false
        if first.is_some() {
            match first.unwrap().kind {
                case Pipe:
                    is_row = true
                else:
                    is_row = false
            }
        }
        if !is_row {
            running = false
        } else {
            children = push(children, data_cst_node(NodeTableRow, new_span(line.start, line.stop), markdown_line_tokens(line)))
            index = index + 1
        }
    }
    return MarkdownTableOut {
        node: data_cst_node(NodeTable, new_span(lines⁅start⁆.start, lines⁅index - 1⁆.stop), children),
        next: index
    }
}

micro markdown_collect_list(lines: [MarkdownLine], start: usize) -> MarkdownListOut {
    let mut children: [DataCstNode<MarkdownTokenKind>] = []
    let mut index: usize = start
    let mut running: bool = true
    while index < lines.length() && running {
        if !markdown_is_list_item(lines⁅index⁆) {
            running = false
        } else {
            let line: MarkdownLine = lines⁅index⁆
            children = push(children, data_cst_node(NodeListItem, new_span(line.start, line.stop), markdown_line_tokens(line)))
            index = index + 1
        }
    }
    return MarkdownListOut {
        node: data_cst_node(NodeList, new_span(lines⁅start⁆.start, lines⁅index - 1⁆.stop), children),
        next: index
    }
}
