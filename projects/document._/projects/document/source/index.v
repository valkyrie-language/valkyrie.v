namespace document;

# 引用系统求解：编号 pass 产物与 TOC。
#
# 规则：
# - R1 只对顶层 `blocks` 的 `Heading` 编号；`QuoteBlock`/`TableCell`/`ListItem`
#   内部的 heading 不编号、不进 TOC。
# - R2 计数器 `counter[1..=6]`：遇到 level = L 的 heading 时 `counter[L] += 1`，
#   并把 `counter[L+1..=6]` 清零。
# - R3 `SectionNumber.parts = counter[1..=L]`（定长 L 段）；跳级不补段，
#   h1 后接 h3 得 `1.0.1`（如实记录，校验不判错）。
# - R4 `anchor` 为点分编号字符串（如 `1.2.3`），编号唯一 ⇒ anchor 唯一。
# - R5/R6 脚注与参考文献按声明序编号 1..n。
# - R8 `document_toc` 只消费 `DocumentIndex.sections`，不重扫树。

structure SectionNumber {
    parts: [usize]
}

structure SectionRef {
    node_id: u64
    number: SectionNumber
    anchor: utf8
    title: [Inline]
}

structure FootnoteNumber {
    key: utf8
    number: usize
}

structure CitationNumber {
    key: utf8
    number: usize
}

structure DocumentIndex {
    sections: [SectionRef]
    footnotes: [FootnoteNumber]
    citations: [CitationNumber]
}

structure TocEntry {
    level: usize
    number: SectionNumber
    title: [Inline]
    anchor: utf8
}

# 点分编号字符串：`1.0.1` 形态，逐段拼接。
micro section_number_anchor(number: SectionNumber) -> utf8 {
    let mut out: utf8 = ""
    let mut index: usize = 0
    while index < number.parts.length() {
        if index > 0 {
            out = out + "."
        }
        out = out + format("{}", number.parts⁅index⁆)
        index = index + 1
    }
    return out
}

micro document_index(document: Document) -> DocumentIndex {
    let mut counters: [usize] = [0, 0, 0, 0, 0, 0]
    let mut sections: [SectionRef] = []

    let mut block_index: usize = 0
    while block_index < document.blocks.length() {
        let block: Block = document.blocks⁅block_index⁆
        let mut heading_level: usize = 0
        let mut heading_content: [Inline] = []
        match block.kind {
            case Heading(payload):
                heading_level = payload.level
                heading_content = payload.content
            else:
                heading_level = 0
        }
        if heading_level >= 1 && heading_level <= 6 {
            counters⁅heading_level - 1⁆ = counters⁅heading_level - 1⁆ + 1
            let mut reset: usize = heading_level
            while reset < 6 {
                counters⁅reset⁆ = 0
                reset = reset + 1
            }
            let mut parts: [usize] = []
            let mut slot: usize = 0
            while slot < heading_level {
                parts = push(parts, counters⁅slot⁆)
                slot = slot + 1
            }
            let number: SectionNumber = SectionNumber {
                parts: parts
            }
            let anchor: utf8 = section_number_anchor(number)
            sections = push(sections, SectionRef {
                node_id: block.id,
                number: number,
                anchor: anchor,
                title: heading_content
            })
        }
        block_index = block_index + 1
    }

    let mut footnotes: [FootnoteNumber] = []
    let mut footnote_index: usize = 0
    while footnote_index < document.footnotes.length() {
        footnotes = push(footnotes, FootnoteNumber {
            key: document.footnotes⁅footnote_index⁆.key,
            number: footnote_index + 1
        })
        footnote_index = footnote_index + 1
    }

    let mut citations: [CitationNumber] = []
    let mut citation_index: usize = 0
    while citation_index < document.bibliography.length() {
        citations = push(citations, CitationNumber {
            key: document.bibliography⁅citation_index⁆.key,
            number: citation_index + 1
        })
        citation_index = citation_index + 1
    }

    return DocumentIndex {
        sections: sections,
        footnotes: footnotes,
        citations: citations
    }
}

micro document_toc(index: DocumentIndex) -> [TocEntry] {
    let mut entries: [TocEntry] = []
    let mut position: usize = 0
    while position < index.sections.length() {
        let section: SectionRef = index.sections⁅position⁆
        entries = push(entries, TocEntry {
            level: section.number.parts.length(),
            number: section.number,
            title: section.title,
            anchor: section.anchor
        })
        position = position + 1
    }
    return entries
}

# 脚注编号查表：渲染侧把 `FootnoteRef.key` 替换为编号；未定义返回 `None`
# （预检已通过时不发生；未过预检直接渲染属调用方责任）。
micro document_index_footnote_number(index: DocumentIndex, key: utf8) -> Option<usize> {
    let mut position: usize = 0
    while position < index.footnotes.length() {
        if index.footnotes⁅position⁆.key.equals(key) {
            return Some(index.footnotes⁅position⁆.number)
        }
        position = position + 1
    }
    return None
}

micro document_index_citation_number(index: DocumentIndex, key: utf8) -> Option<usize> {
    let mut position: usize = 0
    while position < index.citations.length() {
        if index.citations⁅position⁆.key.equals(key) {
            return Some(index.citations⁅position⁆.number)
        }
        position = position + 1
    }
    return None
}
