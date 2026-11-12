namespace std.adaptor.wasm.crypto;

using std.adaptor.wasm.text::{utf16_to_utf8};
using std.types::{Result, Fine};
using std.crypto::{RandomSourceError};

# std.web_sdk: Crypto API
# [js_builtin] 直接映射 JS 内置 Crypto API，无依赖
# JS 字符串内部为 UTF-16，所有字符串参数标注为 utf16
#
# `random_bytes` 不在此绑定：`crypto.getRandomValues` 需要宿主侧可写
# 字节缓冲，而宿主序列入参合同（01 §4.15）未交付——缺 provider 的目标
# 在计划阶段对 `std::crypto::random_bytes` 显式失败，不以指针 0 或空串
# 冒充字节数据。

[host_provider(std::crypto::random_uuid)]
micro random_uuid(): Result<utf8, RandomSourceError> {
    let host_value: utf16 = crypto_uuid()
    return Fine { value: utf16_to_utf8(host_value) }
}

#region 随机值

[js_builtin("crypto.randomUUID")]
micro crypto_uuid(): utf16

#endregion
