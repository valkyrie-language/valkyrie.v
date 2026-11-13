# Asgard UI wire 解码 smoke（legion test）

using asgard.ui.wire;
using asgard.ui.ir;
using std.types::{Fine, Fail};

[test]
micro `decode empty is empty`() {
    let components: Result<[UiComponent], std.text::Utf8DecodeError> = decode_package([])
    match components {
        case Fine(loaded):
            if loaded.length != 0 {
                panic("decode_package([]) should be empty")
            }
        case Fail(error):
            panic("decode_package([]) must not fail")
    }
}

[test]
micro `find section empty is empty`() {
    let section: [u8] = find_asgard_ui_section([])
    if section.length != 0 {
        panic("find on empty container should be empty")
    }
}

[test]
micro `header magic alone is not a package`() {
    # ASGARDUI (8 bytes) alone — too short for a valid package body
    let data: [u8] = [0x41, 0x53, 0x47, 0x41, 0x52, 0x44, 0x55, 0x49]
    let components: Result<[UiComponent], std.text::Utf8DecodeError> = decode_package(data)
    match components {
        case Fine(loaded):
            if loaded.length != 0 {
                panic("magic-only payload should not decode components")
            }
        case Fail(error):
            panic("magic-only payload must decode to empty, not fail")
    }
}

[test]
micro `empty package with magic and zero count`() {
    # ASGARDUI + u32 LE component_count = 0
    let data: [u8] = [
        0x41, 0x53, 0x47, 0x41, 0x52, 0x44, 0x55, 0x49,
        0x00, 0x00, 0x00, 0x00
    ]
    let components: Result<[UiComponent], std.text::Utf8DecodeError> = decode_package(data)
    match components {
        case Fine(loaded):
            if loaded.length != 0 {
                panic("zero-count package should yield empty component list")
            }
        case Fail(error):
            panic("zero-count package must not fail")
    }
}
