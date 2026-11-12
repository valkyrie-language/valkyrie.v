[test]
micro `test utf8 view full and slice`() {
    let value: utf8 = "hello"
    let view: Utf8View = Utf8View::full(value)

    if view.is_empty() {
        panic("utf8 view is_empty test failed")
    }

    if view.byte_length() != 5 {
        panic("utf8 view byte_length test failed")
    }

    let full_span: TextSpan = view.span()
    if full_span.offset != 0 || full_span.length != 5 {
        panic("utf8 view full span test failed")
    }

    let part: Utf8Text = view.view(TextSpan {
        offset: 1,
        length: 3,
    }).to_text().unwrap()
    if !part.equals("ell") {
        panic("utf8 view slice test failed")
    }
}

[test]
micro `test utf8 view nested span`() {
    let value: utf8 = "hello"
    let view: Utf8View = Utf8View::new(value, TextSpan {
        offset: 1,
        length: 3,
    })

    let nested: Utf8View = view.view(TextSpan {
        offset: 1,
        length: 1,
    })
    let nested_span: TextSpan = nested.span()
    if nested_span.offset != 2 || nested_span.length != 1 {
        panic("utf8 view nested span test failed")
    }

    if !nested.to_text().unwrap().equals("l") {
        panic("utf8 view nested to_text test failed")
    }
}

[test]
micro `test utf8 view clamp`() {
    let value: utf8 = "hello"
    let view: Utf8View = Utf8View::new(value, TextSpan {
        offset: 3,
        length: 10,
    })

    let span: TextSpan = view.span()
    if span.offset != 3 || span.length != 2 {
        panic("utf8 view clamp span test failed")
    }

    if !view.to_text().unwrap().equals("lo") {
        panic("utf8 view clamp to_text test failed")
    }
}

[test]
micro `test utf8 view child window stays inside parent`() {
    # 底层 "abcdef"、父窗口 "bc"（offset 1, length 2）。
    let value: utf8 = "abcdef"
    let parent: Utf8View = Utf8View::new(value, TextSpan {
        offset: 1,
        length: 2,
    })

    # 相对区间整体越过父窗口：收敛到父窗口末尾的空窗口，不得逃出成 "de"。
    let escaped: Utf8View = parent.view(TextSpan {
        offset: 2,
        length: 2,
    })
    let parent_span: TextSpan = parent.span()
    let escaped_span: TextSpan = escaped.span()
    if escaped_span.offset < parent_span.offset {
        panic("utf8 view child must stay at or after parent start")
    }
    if escaped_span.offset + escaped_span.length > parent_span.offset + parent_span.length {
        panic("utf8 view child window escaped parent")
    }
    if !escaped.to_text().unwrap().equals("") {
        panic("utf8 view escaped request must clamp to empty")
    }

    # 严格版对越父区间结构化拒绝。
    let strict: Result<Utf8View, Utf8ViewError> = parent.try_view(TextSpan {
        offset: 2,
        length: 2,
    })
    let mut rejected: bool = false
    match strict {
        case Fine(strict_inner):
            panic("utf8 try_view must reject out-of-parent range")
        case Fail(error):
            rejected = true
    }
    if !rejected {
        panic("utf8 try_view rejection must be observable")
    }

    # 父窗口内的合法区间照常换算。
    let inside: Utf8View = parent.view(TextSpan {
        offset: 1,
        length: 1,
    })
    if !inside.to_text().unwrap().equals("c") {
        panic("utf8 view inside parent test failed")
    }
}
