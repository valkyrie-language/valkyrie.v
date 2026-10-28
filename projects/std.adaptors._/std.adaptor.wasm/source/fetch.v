# std.adaptor.wasm.fetch — 公共 JS 内置视图与 helper（无平台 provider）
namespace std.adaptor.wasm.fetch;

#region 请求

[js_builtin("fetch")]
micro http_fetch(url: utf16): i32

[js_builtin("Request")]
micro http_request(url: utf16, options: i32): i32

#endregion

#region 响应

[js_builtin("Response.json")]
micro response_json(handle: i32): i32

[js_builtin("Response.text")]
micro response_text(handle: i32): utf16

[js_builtin("Response.ok")]
micro response_ok(handle: i32): i32

[js_builtin("Response.status")]
micro response_status(handle: i32): i32

[js_builtin("Response.headers")]
micro response_headers(handle: i32): i32

#endregion

#region Headers

[js_builtin("Headers")]
micro headers_new(): i32

[js_builtin("Headers.append")]
micro headers_append(handle: i32, name: utf16, value: utf16): unit

[js_builtin("Headers.get")]
micro headers_get(handle: i32, name: utf16): utf16

#endregion
