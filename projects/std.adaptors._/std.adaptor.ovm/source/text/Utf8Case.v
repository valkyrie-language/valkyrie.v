# std.adaptor.ovm：UTF-8 大小写映射的 [ovm] 宿主绑定。
# std 只保留 `to_lower` / `to_upper` 签名；语义固定在 `unicode.case`（UCD 16.0.0），
# 不随 std 版本漂移。这里只做转发，不在 adaptor 内重复实现映射逻辑。
# `case` 是语言保留字，`unicode::case::…` 表达式路径不可解析，按仓内既有约定用 `using`。

using unicode.case::{text_to_lower, text_to_upper};

[host_provider(std::text::Utf8Text::to_lower)]
micro host_to_lower(value: std.text.utf8): std.text.utf8 {
    return text_to_lower(value)
}

[host_provider(std::text::Utf8Text::to_upper)]
micro host_to_upper(value: std.text.utf8): std.text.utf8 {
    return text_to_upper(value)
}
