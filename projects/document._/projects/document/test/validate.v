namespace document;

# 合法样本：覆盖全种类 block/inline，脚注与参考文献均有定义。
micro sample_valid_document() -> Document {
    let heading: Block = block_heading(1, 1, [inline_text(2, "Title")])
    let intro: Block = block_paragraph(3, [
        inline_text(4, "plain"),
        inline_styled(5, Strong, [inline_text(6, "bold")]),
        inline_link(7, "https://example.test", None, [inline_text(8, "site")]),
        inline_footnote_ref(9, "fn1"),
        inline_citation_ref(10, ["bib1"])
    ])
    let list: Block = block_list(11, true, 1, [
        list_item([block_paragraph(12, [inline_text(13, "first")])]),
        list_item([block_paragraph(14, [inline_text(15, "second")])])
    ])
    let table: Block = block_table(16, Some("caption"), [
        table_row([table_cell([block_paragraph(17, [inline_text(18, "head")])], 1, 1)], true)
    ], [
        table_row([table_cell([block_paragraph(19, [inline_text(20, "body")])], 2, 1)], false)
    ])
    let code: Block = block_code(21, Some("v"), "let x = 1")
    let quote: Block = block_quote(22, [block_paragraph(23, [inline_text(24, "quoted")])])
    let rule: Block = block_thematic_break(25)
    let image: Block = block_image(26, "picture.png", [inline_text(27, "alt")], None)

    let footnotes: [FootnoteDefinition] = [
        footnote_definition("fn1", [block_paragraph(28, [inline_text(29, "note")])])
    ]
    let bibliography: [BibliographyEntry] = [
        bibliography_entry("bib1", [document_attribute("title", "Reference")])
    ]
    return new_document(empty_document_metadata(), [heading, intro, list, table, code, quote, rule, image], footnotes, bibliography)
}

[test]
micro validate_accepts_valid_document() -> unit {
    let errors: [DocumentError] = document_validate(sample_valid_document())
    if errors.length() != 0 {
        panic("valid document should pass validation")
    }
}

[test]
micro validate_flags_heading_level() -> unit {
    let low: Block = block_heading(1, 0, [inline_text(2, "x")])
    let high: Block = block_heading(3, 7, [inline_text(4, "y")])
    let document: Document = new_document(empty_document_metadata(), [low, high], [], [])
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 2 {
        panic("expected two heading level errors")
    }
    if !errors⁅0⁆.code.equals("document.error.heading_level") {
        panic("error code should be heading_level")
    }
    if errors⁅1⁆.node_id != 3 {
        panic("second error should point at the second heading")
    }
}

[test]
micro validate_flags_list_start() -> unit {
    let list: Block = block_list(1, true, 0, [list_item([block_paragraph(2, [inline_text(3, "x")])])])
    let document: Document = new_document(empty_document_metadata(), [list], [], [])
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 1 {
        panic("expected one list start error")
    }
    if !errors⁅0⁆.code.equals("document.error.list_start") {
        panic("error code should be list_start")
    }
}

[test]
micro validate_flags_cell_span() -> unit {
    let bad: TableCell = table_cell([block_paragraph(2, [inline_text(3, "x")])], 0, 0)
    let table: Block = block_table(1, None, [], [table_row([bad], false)])
    let document: Document = new_document(empty_document_metadata(), [table], [], [])
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 1 {
        panic("expected one cell span error")
    }
    if !errors⁅0⁆.code.equals("document.error.cell_span") {
        panic("error code should be cell_span")
    }
    if errors⁅0⁆.node_id != 1 {
        panic("cell span error should point at the table block")
    }
}

[test]
micro validate_flags_duplicate_id_across_block_and_inline() -> unit {
    let block: Block = block_paragraph(7, [inline_text(7, "shared")])
    let document: Document = new_document(empty_document_metadata(), [block], [], [])
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 1 {
        panic("expected one duplicate id error")
    }
    if !errors⁅0⁆.code.equals("document.error.duplicate_id") {
        panic("error code should be duplicate_id")
    }
    if errors⁅0⁆.node_id != 7 {
        panic("duplicate id error should carry the repeated id")
    }
}

