# WASI lane 的 `std.fs` 字节合同占位绑定。
#
# 与 `std.io` 文本合同同口径：在 `wasi:filesystem/*` Canonical ABI 齐备前，
# 用纯 guest 占位，不合成虚假 wasi 导入；字节面诚实返回空/失败，
# 真实读写在占位期不可用。

namespace std.adaptor.wasi.fs;

[host_provider(std::fs::exists)]
micro exists(path: utf8) -> bool {
    return false
}

[host_provider(std::fs::read_bytes)]
micro read_bytes(path: utf8) -> [u8] {
    return []
}

[host_provider(std::fs::write_bytes)]
micro write_bytes(path: utf8, bytes: [u8]) -> bool {
    return false
}
