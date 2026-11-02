namespace document;

[test]
micro index_numbers_top_level_headings_only() -> unit {
    let document: Document = new_document(empty_document_metadata(), [
        block_heading(1, 1, [inline_text(2, "One")]),
        block_quote(3, [block_heading(4, 1, [inline_text(5, "Nested")])]),
        block_heading(6, 2, [inline_text(7, "Two")]),
        block_list(8, false, 1, [list_item([block_heading(9, 1, [inline_text(10, "Deep")])])])
    ], [], [])
    let index: DocumentIndex = document_index(document)
    if index.sections.length() != 2 {
        panic("only top level headings get numbered")
    }
    if !index.sections⁅0⁆.anchor.equals("1") {
        panic("first heading anchors at 1")
    }
    if !index.sections⁅1⁆.anchor.equals("1.1") {
        panic("second heading anchors at 1.1")
    }
    if index.sections⁅0⁆.node_id != 1 || index.sections⁅1⁆.node_id != 6 {
        panic("section refs carry heading node ids")
    }
}

[test]
micro index_records_skipped_levels_without_padding() -> unit {
    let document: Document = new_document(empty_document_metadata(), [
        block_heading(1, 1, [inline_text(2, "One")]),
        block_heading(3, 3, [inline_text(4, "Three")])
    ], [], [])
    let index: DocumentIndex = document_index(document)
    if index.sections.length() != 2 {
        panic("both headings numbered")
    }
    let parts: [usize] = index.sections⁅1⁆.number.parts
    if parts.length() != 3 {
        panic("level three heading keeps three segments")
    }
    if parts⁅0⁆ != 1 || parts⁅1⁆ != 0 || parts⁅2⁆ != 1 {
        panic("skipped level keeps zero segment")
    }
    if !index.sections⁅1⁆.anchor.equals("1.0.1") {
        panic("anchor keeps the zero segment")
    }
}

[test]
micro index_resets_deeper_counters() -> unit {
    let document: Document = new_document(empty_document_metadata(), [
        block_heading(1, 1, [inline_text(2, "A")]),
        block_heading(3, 2, [inline_text(4, "B")]),
        block_heading(5, 1, [inline_text(6, "C")]),
        block_heading(7, 2, [inline_text(8, "D")])
    ], [], [])
    let index: DocumentIndex = document_index(document)
    if index.sections.length() != 4 {
        panic("all four headings numbered")
    }
    if !index.sections⁅2⁆.anchor.equals("2") {
        panic("level one counter advances")
    }
    if !index.sections⁅3⁆.anchor.equals("2.1") {
        panic("level two counter resets after new level one")
    }
}

[test]
micro index_numbers_footnotes_and_citations_by_declaration() -> unit {
    let footnotes: [FootnoteDefinition] = [
        footnote_definition("later", [block_paragraph(1, [inline_text(2, "a")])]),
        footnote_definition("first", [block_paragraph(3, [inline_text(4, "b")])])
    ]
    let bibliography: [BibliographyEntry] = [
        bibliography_entry("zebra", []),
        bibliography_entry("apple", [])
    ]
    let document: Document = new_document(empty_document_metadata(), [], footnotes, bibliography)
    let index: DocumentIndex = document_index(document)
    let footnote_number: Option<usize> = document_index_footnote_number(index, "first")
    if footnote_number.is_none() {
        panic("footnote key resolves")
    }
    if footnote_number.unwrap() != 2 {
        panic("footnote number follows declaration order")
    }
    let citation_number: Option<usize> = document_index_citation_number(index, "apple")
    if citation_number.is_none() {
        panic("citation key resolves")
    }
    if citation_number.unwrap() != 2 {
        panic("citation number follows declaration order")
    }
    if document_index_footnote_number(index, "missing").is_some() {
        panic("missing footnote key stays none")
    }
}

[test]
micro toc_mirrors_sections_without_rescanning() -> unit {
    let document: Document = new_document(empty_document_metadata(), [
        block_heading(1, 1, [inline_text(2, "One")]),
        block_paragraph(3, [inline_text(4, "body")]),
        block_heading(5, 2, [inline_text(6, "Two")])
    ], [], [])
    let toc: [TocEntry] = document_toc(document_index(document))
    if toc.length() != 2 {
        panic("toc has one entry per section")
    }
    if toc⁅0⁆.level != 1 || toc⁅1⁆.level != 2 {
        panic("toc level comes from the section number depth")
    }
    if !toc⁅1⁆.anchor.equals("1.1") {
        panic("toc keeps section anchors")
    }
    if !inline_plain_all(toc⁅0⁆.title).equals("One") {
        panic("toc keeps section titles")
    }
}
