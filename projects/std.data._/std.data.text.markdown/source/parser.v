namespace std.data.text.markdown;

using std.data::{DataCstNode, DataOutcome, DataSettings, data_cst_node, data_cst_span, data_cst_token, data_outcome_partial, new_data_token};
using std.diagnostic::{Span, new_span};

# 语法段：词法 token 流 -> 块级无损 CST（`DataCstNode<MarkdownTokenKind>`）。
# 行在 `Newline` 处切分；行分类看首个非空白 token：
# - `Hash` run 1..=6 + `Whitespace` → `NodeHeading`
# - `Backtick` run ≥3 → `NodeFence`（开闭成对；未闭合收编到源末，trivia 不丢）
# - 首 token `Pipe` → 表格行（连续行聚成 `NodeTable`；分隔行判定在建模段）
# - `Minus`(单个) + `Whitespace` → `NodeListItem`（连续聚成 `NodeList`）
# - 全行 `Minus`(≥3) + 空白 → `NodeThematicBreak`
# - 全空（无 token）→ 丢弃（段落分隔事实由块序列表达）
# - 其余 → `NodeParagraph`（连续非空行聚成一个段落节点）
#
# `NodeFence` 子节点 = 开行 token、内容行 token（含 `Newline`）、闭行 token（若闭合）。

structure MarkdownLine {
    tokens: [MarkdownToken]
    start: usize
    stop: usize
}

micro markdown_line_tokens(line: MarkdownLine) -> [DataToken<MarkdownTokenKind>] {
    let mut out: [DataToken<MarkdownTokenKind>] = []
    let mut index: usize = 0
    while index < line.tokens.length() {
        let token: MarkdownToken = line.tokens⁅index⁆
        out = push(out, new_data_token(token.kind, token.span.start, token.span.stop))
        index = index + 1
    }
    return out
}

micro markdown_fold_lines(tokens: [MarkdownToken]) -> [MarkdownLine] {
    let mut lines: [MarkdownLine] = []
    let mut current: [MarkdownToken] = []
    let mut index: usize = 0
    while index <= tokens.length() {
        let mut at_break: bool = index == tokens.length()
        if !at_break {
            match tokens⁅index⁆.kind {
                case Newline:
                    at_break = true
                else:
                    at_break = false
            }
        }
        if at_break {
            if current.length() > 0 {
                lines = push(lines, MarkdownLine {
                    tokens: current,
                    start: current⁅0⁆.span.start,
                    stop: current⁅current.length() - 1⁆.span.stop
                })
            }
            current = []
        } else {
            current = push(current, tokens⁅index⁆)
        }
        index = index + 1
    }
    return lines
}

micro markdown_first_significant(line: MarkdownLine) -> Option<MarkdownToken> {
    let mut index: usize = 0
    while index < line.tokens.length() {
        match line.tokens⁅index⁆.kind {
            case Whitespace:
                index = index + 1
            else:
                return Some(line.tokens⁅index⁆)
        }
    }
    return None
}

micro markdown_count_leading(line: MarkdownLine, kind: MarkdownTokenKind) -> usize {
    let first: Option<MarkdownToken> = markdown_first_significant(line)
    if first.is_none() {
        return 0
    }
    let token: MarkdownToken = first.unwrap()
    let mut same: bool = false
    match token.kind {
        case Hash:
            same = kind_is_hash(kind)
        case Backtick:
            same = kind_is_backtick(kind)
        case Minus:
            same = kind_is_minus(kind)
        else:
            same = false
    }
    if !same {
        return 0
    }
    return token.span.stop - token.span.start
}

micro kind_is_hash(kind: MarkdownTokenKind) -> bool {
    match kind {
        case Hash:
            return true
        else:
            return false
    }
}

micro kind_is_backtick(kind: MarkdownTokenKind) -> bool {
    match kind {
        case Backtick:
            return true
        else:
            return false
    }
}

