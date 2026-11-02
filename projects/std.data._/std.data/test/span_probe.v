namespace std.data;

# span 工具直接调用的探针：与 infix 候选缺口同批等待编译器修复。

[test]
micro test_probe_well_formed_function_call() -> unit {
    let span: DataSpan = new_data_span(0, 5)
    if !data_span_is_well_formed(span) {
        panic("well formed expected")
    }
}

[test]
micro test_probe_span_contains() -> unit {
    let parent: DataSpan = new_data_span(0, 10)
    let child: DataSpan = new_data_span(2, 5)
    if !data_span_contains(parent, child) {
        panic("contains expected")
    }
    let outside: DataSpan = new_data_span(8, 12)
    if data_span_contains(parent, outside) {
        panic("outside must not be contained")
    }
}
