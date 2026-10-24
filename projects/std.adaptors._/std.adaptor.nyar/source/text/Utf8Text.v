# std.adaptor.nyar: UTF-8 文本操作 [ovm] 宿主绑定
# 将 valkyrie-core 的 UTF-8 文本操作映射为 NyarVM opcode
# NyarVM 内部文本表示为 UTF-8 编码

#region utf8 操作

[ovm("utf8_concat")]
micro utf8_concat(a: utf8, b: utf8): utf8

[ovm("utf8_length_bytes")]
micro utf8_length_bytes(s: utf8): i32

[ovm("utf8_length_chars")]
micro utf8_length_chars(s: utf8): i32

[ovm("utf8_substr")]
micro utf8_substr(s: utf8, start: i32, length: i32): utf8

[ovm("utf8_eq")]
micro utf8_eq(a: utf8, b: utf8): bool

[ovm("utf8_ne")]
micro utf8_ne(a: utf8, b: utf8): bool

#endregion
