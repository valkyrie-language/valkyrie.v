namespace document;

# 文档本体、元数据与失败模型。
#
# 元数据与正文严格分离；`front_matter` 原样保留，核心不解释任何键名。
# 渲染/布局侧硬失败走结构化 `DocumentError`（稳定 code + `node_id`，文档级取 0），
# 不 panic、不产半成品。`DocumentError` 归本包：模型预检与渲染管线共用，
# `document.render` 仅引用。

structure DocumentMetadata {
    title: Option<utf8>
    authors: [utf8]
    date: Option<utf8>
    labels: [utf8]
    front_matter: [DocumentAttribute]
}

structure FootnoteDefinition {
    key: utf8
    content: [Block]
}

structure BibliographyEntry {
    key: utf8
    fields: [DocumentAttribute]
}

structure Document {
    metadata: DocumentMetadata
    blocks: [Block]
    footnotes: [FootnoteDefinition]
    bibliography: [BibliographyEntry]
}

structure DocumentError {
    code: utf8
    message: utf8
    node_id: u64
}

micro document_error(code: utf8, message: utf8, node_id: u64) -> DocumentError {
    return DocumentError {
        code: code,
        message: message,
        node_id: node_id
    }
}

micro document_metadata(title: Option<utf8>, authors: [utf8], date: Option<utf8>, labels: [utf8], front_matter: [DocumentAttribute]) -> DocumentMetadata {
    return DocumentMetadata {
        title: title,
        authors: authors,
        date: date,
        labels: labels,
        front_matter: front_matter
    }
}

micro empty_document_metadata() -> DocumentMetadata {
    return DocumentMetadata {
        title: None,
        authors: [],
        date: None,
        labels: [],
        front_matter: []
    }
}

micro footnote_definition(key: utf8, content: [Block]) -> FootnoteDefinition {
    return FootnoteDefinition {
        key: key,
        content: content
    }
}

micro bibliography_entry(key: utf8, fields: [DocumentAttribute]) -> BibliographyEntry {
    return BibliographyEntry {
        key: key,
        fields: fields
    }
}

micro new_document(metadata: DocumentMetadata, blocks: [Block], footnotes: [FootnoteDefinition], bibliography: [BibliographyEntry]) -> Document {
    return Document {
        metadata: metadata,
        blocks: blocks,
        footnotes: footnotes,
        bibliography: bibliography
    }
}

# 脚注键查定义（声明序即编号序，查表不经编号）。
micro document_find_footnote(document: Document, key: utf8) -> Option<FootnoteDefinition> {
    let mut index: usize = 0
    while index < document.footnotes.length() {
        if document.footnotes⁅index⁆.key.equals(key) {
            return Some(document.footnotes⁅index⁆)
        }
        index = index + 1
    }
    return None
}

micro document_has_footnote(document: Document, key: utf8) -> bool {
    return document_find_footnote(document, key).is_some()
}

micro document_find_bibliography(document: Document, key: utf8) -> Option<BibliographyEntry> {
    let mut index: usize = 0
    while index < document.bibliography.length() {
        if document.bibliography⁅index⁆.key.equals(key) {
            return Some(document.bibliography⁅index⁆)
        }
        index = index + 1
    }
    return None
}

micro document_has_bibliography(document: Document, key: utf8) -> bool {
    return document_find_bibliography(document, key).is_some()
}
