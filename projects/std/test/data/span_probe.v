namespace std.data;

using std.diagnostic::{Span, new_span, span_is_well_formed, span_contains};

# span 工具直接调用的探针：与 infix 候选缺口同批等待编译器修复。

[test]
micro test_probe_well_formed_function_call() -> unit {
    let span: Span = new_span(0, 5)
    if !span_is_well_formed(span) {
        panic("well formed expected")
    }
}

[test]
micro test_probe_span_contains() -> unit {
    let parent: Span = new_span(0, 10)
    let child: Span = new_span(2, 5)
    if !span_contains(parent, child) {
        panic("contains expected")
    }
    let outside: Span = new_span(8, 12)
    if span_contains(parent, outside) {
        panic("outside must not be contained")
    }
}
