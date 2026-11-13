[test]
micro `test ascii view child window stays inside parent`() {
    # 底层 "abcdef"、父窗口 "bc"（offset 1, length 2）。
    let text: ascii = AsciiText { _bytes: [97, 98, 99, 100, 101, 102] }
    let parent: AsciiView = text.view(TextSpan {
        offset: 1,
        length: 2,
    })

    # 相对区间整体越过父窗口：收敛到父窗口末尾的空窗口，不得逃出成 "de"。
    let escaped: AsciiView = parent.view(TextSpan {
        offset: 2,
        length: 2,
    })
    let parent_span: TextSpan = parent.span()
    let escaped_span: TextSpan = escaped.span()
    if escaped_span.offset < parent_span.offset {
        panic("ascii view child must stay at or after parent start")
    }
    if escaped_span.offset + escaped_span.length > parent_span.offset + parent_span.length {
        panic("ascii view child window escaped parent")
    }
    if !escaped.to_text().equals("") {
        panic("ascii view escaped request must clamp to empty")
    }

    # 固定宽回绕探针：`父偏移 + 相对偏移` 恰在地址域回绕时，旧"先加后判"
    # 会把子窗口折回父窗口之前（逃出成 "ab"）；全 1 掩码以 hi/lo 组合表达
    # （编译器对超 i64 上限的十六进制字面量溢栈，同 test_range 先例）。
    let wrap_offset: usize = (((0xFFFFFFFF as u64) << 32) | (0xFFFFFFFF as u64)) as usize
    let wrapped: AsciiView = parent.view(TextSpan {
        offset: wrap_offset,
        length: 2,
    })
    let wrapped_span: TextSpan = wrapped.span()
    if wrapped_span.offset + wrapped_span.length > parent_span.offset + parent_span.length {
        panic("ascii view wraparound escaped parent")
    }
    if wrapped_span.offset < parent_span.offset {
        panic("ascii view wraparound child before parent start")
    }

    # 父窗口内的合法区间照常换算。
    let inside: AsciiView = parent.view(TextSpan {
        offset: 1,
        length: 1,
    })
    if !inside.to_text().equals("c") {
        panic("ascii view inside parent test failed")
    }
}
