namespace document.markdown;

using document::{Block, Document, FootnoteDefinition, Inline, Strong, Emphasis, Code, block_code, block_heading, block_list, block_paragraph, block_table, block_thematic_break, document_attribute, empty_document_metadata, footnote_definition, inline_break, inline_footnote_ref, inline_link, inline_styled, inline_text, list_item, new_document, table_cell, table_row};

# markdown 子集解析：行级块扫描 + 行内扫描，错误容许。
# 节点 id 自 1 起按创建序递增（同输入同 id 分配）。
#
# 数学片段的模型承载（开放扩展面，核心不解释）：
# - 行内 `$...$`：`Styled{Code}` + `classes: ["math"]` + `attributes: [tex=源]`
# - 段落级 `$$...$$`：同上并追加 `math-display` class；内容退化形态是源文本
#   的 code 样式（不认识扩展的消费方如实降级）。

structure MarkdownIdGen {
    next: u64
}

micro markdown_id_gen() -> MarkdownIdGen {
    return MarkdownIdGen {
        next: 1
    }
}

# 取当前 id 并递增；调用点先存 `gen.next` 再调用本函数。
micro markdown_bump_id(gen: MarkdownIdGen) -> MarkdownIdGen {
    return MarkdownIdGen {
        next: gen.next + 1
    }
}

micro markdown_is_blank_char(c: char) -> bool {
    return c == ' ' || c == '\t' || c == '\n' || c as u32 == 13
}

micro markdown_trim(text: utf8) -> utf8 {
    let mut start: usize = 1
    let mut stop: usize = text.length()
    while start <= stop && markdown_is_blank_char(text[start]) {
        start = start + 1
    }
    while stop >= start && markdown_is_blank_char(text[stop]) {
        stop = stop - 1
    }
    if stop < start {
        return ""
    }
    return text.slice(start - 1, stop - start + 1)
}

micro markdown_split_lines(text: utf8) -> [utf8] {
    let mut out: [utf8] = []
    let mut current: utf8 = ""
    let mut position: usize = 1
    let length: usize = text.length()
    while position <= length {
        let c: char = text[position]
        if c == '\n' {
            out = push(out, current)
            current = ""
        } else if c as u32 != 13 {
            current = current + std::text::encode_char_as_utf8(c)
        }
        position = position + 1
    }
    out = push(out, current)
    return out
}

# 从 `start`（1 基）起找定长字面量，返回命中起点；未命中 `None`。
micro markdown_find(text: utf8, needle: utf8, start: usize) -> Option<usize> {
    let length: usize = text.length()
    let needle_length: usize = needle.length()
    if needle_length == 0 {
        return None
    }
    let mut position: usize = start
    while position + needle_length - 1 <= length {
        let mut matched: bool = true
        let mut offset: usize = 0
        while offset < needle_length {
            if text[position + offset] != needle[offset + 1] {
                matched = false
            }
            offset = offset + 1
        }
        if matched {
            return Some(position)
        }
        position = position + 1
    }
    return None
}

# 行首连续 `#` 数（1..=6 且后跟空格才是标题；否则 0）。
micro markdown_heading_level(line: utf8) -> usize {
    let mut level: usize = 0
    let length: usize = line.length()
    while level < length && line[level + 1] == '#' {
        level = level + 1
    }
    if level >= 1 && level <= 6 && level + 1 <= length && line[level + 1] == ' ' {
        return level
    }
    return 0
}

# 表格分隔行单元：trim 后全 `-`/`:` 且至少一个 `-`。
micro markdown_is_separator_cell(text: utf8) -> bool {
    let trimmed: utf8 = markdown_trim(text)
    if trimmed.length() == 0 {
        return false
    }
    let mut has_dash: bool = false
    let mut position: usize = 1
    while position <= trimmed.length() {
        let c: char = trimmed[position]
        if c == '-' {
            has_dash = true
        } else if c != ':' {
            return false
        }
        position = position + 1
    }
    return has_dash
}

# pipe 行切单元：去首尾空段，逐单元 trim。
micro markdown_split_table_row(line: utf8) -> [utf8] {
    let parts: [utf8] = line.split("|")
    let mut out: [utf8] = []
    let mut index: usize = 0
    while index < parts.length() {
        let cell: utf8 = markdown_trim(parts⁅index⁆)
        let is_edge: bool = index == 0 || index == parts.length() - 1
        if !(is_edge && cell.length() == 0) {
            out = push(out, cell)
        }
        index = index + 1
    }
    return out
}

micro markdown_is_table_separator(cells: [utf8]) -> bool {
    if cells.length() == 0 {
        return false
    }
    let mut index: usize = 0
    while index < cells.length() {
        if !markdown_is_separator_cell(cells⁅index⁆) {
            return false
        }
        index = index + 1
    }
    return true
}

# 块起始判定（段落收集的终止条件）。
micro markdown_is_block_starter(line: utf8) -> bool {
    let trimmed: utf8 = markdown_trim(line)
    if trimmed.length() == 0 {
        return true
    }
    if trimmed.slice(0, if trimmed.length() >= 3 { 3 } else { trimmed.length() }).equals("```") {
        return true
    }
    if markdown_heading_level(line) > 0 {
        return true
    }
    if trimmed.equals("---") {
        return true
    }
    if trimmed.slice(0, 2).equals("- ") {
        return true
    }
    if trimmed.slice(0, 1).equals("|") {
        return true
    }
    if trimmed.slice(0, 2).equals("[^") {
        return true
    }
    return false
}
