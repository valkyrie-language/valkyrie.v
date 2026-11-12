[test]
micro `test utf8 text features`() {
    let value: utf8 = "hello"

    if value.is_empty() {
        panic("utf8 is_empty test failed")
    }

    if value.byte_length() != 5 {
        panic("utf8 byte_length test failed")
    }

    if value.length() != 5 {
        panic("utf8 length test failed")
    }

    if !value.contains("ell") {
        panic("utf8 contains test failed")
    }

    if !value.starts_with("he") {
        panic("utf8 starts_with test failed")
    }

    if !value.ends_with("lo") {
        panic("utf8 ends_with test failed")
    }

    if value.index_of("ll") != Some(2) {
        panic("utf8 index_of test failed")
    }

    let part: utf8 = value.slice(1, 3)
    if part.length() != 3 {
        panic("utf8 substring length test failed")
    }

    if !part.equals("ell") {
        panic("utf8 substring equals test failed")
    }

    let merged: utf8 = value.concat("!")
    if !merged.ends_with("!") {
        panic("utf8 concat test failed")
    }
}
