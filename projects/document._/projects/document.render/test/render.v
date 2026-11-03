namespace document.render;

using document::{BibliographyEntry, Block, Document, FootnoteDefinition, Strong, block_code, block_heading, block_image, block_list, block_paragraph, block_quote, block_table, block_thematic_break, document_attribute, bibliography_entry, empty_document_metadata, footnote_definition, inline_citation_ref, inline_footnote_ref, inline_styled, inline_text, list_item, new_document, table_cell, table_row};

micro render_sample_document() -> Document {
    let blocks: [Block] = [
        block_heading(1, 1, [inline_text(2, "Guide")]),
        block_paragraph(3, [
            inline_text(4, "A & B"),
            inline_styled(5, Strong, [inline_text(6, "bold")]),
            inline_footnote_ref(7, "fn1"),
            inline_citation_ref(8, ["b1"])
        ]),
        block_list(9, false, 1, [
            list_item([block_paragraph(10, [inline_text(11, "one")])]),
            list_item([block_paragraph(12, [inline_text(13, "two")])])
        ]),
        block_code(14, Some("v"), "let x = 1"),
        block_quote(15, [block_paragraph(16, [inline_text(17, "quoted")])]),
        block_thematic_break(18),
        block_table(19, None, [table_row([table_cell([block_paragraph(20, [inline_text(21, "H")])], 1, 1)], true)], [table_row([table_cell([block_paragraph(22, [inline_text(23, "b")])], 1, 1)], false)]),
        block_image(24, "a.png", [inline_text(25, "alt")], None)
    ]
    let footnotes: [FootnoteDefinition] = [footnote_definition("fn1", [block_paragraph(26, [inline_text(27, "note")])])]
    let bibliography: [BibliographyEntry] = [bibliography_entry("b1", [document_attribute("title", "Ref")])]
    return new_document(empty_document_metadata(), blocks, footnotes, bibliography)
}

[test]
micro html_snapshot_full_document() -> unit {
    let result: RenderResult<utf8> = render_html(render_sample_document())
    match result {
        case Fine(payload):
            let expected: utf8 = "<h1 id='1'>Guide</h1>"
                + "<p>A &amp; B<strong>bold</strong><sup><a href='#fn-1' id='fnref-1'>1</a></sup><sup>[<a href='#bib-1'>1</a>]</sup></p>"
                + "<ul><li><p>one</p></li><li><p>two</p></li></ul>"
                + "<pre><code class='language-v'>let x = 1</code></pre>"
                + "<blockquote><p>quoted</p></blockquote>"
                + "<hr/>"
                + "<table><thead><tr><th><p>H</p></th></tr></thead><tbody><tr><td><p>b</p></td></tr></tbody></table>"
                + "<img src='a.png' alt='alt'/>"
                + "<section class='footnotes'><ol><li id='fn-1'><p>note</p> <a href='#fnref-1' class='footnote-backref'>↩</a></li></ol></section>"
                + "<section class='bibliography'><ol><li id='bib-1'>title: Ref</li></ol></section>"
            if !payload.value.equals(expected) {
                panic("html snapshot matches")
            }
        case Fail(payload):
            panic("valid document renders html")
    }
}

[test]
micro text_snapshot_full_document() -> unit {
    let result: RenderResult<utf8> = render_text(render_sample_document())
    match result {
        case Fine(payload):
            let expected: utf8 = "Guide"
                + "\n\nA & Bbold[1][1]"
                + "\n\n- one\n- two"
                + "\n\n```v\nlet x = 1\n```"
                + "\n\n> quoted"
                + "\n\n---"
                + "\n\n| H |\n| b |"
                + "\n\n[image: alt]"
                + "\n\n[1] note"
                + "\n\n[1] title: Ref"
            if !payload.value.equals(expected) {
                panic("text snapshot matches")
            }
        case Fail(payload):
            panic("valid document renders text")
    }
}

[test]
micro markdown_snapshot_full_document() -> unit {
    let result: RenderResult<utf8> = render_markdown(render_sample_document())
    match result {
        case Fine(payload):
            let expected: utf8 = "# Guide"
                + "\n\nA & B**bold**[^fn1][1]"
                + "\n\n- one\n- two"
                + "\n\n```v\nlet x = 1\n```"
                + "\n\n> quoted"
                + "\n\n---"
                + "\n\n| H |\n| --- |\n| b |"
                + "\n\n![alt](a.png)"
                + "\n\n[^fn1]: note"
                + "\n\n[1] title: Ref"
            if !payload.value.equals(expected) {
                panic("markdown snapshot matches")
            }
        case Fail(payload):
            panic("valid document renders markdown")
    }
}

