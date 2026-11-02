namespace notedown;

# Block 顶层语义（非解析器语法节点）。
#
# BlockKind: 0=Section, 1=Paragraph, 2=List, 3=Quote, 4=Code, 5=Table, 6=RawHtml

structure ListItem {
    content: [Inline]
    children: [u64]
    number: i32
    is_task: bool
    is_checked: i32
}

structure TableCell {
    content: [Inline]
    colspan: i32
    rowspan: i32
}

structure TableRow {
    is_header: bool
    cells: [TableCell]
}

micro plain_item(content: [Inline]) -> ListItem {
    return ListItem {
        content: content,
        children: [],
        number: 0,
        is_task: false,
        is_checked: -1
    }
}

micro block_section(level: i32, title: [Inline]) -> Block {
    return Block {
        kind: 0,
        level: level,
        title: title,
        children: [],
        content: [],
        ordered: false,
        items: [],
        caption: None,
        rows: [],
        language: None,
        text: "",
        html: ""
    }
}

micro block_paragraph(content: [Inline]) -> Block {
    return Block {
        kind: 1,
        level: 0,
        title: [],
        children: [],
        content: content,
        ordered: false,
        items: [],
        caption: None,
        rows: [],
        language: None,
        text: "",
        html: ""
    }
}

micro block_list(ordered: bool, items: [ListItem]) -> Block {
    return Block {
        kind: 2,
        level: 0,
        title: [],
        children: [],
        content: [],
        ordered: ordered,
        items: items,
        caption: None,
        rows: [],
        language: None,
        text: "",
        html: ""
    }
}

micro block_quote(content: [Inline]) -> Block {
    return Block {
        kind: 3,
        level: 0,
        title: [],
        children: [],
        content: content,
        ordered: false,
        items: [],
        caption: None,
        rows: [],
        language: None,
        text: "",
        html: ""
    }
}

micro block_code(language: Option<utf8>, text: utf8) -> Block {
    return Block {
        kind: 4,
        level: 0,
        title: [],
        children: [],
        content: [],
        ordered: false,
        items: [],
        caption: None,
        rows: [],
        language: language,
        text: text,
        html: ""
    }
}

micro block_table(caption: Option<utf8>, rows: [TableRow]) -> Block {
    return Block {
        kind: 5,
        level: 0,
        title: [],
        children: [],
        content: [],
        ordered: false,
        items: [],
        caption: caption,
        rows: rows,
        language: None,
        text: "",
        html: ""
    }
}

micro block_raw_html(html: utf8) -> Block {
    return Block {
        kind: 6,
        level: 0,
        title: [],
        children: [],
        content: [],
        ordered: false,
        items: [],
        caption: None,
        rows: [],
        language: None,
        text: "",
        html: html
    }
}

micro block_with_items(block: Block, items: [ListItem]) -> Block {
    return Block {
        kind: block.kind,
        level: block.level,
        title: block.title,
        children: block.children,
        content: block.content,
        ordered: block.ordered,
        items: items,
        caption: block.caption,
        rows: block.rows,
        language: block.language,
        text: block.text,
        html: block.html
    }
}

# Section 的 children 是子 block 的 NodeId 列表；其余 block 忽略该字段。
structure Block {
    kind: i32
    level: i32
    title: [Inline]
    children: [u64]
    content: [Inline]
    ordered: bool
    items: [ListItem]
    caption: Option<utf8>
    rows: [TableRow]
    language: Option<utf8>
    text: utf8
    html: utf8
}

micro block_with_children(block: Block, children: [u64]) -> Block {
    return Block {
        kind: block.kind,
        level: block.level,
        title: block.title,
        children: children,
        content: block.content,
        ordered: block.ordered,
        items: block.items,
        caption: block.caption,
        rows: block.rows,
        language: block.language,
        text: block.text,
        html: block.html
    }
}
