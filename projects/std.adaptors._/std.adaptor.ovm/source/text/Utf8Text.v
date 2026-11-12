# std.adaptor.ovm: UTF-8 文本操作 [ovm] 宿主绑定
# 将 valkyrie-core 的 UTF-8 文本操作映射为 OVM opcode
# OVM 内部文本表示为 UTF-8 编码
# 作者面索引单位是 Unicode 标量（码点），合同类型为 `usize`；VM 的 32 位整数
# 槽只出现在本 provider 内部——窄化在这一层完成，不回写 std 合同。
# `utf8.slice` 第三个参数是 **count**（从 start 起取多少个标量），不是 end。

#region utf8 操作

[ovm("utf8.concat")]
micro utf8_concat(a: utf8, b: utf8): utf8

[ovm("utf8.length_bytes")]
micro utf8_length_bytes(s: utf8): i32

[ovm("utf8.length_chars")]
micro utf8_length_chars(s: utf8): i32

[ovm("utf8.slice")]
micro utf8_slice(s: utf8, start: i32, count: i32): utf8

[ovm("utf8.eq")]
micro utf8_eq(a: utf8, b: utf8): bool

[ovm("utf8.ne")]
micro utf8_ne(a: utf8, b: utf8): bool

#endregion

#region 严格切片 provider

# 宿主层严格：越界区间由 VM `utf8.slice` 结构化失败。
# std 的 `slice` 是总函数，负责先 clamp 再调本 provider；`try_slice` 先判定再调用。
[host_provider(std::text::Utf8Text::host_slice)]
micro host_slice(value: std.text.utf8, start: usize, count: usize): std.text.utf8 {
    return utf8_slice(value, start as i32, count as i32)
}

#endregion
