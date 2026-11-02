namespace std.data.text.markdown;

using std.data::{DataCstNode, DataOutcome, DataSettings, DataSource, data_cst_missing, data_outcome_failed, data_outcome_partial, data_outcome_value_or, data_source_from_text, new_data_settings};
using std.diagnostic::{Error, new_diagnostic, new_span};
using document::{Block, Document, FootnoteDefinition, block_thematic_break, empty_document_metadata, new_document};

# 构建入口：`NodeDocument` -> `document::Document`。

micro markdown_build(node: DataCstNode<MarkdownTokenKind>, source: DataSource, settings: DataSettings) -> DataOutcome<Document> {
    match source {
        case Text(payload):
            let state: MarkdownBuildState = MarkdownBuildState {
                text: payload.text,
                gen: MarkdownIdGen {
                    next: 1
                }
            }
            let mut blocks: [Block] = []
            let mut footnotes: [FootnoteDefinition] = []
            let mut current: MarkdownBuildState = state
            match node {
                case Node(root):
                    let mut index: usize = 0
                    while index < root.children.length() {
                        let child: DataCstNode<MarkdownTokenKind> = root.children⁅index⁆
                        let mut out: MarkdownBlocks = MarkdownBlocks {
                            state: current,
                            blocks: [],
                            footnotes: []
                        }
                        match child {
                            case Node(payload):
                                match payload.kind {
                                    case NodeHeading:
                                        out = markdown_build_heading(child, current)
                                    case NodeParagraph:
                                        out = markdown_build_paragraph(child, current)
                                    case NodeFence:
                                        out = markdown_build_fence(child, current)
                                    case NodeTable:
                                        out = markdown_build_table(child, current)
                                    case NodeList:
                                        out = markdown_build_list(child, current)
                                    case NodeThematicBreak:
                                        let id: u64 = markdown_take_id(current)
                                        out = MarkdownBlocks {
                                            state: markdown_bump(current),
                                            blocks: [block_thematic_break(id)],
                                            footnotes: []
                                        }
                                    else:
                                        out = out
                                }
                            else:
                                out = out
                        }
                        current = out.state
                        let mut merge: usize = 0
                        while merge < out.blocks.length() {
                            blocks = push(blocks, out.blocks⁅merge⁆)
                            merge = merge + 1
                        }
                        merge = 0
                        while merge < out.footnotes.length() {
                            footnotes = push(footnotes, out.footnotes⁅merge⁆)
                            merge = merge + 1
                        }
                        index = index + 1
                    }
                else:
                    blocks = blocks
            }
            return data_outcome_partial(new_document(empty_document_metadata(), blocks, footnotes, []), [])
        case Bytes(payload):
            return data_outcome_failed([new_diagnostic("markdown.build.binary_source", Error, "binary source is not markdown input", new_span(0, 0))])
    }
}

# 便捷管线：源文本 -> `document::Document`（词法 -> 语法 -> 语义全链）。
micro markdown_parse_document(text: utf8) -> DataOutcome<Document> {
    let settings: DataSettings = new_data_settings(64, 0)
    let source: DataSource = data_source_from_text(text)
    let lexed: DataOutcome<[MarkdownToken]> = markdown_lex(text)
    let tokens: [MarkdownToken] = data_outcome_value_or(lexed, [])
    let parsed: DataOutcome<DataCstNode<MarkdownTokenKind>> = markdown_parse(tokens, settings)
    let cst: DataCstNode<MarkdownTokenKind> = data_outcome_value_or(parsed, data_cst_missing(new_span(0, 0), "parse failed"))
    return markdown_build(cst, source, settings)
}