[test]
micro validate_flags_duplicate_attribute() -> unit {
    let attributes: [DocumentAttribute] = [
        document_attribute("data-x", "1"),
        document_attribute("data-x", "2")
    ]
    let block: Block = block_with_attributes(block_paragraph(1, [inline_text(2, "x")]), attributes)
    let document: Document = new_document(empty_document_metadata(), [block], [], [])
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 1 {
        panic("expected one duplicate attribute error")
    }
    if !errors⁅0⁆.code.equals("document.error.duplicate_attribute") {
        panic("error code should be duplicate_attribute")
    }
    if errors⁅0⁆.node_id != 1 {
        panic("duplicate attribute error should point at the block")
    }
}

[test]
micro validate_flags_undefined_footnote() -> unit {
    let block: Block = block_paragraph(1, [inline_footnote_ref(2, "missing")])
    let document: Document = new_document(empty_document_metadata(), [block], [], [])
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 1 {
        panic("expected one undefined footnote error")
    }
    if !errors⁅0⁆.code.equals("document.error.undefined_footnote") {
        panic("error code should be undefined_footnote")
    }
    if errors⁅0⁆.node_id != 2 {
        panic("footnote error should point at the inline ref")
    }
}

[test]
micro validate_flags_undefined_and_empty_citation() -> unit {
    let undefined: Block = block_paragraph(1, [inline_citation_ref(2, ["missing"])])
    let empty: Block = block_paragraph(3, [inline_citation_ref(4, [])])
    let document: Document = new_document(empty_document_metadata(), [undefined, empty], [], [])
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 2 {
        panic("expected two citation errors")
    }
    if !errors⁅0⁆.code.equals("document.error.undefined_citation") {
        panic("error code should be undefined_citation")
    }
    if !errors⁅1⁆.code.equals("document.error.undefined_citation") {
        panic("empty keys should share the citation error code")
    }
}

[test]
micro validate_flags_duplicate_footnote_and_bib_keys() -> unit {
    let footnotes: [FootnoteDefinition] = [
        footnote_definition("fn1", [block_paragraph(1, [inline_text(2, "a")])]),
        footnote_definition("fn1", [block_paragraph(3, [inline_text(4, "b")])])
    ]
    let bibliography: [BibliographyEntry] = [
        bibliography_entry("bib1", []),
        bibliography_entry("bib1", [])
    ]
    let document: Document = new_document(empty_document_metadata(), [], footnotes, bibliography)
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 2 {
        panic("expected footnote and bibliography key errors")
    }
    if !errors⁅0⁆.code.equals("document.error.duplicate_footnote_key") {
        panic("first error should be duplicate_footnote_key")
    }
    if !errors⁅1⁆.code.equals("document.error.duplicate_bib_key") {
        panic("second error should be duplicate_bib_key")
    }
    if errors⁅0⁆.node_id != 0 {
        panic("document level errors use node id zero")
    }
}

[test]
micro validate_walks_nested_quote_and_list_content() -> unit {
    let nested_heading: Block = block_heading(1, 9, [inline_text(2, "deep")])
    let quote: Block = block_quote(3, [nested_heading])
    let list: Block = block_list(4, false, 1, [
        list_item([block_quote(5, [block_heading(6, 0, [inline_text(7, "deeper")])])])
    ])
    let document: Document = new_document(empty_document_metadata(), [quote, list], [], [])
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 2 {
        panic("nested invalid headings should both be flagged")
    }
}

[test]
micro validate_walks_footnote_content_ids() -> unit {
    let block: Block = block_paragraph(9, [inline_text(10, "body")])
    let footnotes: [FootnoteDefinition] = [
        footnote_definition("fn1", [block_paragraph(9, [inline_text(11, "note")])])
    ]
    let document: Document = new_document(empty_document_metadata(), [block], footnotes, [])
    let errors: [DocumentError] = document_validate(document)
    if errors.length() != 1 {
        panic("footnote content shares the document id namespace")
    }
    if !errors⁅0⁆.code.equals("document.error.duplicate_id") {
        panic("error code should be duplicate_id")
    }
}

[test]
micro plain_text_projection_drops_marks() -> unit {
    let items: [Inline] = [
        inline_text(1, "a"),
        inline_styled(2, Emphasis, [inline_text(3, "b")]),
        inline_break(4, true),
        inline_text(5, "c")
    ]
    let plain: utf8 = inline_plain_all(items)
    if !plain.equals("ab\nc") {
        panic("plain projection should keep text and hard break")
    }
}
