# std.adaptor.windows: UTF-16 text host_provider
# 本后端未提供 UTF-16 字符串操作宿主原语；本包只绑定 `length`
# （码元计数，读取 `Utf16Text` 的码元数组载体，与 std 契约口径一致）。
# 其余能力不在这里绑定占位 provider：未交付能力由 std 宿主契约显式失败，
# 不以成功函数体冒充。

namespace std.adaptor.windows.text;

[host_provider(std::text::Utf16Text::length)]
micro host_length(value: std.text.utf16): usize {
    return value._repr.length
}
