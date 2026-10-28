[when(target.specification == "browser")]
namespace std.adaptor.wasm.fetch;

[host_provider(std::net::get)]
micro get(url: utf8): utf8 {
    let host_url: utf16 = utf8_to_utf16(url)
    let handle: i32 = http_fetch(host_url)
    let response: utf16 = response_text(handle)
    return utf16_to_utf8(response)
}

[host_provider(std::net::post)]
micro post(url: utf8, body: utf8): utf8 {
    let host_url: utf16 = utf8_to_utf16(url)
    let handle: i32 = http_fetch(host_url)
    let response: utf16 = response_text(handle)
    return utf16_to_utf8(response)
}

[host_provider(std::net::put)]
micro put(url: utf8, body: utf8): utf8 {
    let host_url: utf16 = utf8_to_utf16(url)
    let handle: i32 = http_fetch(host_url)
    let response: utf16 = response_text(handle)
    return utf16_to_utf8(response)
}

[host_provider(std::net::delete)]
micro delete(url: utf8): utf8 {
    let host_url: utf16 = utf8_to_utf16(url)
    let handle: i32 = http_fetch(host_url)
    let response: utf16 = response_text(handle)
    return utf16_to_utf8(response)
}
