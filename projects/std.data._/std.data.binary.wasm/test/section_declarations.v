namespace std.data.binary.wasm;

# wasm 骨架声明验证：section 头承载物可构造、kind 变体可引用。

[test]
micro test_wasm_section_header_constructible() -> unit {
    let header: WasmSectionHeader = WasmSectionHeader {
        kind: Type,
        id: 1,
        span: new_span(8, 20),
        header_span: new_span(6, 8)
    }
    if header.id != 1 {
        panic("section id mismatch")
    }
    if header.span.start != 8 {
        panic("payload span start mismatch")
    }
    if header.header_span.stop != 8 {
        panic("header span stop mismatch")
    }
}

[test]
micro test_wasm_section_kind_variants() -> unit {
    let custom: WasmSectionKind = Custom
    let code: WasmSectionKind = Code
    let unknown: WasmSectionKind = Unknown
    if custom == code {
        panic("section kinds must differ")
    }
    if code == unknown {
        panic("section kinds must differ")
    }
}
