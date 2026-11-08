namespace std.adaptor.macos.text;

[host_provider(std::text::Utf16Text::length)]
micro host_length(value: std.text.utf16): usize {
    return value._repr.length
}

[host_provider(std::text::Utf16Text::slice)]
micro host_slice(value: std.text.utf16, start: usize, count: usize): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::concat)]
micro host_concat(value: std.text.utf16, other: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::contains)]
micro host_contains(value: std.text.utf16, other: std.text.utf16): bool {
    return false
}

[host_provider(std::text::Utf16Text::starts_with)]
micro host_starts_with(value: std.text.utf16, prefix: std.text.utf16): bool {
    return false
}

[host_provider(std::text::Utf16Text::ends_with)]
micro host_ends_with(value: std.text.utf16, suffix: std.text.utf16): bool {
    return false
}

[host_provider(std::text::Utf16Text::index_of)]
micro host_index_of(value: std.text.utf16, other: std.text.utf16): Option<usize> {
    return None
}

[host_provider(std::text::Utf16Text::trim)]
micro host_trim(value: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::to_lower)]
micro host_to_lower(value: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::to_upper)]
micro host_to_upper(value: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::replace)]
micro host_replace(value: std.text.utf16, old_value: std.text.utf16, new_value: std.text.utf16): std.text.utf16 {
    return value
}

[host_provider(std::text::Utf16Text::equals)]
micro host_equals(value: std.text.utf16, other: std.text.utf16): bool {
    return false
}
