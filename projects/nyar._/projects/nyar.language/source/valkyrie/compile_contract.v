namespace nyar.language.valkyrie;

structure CompileOutput {
    assembly_name: utf8
    namespace_symbol: utf8
    console_message: utf8
    source_files: [utf8]
}

structure CompileResult {
    ok: bool
    error: utf8
    output: CompileOutput
}

micro empty_compile_output() -> CompileOutput {
    return CompileOutput {
        assembly_name: "",
        namespace_symbol: "",
        console_message: "",
        source_files: []
    }
}