[test]
micro render_fails_fast_on_invalid_document() -> unit {
    let document: Document = new_document(empty_document_metadata(), [block_heading(1, 7, [inline_text(2, "x")])], [], [])
    match render_html(document) {
        case Fine(payload):
            panic("invalid document must not render")
        case Fail(payload):
            if !payload.error.code.equals("document.error.heading_level") {
                panic("failure carries the validation code")
            }
    }
    match render_text(document) {
        case Fine(payload):
            panic("invalid document must not render")
        case Fail(payload):
            if payload.error.node_id != 1 {
                panic("failure carries the node id")
            }
    }
}

[test]
micro nested_heading_gets_no_anchor() -> unit {
    let document: Document = new_document(empty_document_metadata(), [
        block_quote(1, [block_heading(2, 1, [inline_text(3, "deep")])])
    ], [], [])
    match render_html(document) {
        case Fine(payload):
            if !payload.value.equals("<blockquote><h1>deep</h1></blockquote>") {
                panic("nested heading renders without id attribute")
            }
        case Fail(payload):
            panic("valid document renders html")
    }
}

[test]
micro nested_list_renders_across_targets() -> unit {
    let document: Document = new_document(empty_document_metadata(), [
        block_list(1, false, 1, [
            list_item([block_paragraph(2, [inline_text(3, "outer")]), block_list(4, true, 1, [list_item([block_paragraph(5, [inline_text(6, "inner")])])])])
        ])
    ], [], [])
    match render_html(document) {
        case Fine(payload):
            let expected: utf8 = "<ul><li><p>outer</p><ol><li><p>inner</p></li></ol></li></ul>"
            if !payload.value.equals(expected) {
                panic("nested list renders nested tags")
            }
        case Fail(payload):
            panic("nested list renders html")
    }
    match render_text(document) {
        case Fine(payload):
            let expected: utf8 = "- outer\n  1. inner"
            if !payload.value.equals(expected) {
                panic("nested list indents two spaces per level")
            }
        case Fail(payload):
            panic("nested list renders text")
    }
    match render_markdown(document) {
        case Fine(payload):
            let expected: utf8 = "- outer\n  1. inner"
            if !payload.value.equals(expected) {
                panic("nested list keeps marker indentation in markdown")
            }
        case Fail(payload):
            panic("nested list renders markdown")
    }
}

[test]
micro markdown_table_pads_columns() -> unit {
    let document: Document = new_document(empty_document_metadata(), [
        block_table(1, None, [table_row([table_cell([block_paragraph(2, [inline_text(3, "Name")])], 1, 1), table_cell([block_paragraph(4, [inline_text(5, "V")])], 1, 1)], true)], [table_row([table_cell([block_paragraph(6, [inline_text(7, "a")])], 1, 1), table_cell([block_paragraph(8, [inline_text(9, "10")])], 1, 1)], false)])
    ], [], [])
    match render_markdown(document) {
        case Fine(payload):
            let expected: utf8 = "| Name | V  |\n| ---- | --- |\n| a    | 10 |"
            if !payload.value.equals(expected) {
                panic("markdown table pads cells to column width")
            }
        case Fail(payload):
            panic("table renders markdown")
    }
    match render_text(document) {
        case Fine(payload):
            let expected: utf8 = "| Name | V  |\n| a    | 10 |"
            if !payload.value.equals(expected) {
                panic("text table shares the same column widths")
            }
        case Fail(payload):
            panic("table renders text")
    }
}

[test]
micro heading_levels_carry_ordered_anchors() -> unit {
    let document: Document = new_document(empty_document_metadata(), [
        block_heading(1, 1, [inline_text(2, "One")]),
        block_heading(3, 2, [inline_text(4, "Two")]),
        block_heading(5, 1, [inline_text(6, "Three")])
    ], [], [])
    match render_html(document) {
        case Fine(payload):
            let expected: utf8 = "<h1 id='1'>One</h1><h2 id='1.1'>Two</h2><h1 id='2'>Three</h1>"
            if !payload.value.equals(expected) {
                panic("heading levels carry ordered anchors")
            }
        case Fail(payload):
            panic("headings render html")
    }
}

[test]
micro ordered_list_start_attribute() -> unit {
    let document: Document = new_document(empty_document_metadata(), [
        block_list(1, true, 3, [list_item([block_paragraph(2, [inline_text(3, "x")])])])
    ], [], [])
    match render_html(document) {
        case Fine(payload):
            if !payload.value.equals("<ol start='3'><li><p>x</p></li></ol>") {
                panic("ordered list start renders as attribute")
            }
        case Fail(payload):
            panic("valid document renders html")
    }
    match render_text(document) {
        case Fine(payload):
            if !payload.value.equals("3. x") {
                panic("ordered list start renders as marker")
            }
        case Fail(payload):
            panic("valid document renders text")
    }
}
