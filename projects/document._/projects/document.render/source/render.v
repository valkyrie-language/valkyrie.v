namespace document.render;

using document::{Document, DocumentError, DocumentIndex, document_index, document_validate};

# 渲染结果：`Fine` 完整产物 / `Fail` 结构化硬失败（`DocumentError` 归
# `document` 包，预检与渲染共用）。

unite RenderResult<T> {
    [constructor]
    Fine {
        value: T
    }
    [constructor]
    Fail {
        error: DocumentError
    }
}

micro render_fine<T>(value: T) -> RenderResult<T> {
    return Fine {
        value: value
    }
}

micro render_fail<T>(error: DocumentError) -> RenderResult<T> {
    return Fail {
        error: error
    }
}

# 管线第一步（R16）：预检 → 编号；预检聚合的违例取首条作为硬失败原因。
micro render_prepare(document: Document) -> RenderResult<DocumentIndex> {
    let errors: [DocumentError] = document_validate(document)
    if errors.length() > 0 {
        return render_fail(errors⁅0⁆)
    }
    return render_fine(document_index(document))
}

# 章节 anchor 查表：按 block id；未编号（嵌套 heading）返回空串。
micro render_anchor_of(index: DocumentIndex, node_id: u64) -> utf8 {
    let mut position: usize = 0
    while position < index.sections.length() {
        if index.sections⁅position⁆.node_id == node_id {
            return index.sections⁅position⁆.anchor
        }
        position = position + 1
    }
    return ""
}

# usize → 文本（编号、colspan 等）。
micro render_number(value: usize) -> utf8 {
    return format("{}", value)
}
