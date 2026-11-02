namespace document;

# Inline 语义内容：行内节点骨架与种类和。
#
# `id` 文档内唯一（与 Block 同一命名空间）；`classes`/`attributes` 是开放扩展面。
# `Styled` 允许嵌套；同 style 直接嵌套在渲染时归一为单层（渲染归一，非错误）。

enums InlineStyle {
    Strong
    Emphasis
    Code
    Strike
}

unite InlineKind {
    [constructor]
    Text {
        text: utf8
    }
    [constructor]
    Styled {
        style: InlineStyle
        content: [Inline]
    }
    [constructor]
    Link {
        target: utf8
        title: Option<utf8>
        content: [Inline]
    }
    [constructor]
    InlineImage {
        source: utf8
        alt: [Inline]
        title: Option<utf8>
    }
    [constructor]
    Break {
        hard: bool
    }
    [constructor]
    FootnoteRef {
        key: utf8
    }
    [constructor]
    CitationRef {
        keys: [utf8]
    }
}

structure Inline {
    id: u64
    classes: [utf8]
    attributes: [DocumentAttribute]
    kind: InlineKind
}

micro inline_text(id: u64, text: utf8) -> Inline {
    return Inline {
        id: id,
        classes: [],
        attributes: [],
        kind: Text {
            text: text
        }
    }
}

micro inline_styled(id: u64, style: InlineStyle, content: [Inline]) -> Inline {
    return Inline {
        id: id,
        classes: [],
        attributes: [],
        kind: Styled {
            style: style,
            content: content
        }
    }
}

micro inline_link(id: u64, target: utf8, title: Option<utf8>, content: [Inline]) -> Inline {
    return Inline {
        id: id,
        classes: [],
        attributes: [],
        kind: Link {
            target: target,
            title: title,
            content: content
        }
    }
}

micro inline_image(id: u64, source: utf8, alt: [Inline], title: Option<utf8>) -> Inline {
    return Inline {
        id: id,
        classes: [],
        attributes: [],
        kind: InlineImage {
            source: source,
            alt: alt,
            title: title
        }
    }
}

micro inline_break(id: u64, hard: bool) -> Inline {
    return Inline {
        id: id,
        classes: [],
        attributes: [],
        kind: Break {
            hard: hard
        }
    }
}

micro inline_footnote_ref(id: u64, key: utf8) -> Inline {
    return Inline {
        id: id,
        classes: [],
        attributes: [],
        kind: FootnoteRef {
            key: key
        }
    }
}

micro inline_citation_ref(id: u64, keys: [utf8]) -> Inline {
    return Inline {
        id: id,
        classes: [],
        attributes: [],
        kind: CitationRef {
            keys: keys
        }
    }
}

# 纯文本投影：样式、目标与属性被丢弃，面向纯文本消费者的扁平化。
micro inline_plain_text(item: Inline) -> utf8 {
    match item.kind {
        case Text(payload):
            return payload.text
        case Styled(payload):
            return inline_plain_all(payload.content)
        case Link(payload):
            return inline_plain_all(payload.content)
        case InlineImage(payload):
            return inline_plain_all(payload.alt)
        case Break(payload):
            if payload.hard {
                return "\n"
            }
            return " "
        case FootnoteRef(payload):
            return ""
        case CitationRef(payload):
            return ""
    }
}

micro inline_plain_all(items: [Inline]) -> utf8 {
    let mut out: utf8 = ""
    let mut index: usize = 0
    while index < items.length() {
        out = out + inline_plain_text(items⁅index⁆)
        index = index + 1
    }
    return out
}
