# std.adaptor.ovm: UTF-8 文本操作 [ovm] 宿主绑定
# 将 valkyrie-core 的 UTF-8 文本操作映射为 OVM opcode
# OVM 内部文本表示为 UTF-8 编码

#region utf8 操作

[ovm("utf8.concat")]
micro utf8_concat(a: utf8, b: utf8): utf8

[ovm("utf8.length_bytes")]
micro utf8_length_bytes(s: utf8): usize

[ovm("utf8.length_chars")]
micro utf8_length_chars(s: utf8): usize

[ovm("utf8.slice")]
micro utf8_slice(s: utf8, start: usize, length: usize): utf8

[ovm("utf8.eq")]
micro utf8_eq(a: utf8, b: utf8): bool

[ovm("utf8.ne")]
micro utf8_ne(a: utf8, b: utf8): bool

#endregion
