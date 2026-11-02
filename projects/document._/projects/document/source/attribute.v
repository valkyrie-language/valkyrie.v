namespace document;

# 开放扩展面：核心不解释的扩展信息一律经 `classes` / `attributes` 携带，
# 不为单个方言新增专用字段。`attributes` 内键可重复出现由构造侧负责去重，
# 校验侧对重复键报 `document.error.duplicate_attribute`。
structure DocumentAttribute {
    name: utf8
    value: utf8
}

micro document_attribute(name: utf8, value: utf8) -> DocumentAttribute {
    return DocumentAttribute {
        name: name,
        value: value
    }
}

# 按键查值：同名键取首个命中；未命中返回 `None`。核心不解释键名。
micro attribute_value(attributes: [DocumentAttribute], name: utf8) -> Option<utf8> {
    let mut index: usize = 0
    while index < attributes.length() {
        if attributes⁅index⁆.name.equals(name) {
            return Some(attributes⁅index⁆.value)
        }
        index = index + 1
    }
    return None
}

# 键是否重复（同一节点内判定，供校验与构造侧自检共用）。
micro attributes_have_duplicate_name(attributes: [DocumentAttribute]) -> bool {
    let mut outer: usize = 0
    while outer < attributes.length() {
        let mut inner: usize = outer + 1
        while inner < attributes.length() {
            if attributes⁅outer⁆.name.equals(attributes⁅inner⁆.name) {
                return true
            }
            inner = inner + 1
        }
        outer = outer + 1
    }
    return false
}
