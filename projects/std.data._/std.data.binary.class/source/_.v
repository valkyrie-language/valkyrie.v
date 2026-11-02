namespace std.data.binary.`class`;

# Minimal ClassFile encode surface used by `nyar.emitter.jvm`.
# Full isomorphic port of Rust `std-data::binary::class` is a later slice;
# Node/Wasm seed only needs the symbol to resolve in the workspace closure.

structure JvmEncodedMethod {
    name: utf8
    descriptor: utf8
    max_stack: u16
    max_locals: u16
    code_bytes: [i32]
}

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};

# 诊断类型收敛到 `std.diagnostic::Diagnostic`（统一合同，不再各自定义）。
# 旧轨包：诊断码表随错误容许改造补齐，暂以单码占位。

[tag(ClassBinaryResultKind)]
unite ClassBinaryResult<T> {
    [tag(0)]
    Fine { value: T }
    [tag(1)]
    Fail { error: Diagnostic }
}

micro class_binary_diagnostic(message: utf8, offset: usize) -> Diagnostic {
    return new_diagnostic("std.data.binary.class.defect", Error, message, new_span(offset, offset))
}

# Encode a ClassFile from method plans + constant-pool string/class/methodref tables.
# Stub: returns empty bytes until the full encoder is ported; callers must treat
# empty as "encode not ready" rather than a valid empty class.
micro jvm_encode_classfile_with_methods(
    binary_name: utf8,
    methods: [JvmEncodedMethod],
    string_texts: [utf8],
    string_utf8_indices: [u16],
    class_names: [utf8],
    invoke_owners: [utf8],
    invoke_names: [utf8],
    invoke_descs: [utf8],
    invoke_owner_ords: [u16]
) -> [i32] {
    let _ = binary_name
    let _ = methods
    let _ = string_texts
    let _ = string_utf8_indices
    let _ = class_names
    let _ = invoke_owners
    let _ = invoke_names
    let _ = invoke_descs
    let _ = invoke_owner_ords
    return []
}
