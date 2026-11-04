namespace std.text.test;

using std.text::Utf8Text;

# `utf8` 的 `Comparable`：字节序（内部 UTF-8 编码字节的字典序），
# 前缀关系以长度决胜，不引入区域规则、大小写折叠或 Unicode 规范化。

[test]
micro `test utf8 comparable byte order`() {
    let abc: Utf8Text = Utf8Text::from_bytes([97 as u8, 98 as u8, 99 as u8])
    let abd: Utf8Text = Utf8Text::from_bytes([97 as u8, 98 as u8, 100 as u8])
    let prefix: Utf8Text = Utf8Text::from_bytes([97 as u8, 98 as u8])
    let upper: Utf8Text = Utf8Text::from_bytes([90 as u8])
    let lower: Utf8Text = Utf8Text::from_bytes([97 as u8])

    if !(abc < abd) {
        panic("utf8 byte order less test failed")
    }

    if abc >= abd {
        panic("utf8 byte order not greater test failed")
    }

    if !(prefix < abc) {
        panic("utf8 prefix shorter test failed")
    }

    if !(abc > prefix) {
        panic("utf8 prefix longer test failed")
    }

    # 0x5A < 0x61：字节序下 `Z` 在 `a` 之前，不做大小写折叠。
    if !(upper < lower) {
        panic("utf8 byte order case folding test failed")
    }

    if abc.compare(abd).to_code() != -1 {
        panic("utf8 compare Less test failed")
    }

    if prefix.compare(abc).to_code() != -1 {
        panic("utf8 compare prefix Less test failed")
    }

    if abc.compare(abc).to_code() != 0 {
        panic("utf8 compare Equal test failed")
    }

    if abd.compare(abc).to_code() != 1 {
        panic("utf8 compare Greater test failed")
    }
}
