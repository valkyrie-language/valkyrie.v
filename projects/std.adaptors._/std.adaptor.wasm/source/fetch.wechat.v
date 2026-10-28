[when(target.vendor == "wechat")]
namespace std.adaptor.wasm.fetch;

[js_builtin("wx.request")]
micro wx_request(url: utf16, options: i32): i32

[host_provider(std::net::get)]
[js("wx.request")]
micro get(url: utf8): utf8 {
    let host_url: utf16 = utf8_to_utf16(url)
    let handle: i32 = wx_request(host_url, 0)
    let response: utf16 = response_text(handle)
    return utf16_to_utf8(response)
}
