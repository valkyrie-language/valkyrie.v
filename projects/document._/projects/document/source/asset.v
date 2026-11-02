namespace document;

# 资源表：图片/字体/附件的身份、去重与 base 解析（纯函数）。
#
# - R9 绝对路径原样：以 `/` 开头，或以盘符（ASCII 字母 + `:`）开头。
# - R10 相对路径：`base` + `/` + `source` 字符串拼接，随后做 `/` 重复折叠与末尾 `/` 去除。
# - R11 v0 不解析 `.`/`..`（边界，不做字符串魔法）。
# - R12 去重：`resolved` 相同且 `kind` 相同 ⇒ 已存在则原样返回。
# 核心不做 IO：读文件、取网络、探测 MIME 全是 host capability，归消费侧。

enums AssetKind {
    Image
    Font
    Attachment
}

structure AssetEntry {
    kind: AssetKind
    source: utf8
    resolved: utf8
}

structure AssetTable {
    entries: [AssetEntry]
}

micro asset_kind_tag(kind: AssetKind) -> i32 {
    match kind {
        case Image:
            return 0
        case Font:
            return 1
        case Attachment:
            return 2
    }
}

micro empty_asset_table() -> AssetTable {
    return AssetTable {
        entries: []
    }
}

# R9：绝对路径判定。`/` 开头，或 ASCII 字母 + `:` 的盘符开头。
micro asset_path_is_absolute(source: utf8) -> bool {
    let length: usize = source.length()
    if length >= 1 && source[1] == '/' {
        return true
    }
    if length >= 2 && source[2] == ':' {
        let letter: u32 = source[1] as u32
        if letter >= 65 && letter <= 90 {
            return true
        }
        if letter >= 97 && letter <= 122 {
            return true
        }
    }
    return false
}

# R10 折叠：逐字符扫描重建，跳过与前一个输出字符重复的 `/`，纯函数无 host 依赖。
micro asset_collapse_slashes(text: utf8) -> utf8 {
    let mut out: utf8 = ""
    let mut previous_was_slash: bool = false
    let mut position: usize = 1
    let length: usize = text.length()
    while position <= length {
        let current: char = text[position]
        if current == '/' {
            if !previous_was_slash {
                out = out + std::text::encode_char_as_utf8(current)
            }
            previous_was_slash = true
        } else {
            out = out + std::text::encode_char_as_utf8(current)
            previous_was_slash = false
        }
        position = position + 1
    }
    return out
}

# R10 末尾 `/` 去除；保留根形态的单独 `/`（折叠后长度大于 1 时才剥）。
micro asset_strip_trailing_slash(text: utf8) -> utf8 {
    let mut out: utf8 = text
    let mut length: usize = out.length()
    while length > 1 && out[length] == '/' {
        out = out.slice(0, length - 1)
        length = out.length()
    }
    return out
}

micro asset_resolve(source: utf8, base: utf8) -> utf8 {
    if asset_path_is_absolute(source) {
        return source
    }
    let joined: utf8 = base + "/" + source
    return asset_strip_trailing_slash(asset_collapse_slashes(joined))
}

micro asset_register(table: AssetTable, kind: AssetKind, source: utf8, base: utf8) -> AssetTable {
    let resolved: utf8 = asset_resolve(source, base)
    let mut index: usize = 0
    while index < table.entries.length() {
        let entry: AssetEntry = table.entries⁅index⁆
        if entry.resolved.equals(resolved) && asset_kind_tag(entry.kind) == asset_kind_tag(kind) {
            return table
        }
        index = index + 1
    }
    return AssetTable {
        entries: push(table.entries, AssetEntry {
            kind: kind,
            source: source,
            resolved: resolved
        })
    }
}

# 查资源：按 `resolved` + `kind` 精确命中。
micro asset_table_find(table: AssetTable, kind: AssetKind, resolved: utf8) -> Option<AssetEntry> {
    let mut index: usize = 0
    while index < table.entries.length() {
        let entry: AssetEntry = table.entries⁅index⁆
        if entry.resolved.equals(resolved) && asset_kind_tag(entry.kind) == asset_kind_tag(kind) {
            return Some(entry)
        }
        index = index + 1
    }
    return None
}
