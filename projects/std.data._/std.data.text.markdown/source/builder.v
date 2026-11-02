namespace std.data.text.markdown;

using std.data::{DataCstNode, DataOutcome, DataSettings, DataSource, data_outcome_partial};
using std.diagnostic::{Span};
using document::{Block, Document, FootnoteDefinition, Inline, ListItem, TableCell, TableRow, Strong, Emphasis, Code, block_code, block_heading, block_list, block_paragraph, block_table, block_thematic_break, document_attribute, empty_document_metadata, footnote_definition, inline_break, inline_footnote_ref, inline_link, inline_styled, inline_text, list_item, new_document, table_cell, table_row};

# 语义段：块级 CST -> `document::Document`。行内扫描（样式/链接/脚注引用/
# 数学片段）在本段完成（块级 token 流不覆盖行内配对语义；该面待词法段
# 扩展后收编）。词素按 span 从源切回。
#
# 数学片段的模型承载（核心合同的开放扩展面）：
# - 行内 `$...$`：`Styled{Code}` + `classes: ["math"]` + `attributes: [tex=源]`
# - 段落级 `$$...$$`：同上并追加 `math-display` class。
# 节点 id 自 1 起按创建序递增（同输入同 id 分配）。

structure MarkdownIdGen {
    next: u64
}

micro markdown_bump_id(gen: MarkdownIdGen) -> MarkdownIdGen {
    return MarkdownIdGen {
        next: gen.next + 1
    }
}

structure MarkdownBuildState {
    text: utf8
    gen: MarkdownIdGen
}

micro markdown_take_id(state: MarkdownBuildState) -> u64 {
    return state.gen.next
}

micro markdown_bump(state: MarkdownBuildState) -> MarkdownBuildState {
    return MarkdownBuildState {
        text: state.text,
        gen: markdown_bump_id(state.gen)
    }
}

micro markdown_lexeme(state: MarkdownBuildState, start: usize, stop: usize) -> utf8 {
    return state.text.slice(start, stop - start)
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
