namespace std.data;

[test]
micro test_data_text_digest_is_stable_and_sensitive() -> unit {
    let first: usize = data_text_digest("# Title\n")
    let second: usize = data_text_digest("# Title\n")
    if first != second {
        panic("same content must give same digest")
    }
    let different: usize = data_text_digest("# Title!\n")
    if first == different {
        panic("different content must give different digest")
    }
}

[test]
micro test_data_bytes_digest_is_stable_and_sensitive() -> unit {
    let bytes: [u8] = [77, 97, 114, 107]
    let first: usize = data_bytes_digest(bytes)
    let second: usize = data_bytes_digest([77, 97, 114, 107])
    if first != second {
        panic("same bytes must give same digest")
    }
    let different: usize = data_bytes_digest([77, 97, 114, 33])
    if first == different {
        panic("different bytes must give different digest")
    }
}

[test]
micro test_data_source_carries_digest_and_length() -> unit {
    let text_source: DataSource = data_source_from_text("hello")
    if data_source_digest(text_source) != data_text_digest("hello") {
        panic("text source digest mismatch")
    }
    if data_source_length(text_source) != 5 {
        panic("text source length should count characters")
    }
    let byte_source: DataSource = data_source_from_bytes([1, 2, 3])
    if data_source_digest(byte_source) != data_bytes_digest([1, 2, 3]) {
        panic("byte source digest mismatch")
    }
    if data_source_length(byte_source) != 3 {
        panic("byte source length should count bytes")
    }
    let identity: DataSourceIdentity = data_source_identity(text_source, "example.md")
    if identity.content_digest != data_source_digest(text_source) {
        panic("identity digest must equal source digest")
    }
}
