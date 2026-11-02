namespace document.markdown;

using document::{DocumentAttribute, Inline, Strong, Emphasis, Code, document_attribute, inline_footnote_ref, inline_link, inline_styled, inline_text};

# 行内扫描：`**` 强、`*`  emphas、`` ` `` 代码、`[text](target)` 链接、
# `[^key]` 脚注引用、`$...$` 行内数学。未闭合标记按字面量处理（错误容许）。
# v0 样式内容不递归嵌套（子节点是单个 `Text`）。

structure MarkdownScan {
    gen: MarkdownIdGen
    items: [Inline]
}

micro markdown_scan_flush_plain(state: MarkdownScan, plain: utf8) -> MarkdownScan {
    if plain.length() == 0 {
        return state
    }
    let id: u64 = state.gen.next
    return MarkdownScan {
        gen: markdown_bump_id(state.gen),
        items: push(state.items, inline_text(id, plain))
    }
}

micro markdown_scan_push(state: MarkdownScan, item: Inline) -> MarkdownScan {
    return MarkdownScan {
        gen: state.gen,
        items: push(state.items, item)
    }
}

# 数学行内节点：`Styled{Code}` + classes + `tex` 属性；`display` 追加 `math-display`。
micro markdown_math_node(state: MarkdownScan, tex: utf8, display: bool) -> MarkdownScan {
    let text_id: u64 = state.gen.next
    let gen1: MarkdownIdGen = markdown_bump_id(state.gen)
    let node_id: u64 = gen1.next
    let mut classes: [utf8] = ["math"]
    if display {
        classes = push(classes, "math-display")
    }
    return MarkdownScan {
        gen: markdown_bump_id(gen1),
        items: push(state.items, Inline {
            id: node_id,
            classes: classes,
            attributes: [document_attribute("tex", tex)],
            kind: Styled {
                style: Code,
                content: [inline_text(text_id, tex)]
            }
        })
    }
}

micro markdown_scan_inlines(text: utf8, gen: MarkdownIdGen) -> MarkdownScan {
    let mut state: MarkdownScan = MarkdownScan {
        gen: gen,
        items: []
    }
    let mut plain: utf8 = ""
    let mut position: usize = 1
    let length: usize = text.length()
    while position <= length {
        let c: char = text[position]
        let mut handled: bool = false
        if c == '*' {
            let mut marker: utf8 = "*"
            let mut style_is_strong: bool = false
            if position + 1 <= length && text[position + 1] == '*' {
                marker = "**"
                style_is_strong = true
            }
            let close: Option<usize> = markdown_find(text, marker, position + marker.length())
            if close.is_some() {
                let inner: utf8 = text.slice(position + marker.length() - 1, close.unwrap() - position - marker.length())
                if inner.length() > 0 {
                    state = markdown_scan_flush_plain(state, plain)
                    plain = ""
                    let inner_id: u64 = state.gen.next
                    let gen1: MarkdownIdGen = markdown_bump_id(state.gen)
                    let node_id: u64 = gen1.next
                    state = MarkdownScan {
                        gen: markdown_bump_id(gen1),
                        items: push(state.items, inline_styled(node_id, if style_is_strong { Strong } else { Emphasis }, [inline_text(inner_id, inner)]))
                    }
                    position = close.unwrap() + marker.length()
                    handled = true
                }
            }
        } else if c == '`' {
            let close: Option<usize> = markdown_find(text, "`", position + 1)
            if close.is_some() {
                let inner: utf8 = text.slice(position, close.unwrap() - position - 1)
                if inner.length() > 0 {
                    state = markdown_scan_flush_plain(state, plain)
                    plain = ""
                    let inner_id: u64 = state.gen.next
                    let gen1: MarkdownIdGen = markdown_bump_id(state.gen)
                    let node_id: u64 = gen1.next
                    state = MarkdownScan {
                        gen: markdown_bump_id(gen1),
                        items: push(state.items, inline_styled(node_id, Code, [inline_text(inner_id, inner)]))
                    }
                    position = close.unwrap() + 1
                    handled = true
                }
            }
        } else if c == '$' {
            let mut marker: utf8 = "$"
            if position + 1 <= length && text[position + 1] == '$' {
                marker = "$$"
            }
            let close: Option<usize> = markdown_find(text, marker, position + marker.length())
            if close.is_some() {
                let inner: utf8 = text.slice(position + marker.length() - 1, close.unwrap() - position - marker.length())
                if inner.length() > 0 {
                    state = markdown_scan_flush_plain(state, plain)
                    plain = ""
                    state = markdown_math_node(state, inner, marker.length() == 2)
                    position = close.unwrap() + marker.length()
                    handled = true
                }
            }
        } else if c == '[' {
            if position + 1 <= length && text[position + 1] == '^' {
                let close: Option<usize> = markdown_find(text, "]", position + 2)
                if close.is_some() {
                    let key: utf8 = text.slice(position + 1, close.unwrap() - position - 2)
                    if key.length() > 0 {
                        state = markdown_scan_flush_plain(state, plain)
                        plain = ""
                        let node_id: u64 = state.gen.next
                        state = MarkdownScan {
                            gen: markdown_bump_id(state.gen),
                            items: push(state.items, inline_footnote_ref(node_id, key))
                        }
                        position = close.unwrap() + 1
                        handled = true
                    }
                }
            } else {
                let close: Option<usize> = markdown_find(text, "]", position + 1)
                if close.is_some() && close.unwrap() + 1 <= length && text[close.unwrap() + 1] == '(' {
                    let close_paren: Option<usize> = markdown_find(text, ")", close.unwrap() + 2)
                    if close_paren.is_some() {
                        let label: utf8 = text.slice(position, close.unwrap() - position - 1)
                        let target: utf8 = text.slice(close.unwrap() + 1, close_paren.unwrap() - close.unwrap() - 2)
                        state = markdown_scan_flush_plain(state, plain)
                        plain = ""
                        let content_id: u64 = state.gen.next
                        let gen1: MarkdownIdGen = markdown_bump_id(state.gen)
                        let node_id: u64 = gen1.next
                        state = MarkdownScan {
                            gen: markdown_bump_id(gen1),
                            items: push(state.items, inline_link(node_id, target, None, [inline_text(content_id, label)]))
                        }
                        position = close_paren.unwrap() + 1
                        handled = true
                    }
                }
            }
        }
        if !handled {
            plain = plain + std::text::encode_char_as_utf8(c)
            position = position + 1
        }
    }
    state = markdown_scan_flush_plain(state, plain)
    return state
}
