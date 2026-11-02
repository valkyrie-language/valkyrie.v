namespace document.markdown;

using document::{Block, Document};

[test]
micro parse_assigns_unique_ids_in_document_order() -> unit {
    let document: Document = markdown_parse_document("# A\n\npara with **bold**.\n\n- one\n- two\n")
    if document.blocks.length() != 3 {
        panic("heading paragraph list blocks parse")
    }
    let heading: Block = document.blocks⁅0⁆
    let paragraph: Block = document.blocks⁅1⁆
    let list: Block = document.blocks⁅2⁆
    if heading.id != 2 {
        panic("heading id follows its content id")
    }
    if paragraph.id <= heading.id || list.id <= paragraph.id {
        panic("ids increase in document order")
    }
}

[test]
micro parse_collects_table_and_footnote() -> unit {
    let document: Document = markdown_parse_document("| H |\n| --- |\n| b |\n\n[^n1]: note\n")
    if document.blocks.length() != 1 {
        panic("table block parses")
    }
    if document.footnotes.length() != 1 {
        panic("footnote definition collects")
    }
    if !document.footnotes⁅0⁆.key.equals("n1") {
        panic("footnote key keeps source spelling")
    }
}

[test]
micro parse_marks_math_with_extension_surface() -> unit {
    let document: Document = markdown_parse_document("a $x$ b\n\n$$\ny\n$$\n")
    if document.blocks.length() != 2 {
        panic("inline and display math paragraphs parse")
    }
    let mut inline_math_found: bool = false
    match document.blocks⁅0⁆.kind {
        case Paragraph(payload):
            if payload.content.length() == 3 {
                if payload.content⁅1⁆.classes.length() == 1 && payload.content⁅1⁆.classes⁅0⁆.equals("math") {
                    inline_math_found = true
                }
            }
        else:
            inline_math_found = false
    }
    if !inline_math_found {
        panic("inline math carries the math class")
    }
    let mut display_math_found: bool = false
    match document.blocks⁅1⁆.kind {
        case Paragraph(payload):
            if payload.content.length() == 1 && payload.content⁅0⁆.classes.length() == 2 {
                display_math_found = true
            }
        else:
            display_math_found = false
    }
    if !display_math_found {
        panic("display math carries the display class")
    }
}

[test]
micro parse_unclosed_markers_stay_literal() -> unit {
    let document: Document = markdown_parse_document("a **b c `d\n")
    if document.blocks.length() != 1 {
        panic("unclosed markers stay one paragraph")
    }
    match document.blocks⁅0⁆.kind {
        case Paragraph(payload):
            if payload.content.length() != 1 {
                panic("unclosed markers keep literal text without style nodes")
            }
        else:
            panic("paragraph expected")
    }
}

[test]
micro parse_unclosed_fence_consumes_to_end() -> unit {
    let document: Document = markdown_parse_document("```v\nlet a = 1\nlet b = 2\n")
    if document.blocks.length() != 1 {
        panic("unclosed fence consumes to end of source")
    }
    match document.blocks⁅0⁆.kind {
        case CodeBlock(payload):
            if !payload.text.equals("let a = 1\nlet b = 2") {
                panic("fence body keeps both lines")
            }
        else:
            panic("code block expected")
    }
}
