namespace std.data;

[test]
micro test_settings_fingerprint_changes_with_fields() -> unit {
    let base: usize = data_settings_fingerprint(new_data_settings(64, 7))
    if base != data_settings_fingerprint(new_data_settings(64, 7)) {
        panic("same settings must give same fingerprint")
    }
    if base == data_settings_fingerprint(new_data_settings(32, 7)) {
        panic("max_depth must participate in fingerprint")
    }
    if base == data_settings_fingerprint(new_data_settings(64, 8)) {
        panic("extension fingerprint must participate in fingerprint")
    }
}

[test]
micro test_cache_hit_and_miss_semantics() -> unit {
    let settings: DataSettings = new_data_settings(64, 7)
    let fingerprint: usize = data_settings_fingerprint(settings)
    let source: DataSource = data_source_from_text("# Title")
    let digest: usize = data_source_digest(source)

    let empty: DataCache<usize> = data_cache_empty::<usize>()
    if data_cache_matches(empty, digest, fingerprint) {
        panic("empty cache must never hit")
    }

    let stored: DataCache<usize> = data_cache_store(digest, fingerprint, 42)
    if !data_cache_matches(stored, digest, fingerprint) {
        panic("same source and settings must hit")
    }
    match data_cache_value(stored) {
        case Filled(payload):
            if payload.value != 42 {
                panic("hit must return stored value")
            }
        case Empty:
            panic("hit must fill the slot")
    }

    let other_source: DataSource = data_source_from_text("# Other")
    if data_cache_matches(stored, data_source_digest(other_source), fingerprint) {
        panic("changed source digest must miss")
    }
    if data_cache_matches(stored, digest, data_settings_fingerprint(new_data_settings(64, 8))) {
        panic("changed settings fingerprint must miss")
    }
}
