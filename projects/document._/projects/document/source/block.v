namespace document;

# Block 顶层语义：块级节点骨架与种类和。文档是扁平块序列，章节不由嵌套
# 结构表达，由 Heading 层级 + 编号 pass 派生。
#
# `id` 文档内唯一（与 Inline 同一命名空间）；`classes`/`attributes` 是开放扩展面。

structure ListItem {
    blocks: [Block]
}

structure TableCell {
    content: [Block]
    colspan: usize
    rowspan: usize
}

structure TableRow {
    cells: [TableCell]
    is_header: bool
}

unite BlockKind {
    [constructor]
    Heading {
        level: usize
        content: [Inline]
    }
    [constructor]
    Paragraph {
        content: [Inline]
    }
    [constructor]
    ListBlock {
        ordered: bool
        start: usize
        items: [ListItem]
    }
    [constructor]
    Table {
        caption: Option<utf8>
        header: [TableRow]
        rows: [TableRow]
    }
    [constructor]
    CodeBlock {
        language: Option<utf8>
        text: utf8
    }
    [constructor]
    QuoteBlock {
        content: [Block]
    }
    [constructor]
    ThematicBreak
    [constructor]
    ImageBlock {
        source: utf8
        alt: [Inline]
        title: Option<utf8>
    }
}

structure Block {
    id: u64
    classes: [utf8]
    attributes: [DocumentAttribute]
    kind: BlockKind
}

micro list_item(blocks: [Block]) -> ListItem {
    return ListItem {
        blocks: blocks
    }
}

micro table_cell(content: [Block], colspan: usize, rowspan: usize) -> TableCell {
    return TableCell {
        content: content,
        colspan: colspan,
        rowspan: rowspan
    }
}

micro table_row(cells: [TableCell], is_header: bool) -> TableRow {
    return TableRow {
        cells: cells,
        is_header: is_header
    }
}

micro block_heading(id: u64, level: usize, content: [Inline]) -> Block {
    return Block {
        id: id,
        classes: [],
        attributes: [],
        kind: Heading {
            level: level,
            content: content
        }
    }
}

micro block_paragraph(id: u64, content: [Inline]) -> Block {
    return Block {
        id: id,
        classes: [],
        attributes: [],
        kind: Paragraph {
            content: content
        }
    }
}

micro block_list(id: u64, ordered: bool, start: usize, items: [ListItem]) -> Block {
    return Block {
        id: id,
        classes: [],
        attributes: [],
        kind: ListBlock {
            ordered: ordered,
            start: start,
            items: items
        }
    }
}

micro block_table(id: u64, caption: Option<utf8>, header: [TableRow], rows: [TableRow]) -> Block {
    return Block {
        id: id,
        classes: [],
        attributes: [],
        kind: Table {
            caption: caption,
            header: header,
            rows: rows
        }
    }
}

micro block_code(id: u64, language: Option<utf8>, text: utf8) -> Block {
    return Block {
        id: id,
        classes: [],
        attributes: [],
        kind: CodeBlock {
            language: language,
            text: text
        }
    }
}

micro block_quote(id: u64, content: [Block]) -> Block {
    return Block {
        id: id,
        classes: [],
        attributes: [],
        kind: QuoteBlock {
            content: content
        }
    }
}

micro block_thematic_break(id: u64) -> Block {
    return Block {
        id: id,
        classes: [],
        attributes: [],
        kind: ThematicBreak
    }
}

micro block_image(id: u64, source: utf8, alt: [Inline], title: Option<utf8>) -> Block {
    return Block {
        id: id,
        classes: [],
        attributes: [],
        kind: ImageBlock {
            source: source,
            alt: alt,
            title: title
        }
    }
}

# 节点附加扩展信息：返回替换 `classes` 后的副本（不可变外壳）。
micro block_with_classes(block: Block, classes: [utf8]) -> Block {
    return Block {
        id: block.id,
        classes: classes,
        attributes: block.attributes,
        kind: block.kind
    }
}

micro block_with_attributes(block: Block, attributes: [DocumentAttribute]) -> Block {
    return Block {
        id: block.id,
        classes: block.classes,
        attributes: attributes,
        kind: block.kind
    }
}

micro inline_with_attributes(item: Inline, attributes: [DocumentAttribute]) -> Inline {
    return Inline {
        id: item.id,
        classes: item.classes,
        attributes: attributes,
        kind: item.kind
    }
}
