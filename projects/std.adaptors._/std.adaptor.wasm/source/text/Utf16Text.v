# std.adaptor.wasm: UTF-16 文本 host_provider
# Node/Wasm 路径上 utf16 是宿主字符串；不得假设 `_repr` 字节/码元数组布局。

namespace std.adaptor.wasm.text;

[host_provider(std::text::Utf16Text::length)]
micro host_length(value: std.text.utf16): isize {
    return __host_utf16_length(value)
}

[host_provider(std::text::Utf16Text::sub_string)]
micro host_sub_string(value: std.text.utf16, start: isize, count: isize): std.text.utf16 {
    return __host_utf16_slice(value, start, count)
}

[host_provider(std::text::Utf16Text::concat)]
micro host_concat(value: std.text.utf16, other: std.text.utf16): std.text.utf16 {
    return __host_utf16_concat(value, other)
}

[host_provider(std::text::Utf16Text::contains)]
micro host_contains(value: std.text.utf16, other: std.text.utf16): bool {
    return __host_utf16_contains(value, other)
}

[host_provider(std::text::Utf16Text::starts_with)]
micro host_starts_with(value: std.text.utf16, prefix: std.text.utf16): bool {
    return __host_utf16_starts_with(value, prefix)
}

[host_provider(std::text::Utf16Text::ends_with)]
micro host_ends_with(value: std.text.utf16, suffix: std.text.utf16): bool {
    return __host_utf16_ends_with(value, suffix)
}

[host_provider(std::text::Utf16Text::index_of)]
micro host_index_of(value: std.text.utf16, other: std.text.utf16): isize {
    return __host_utf16_index_of(value, other)
}

[host_provider(std::text::Utf16Text::trim)]
micro host_trim(value: std.text.utf16): std.text.utf16 {
    return __host_utf16_trim(value)
}

[host_provider(std::text::Utf16Text::to_lower)]
micro host_to_lower(value: std.text.utf16): std.text.utf16 {
    return __host_utf16_to_lower(value)
}

[host_provider(std::text::Utf16Text::to_upper)]
micro host_to_upper(value: std.text.utf16): std.text.utf16 {
    return __host_utf16_to_upper(value)
}

[host_provider(std::text::Utf16Text::replace)]
micro host_replace(value: std.text.utf16, old_value: std.text.utf16, new_value: std.text.utf16): std.text.utf16 {
    return __host_utf16_replace(value, old_value, new_value)
}

[host_provider(std::text::Utf16Text::equals)]
micro host_equals(value: std.text.utf16, other: std.text.utf16): bool {
    return __host_utf16_equals(value, other)
}

[host_provider(std::text::Utf16Text::char_at)]
micro host_char_at(value: std.text.utf16, index: isize): u16 {
    return __host_utf16_char_at(value, index)
}

[wasm("env", "utf16_length")]
private micro __host_utf16_length(s: utf16): isize

[wasm("env", "utf16_slice")]
private micro __host_utf16_slice(s: utf16, start: isize, count: isize): utf16

[wasm("env", "utf16_concat")]
private micro __host_utf16_concat(a: utf16, b: utf16): utf16

[wasm("env", "utf16_contains")]
private micro __host_utf16_contains(s: utf16, other: utf16): bool

[wasm("env", "utf16_starts_with")]
private micro __host_utf16_starts_with(s: utf16, prefix: utf16): bool

[wasm("env", "utf16_ends_with")]
private micro __host_utf16_ends_with(s: utf16, suffix: utf16): bool

[wasm("env", "utf16_index_of")]
private micro __host_utf16_index_of(s: utf16, other: utf16): isize

[wasm("env", "utf16_trim")]
private micro __host_utf16_trim(s: utf16): utf16

[wasm("env", "utf16_to_lower")]
private micro __host_utf16_to_lower(s: utf16): utf16

[wasm("env", "utf16_to_upper")]
private micro __host_utf16_to_upper(s: utf16): utf16

[wasm("env", "utf16_replace")]
private micro __host_utf16_replace(s: utf16, old_value: utf16, new_value: utf16): utf16

[wasm("env", "utf16_equals")]
private micro __host_utf16_equals(a: utf16, b: utf16): bool

[wasm("env", "utf16_char_at")]
private micro __host_utf16_char_at(s: utf16, index: isize): u16