micro kind_is_minus(kind: MarkdownTokenKind) -> bool {
    match kind {
        case Minus:
            return true
        else:
            return false
    }
}

micro markdown_is_thematic(line: MarkdownLine) -> bool {
    let mut minus_count: usize = 0
    let mut index: usize = 0
    while index < line.tokens.length() {
        match line.tokens⁅index⁆.kind {
            case Minus:
                minus_count = minus_count + 1
            case Whitespace:
                minus_count = minus_count
            else:
                return false
        }
        index = index + 1
    }
    return minus_count >= 3
}

# `Minus`(单个) + `Whitespace` + 非空白内容。
micro markdown_is_list_item(line: MarkdownLine) -> bool {
    let first: Option<MarkdownToken> = markdown_first_significant(line)
    if first.is_none() {
        return false
    }
    let token: MarkdownToken = first.unwrap()
    if token.span.stop - token.span.start != 1 {
        return false
    }
    match token.kind {
        case Minus:
            return true
        else:
            return false
    }
}

micro markdown_parse(tokens: [MarkdownToken], settings: DataSettings) -> DataOutcome<DataCstNode<MarkdownTokenKind>> {
    let lines: [MarkdownLine] = markdown_fold_lines(tokens)
    let mut children: [DataCstNode<MarkdownTokenKind>] = []
    let mut index: usize = 0
    while index < lines.length() {
        let line: MarkdownLine = lines⁅index⁆
        let first: Option<MarkdownToken> = markdown_first_significant(line)
        if first.is_none() {
            index = index + 1
        } else {
            let token: MarkdownToken = first.unwrap()
            match token.kind {
                case Hash:
                    let level: usize = token.span.stop - token.span.start
                    if level >= 1 && level <= 6 && line.tokens.length() > 1 {
                        children = push(children, data_cst_node(NodeHeading, new_span(line.start, line.stop), markdown_line_tokens(line)))
                        index = index + 1
                    } else {
                        let paragraph: MarkdownParagraphOut = markdown_collect_paragraph(lines, index)
                        children = push(children, paragraph.node)
                        index = paragraph.next
                    }
                case Backtick:
                    if token.span.stop - token.span.start >= 3 {
                        let fence: MarkdownFenceOut = markdown_collect_fence(lines, index)
                        children = push(children, fence.node)
                        index = fence.next
                    } else {
                        let paragraph: MarkdownParagraphOut = markdown_collect_paragraph(lines, index)
                        children = push(children, paragraph.node)
                        index = paragraph.next
                    }
                case Pipe:
                    let table: MarkdownTableOut = markdown_collect_table(lines, index)
                    children = push(children, table.node)
                    index = table.next
                case Minus:
                    if markdown_is_thematic(line) {
                        children = push(children, data_cst_node(NodeThematicBreak, new_span(line.start, line.stop), markdown_line_tokens(line)))
                        index = index + 1
                    } else if markdown_is_list_item(line) {
                        let list: MarkdownListOut = markdown_collect_list(lines, index)
                        children = push(children, list.node)
                        index = list.next
                    } else {
                        let paragraph: MarkdownParagraphOut = markdown_collect_paragraph(lines, index)
                        children = push(children, paragraph.node)
                        index = paragraph.next
                    }
                case BracketOpen:
                    let paragraph: MarkdownParagraphOut = markdown_collect_paragraph(lines, index)
                    children = push(children, paragraph.node)
                    index = paragraph.next
                else:
                    let paragraph: MarkdownParagraphOut = markdown_collect_paragraph(lines, index)
                    children = push(children, paragraph.node)
                    index = paragraph.next
            }
        }
    }

    let mut span: Span = new_span(0, 0)
    if children.length() > 0 {
        span = new_span(data_cst_span(children⁅0⁆).start, data_cst_span(children⁅children.length() - 1⁆).end)
    }
    return data_outcome_partial(data_cst_node(NodeDocument, span, children), [])
}
