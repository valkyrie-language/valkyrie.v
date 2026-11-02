namespace document;

[test]
micro asset_absolute_paths_stay_untouched() -> unit {
    let table: AssetTable = asset_register(empty_asset_table(), Image, "/pictures/a.png", "/docs/guide")
    if table.entries.length() != 1 {
        panic("entry registered")
    }
    if !table.entries⁅0⁆.resolved.equals("/pictures/a.png") {
        panic("absolute path resolves to itself")
    }

    let with_drive: AssetTable = asset_register(empty_asset_table(), Image, "D:/pictures/a.png", "/docs/guide")
    if !with_drive.entries⁅0⁆.resolved.equals("D:/pictures/a.png") {
        panic("drive letter path is absolute")
    }
}

[test]
micro asset_relative_paths_join_base_and_collapse() -> unit {
    let table: AssetTable = asset_register(empty_asset_table(), Image, "images//a.png", "/docs/guide/")
    if table.entries.length() != 1 {
        panic("entry registered")
    }
    if !table.entries⁅0⁆.resolved.equals("/docs/guide/images/a.png") {
        panic("relative path joins base with slash folding")
    }
}

[test]
micro asset_resolution_strips_trailing_slash() -> unit {
    let resolved: utf8 = asset_resolve("images/", "/docs")
    if !resolved.equals("/docs/images") {
        panic("trailing slash is stripped")
    }
}

[test]
micro asset_register_dedupes_same_kind_and_resolved() -> unit {
    let first: AssetTable = asset_register(empty_asset_table(), Image, "a.png", "/docs")
    let second: AssetTable = asset_register(first, Image, "a.png", "/docs")
    if second.entries.length() != 1 {
        panic("same kind and resolved path dedupes")
    }

    let other_kind: AssetTable = asset_register(second, Font, "a.png", "/docs")
    if other_kind.entries.length() != 2 {
        panic("different kind with same resolved path is a new entry")
    }

    let other_source: AssetTable = asset_register(other_kind, Image, "b.png", "/docs")
    if other_source.entries.length() != 3 {
        panic("different resolved path is a new entry")
    }
}

[test]
micro asset_find_matches_kind_and_resolved() -> unit {
    let table: AssetTable = asset_register(empty_asset_table(), Attachment, "pack.zip", "/files")
    let found: Option<AssetEntry> = asset_table_find(table, Attachment, "/files/pack.zip")
    if found.is_none() {
        panic("registered asset resolves")
    }
    if !found.unwrap().source.equals("pack.zip") {
        panic("entry keeps original source")
    }
    if asset_table_find(table, Image, "/files/pack.zip").is_some() {
        panic("kind mismatch misses")
    }
}
