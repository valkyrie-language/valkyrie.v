namespace notedown;

# Inline 语义内容：表达文档语义，不表达解析器语法。
#
# InlineKind: 0=Text, 1=Styled, 2=InlineCode, 3=Link, 4=Image, 5=Break, 6=RawHtml

structure Inline {
    kind: i32
    text: utf8
    style: utf8
    children: [Inline]
    target: utf8
    title: Option<utf8>
    hard: bool
}

micro inline_text(text: utf8) -> Inline {
    return Inline {
        kind: 0,
        text: text,
        style: "",
        children: [],
        target: "",
        title: None,
        hard: false
    }
}

micro inline_styled(style: utf8, children: [Inline]) -> Inline {
    return Inline {
        kind: 1,
        text: "",
        style: style,
        children: children,
        target: "",
        title: None,
        hard: false
    }
}

micro inline_code(text: utf8) -> Inline {
    return Inline {
        kind: 2,
        text: text,
        style: "",
        children: [],
        target: "",
        title: None,
        hard: false
    }
}

micro inline_link(target: utf8, display: [Inline], title: Option<utf8>) -> Inline {
    return Inline {
        kind: 3,
        text: "",
        style: "",
        children: display,
        target: target,
        title: title,
        hard: false
    }
}

micro inline_image(source: utf8, alt: [Inline], title: Option<utf8>) -> Inline {
    return Inline {
        kind: 4,
        text: "",
        style: "",
        children: alt,
        target: source,
        title: title,
        hard: false
    }
}

micro inline_break(hard: bool) -> Inline {
    return Inline {
        kind: 5,
        text: "",
        style: "",
        children: [],
        target: "",
        title: None,
        hard: hard
    }
}

micro inline_raw_html(html: utf8) -> Inline {
    return Inline {
        kind: 6,
        text: html,
        style: "",
        children: [],
        target: "",
        title: None,
        hard: false
    }
}

# 面向纯文本消费者的扁平投影：样式、目标身份与属性被丢弃。
micro inline_plain_text(item: Inline) -> utf8 {
    if item.kind == 0 {
        return item.text
    }
    if item.kind == 1 {
        return inline_plain_all(item.children)
    }
    if item.kind == 2 {
        return item.text
    }
    if item.kind == 3 {
        return inline_plain_all(item.children)
    }
    if item.kind == 4 {
        return inline_plain_all(item.children)
    }
    if item.kind == 5 {
        if item.hard {
            return "\n"
        }
        return " "
    }
    return ""
}

micro inline_plain_all(items: [Inline]) -> utf8 {
    let mut out: utf8 = ""
    let mut index: usize = 0
    while index < items.length() {
        let item: Inline = items⁅index⁆
        out = out + inline_plain_text(item)
        index = index + 1
    }
    return out
}
