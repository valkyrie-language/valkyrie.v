# std.adaptor.wasm: 编码转换 host 绑定
# Node/Wasm 路径上 console / print / fetch 需要 utf8 → 宿主 utf16。
# 声明落在本包，禁止依赖 std.adaptor.ovm 的 [vm] 符号跨 adaptor 猜解析。

namespace std.adaptor.wasm.text;

[wasm("env", "utf8_to_utf16")]
micro utf8_to_utf16(s: utf8): utf16

[wasm("env", "utf16_to_utf8")]
micro utf16_to_utf8(s: utf16): utf8
