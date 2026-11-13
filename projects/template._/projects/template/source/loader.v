namespace template;

using std.diagnostic::{Diagnostic, Error, diagnostic_code, new_diagnostic, new_span};
using std.data::{DataOutcome, data_outcome_diagnostics, data_outcome_failed, data_outcome_has_errors, data_outcome_of, data_outcome_partial, data_outcome_value_or};

# 加载段（纯策略）：模板引用 -> 源条目命中。模板源访问一律经 source.v 的
# 窄接口（待 虚拟文件系统层（待定案） 落地后替换其实现）；本文件不含目录实现假设。
#
# path-v1（策略合同）：
# - 引用三态：scheme（`<root>:<path>`）、相对（`./`/`../` 前缀）、裸路径。
# - 反斜杠规格化为 `/`；空段与 `.` 段折叠；`..` 弹一段，越过根即越界。
# - 规范 id：`root:path`（path 不带前导 `/`）。
# - 扩展探测序：原文、`.html`、`.dejavu`。
# - 裸路径按 root `priority` 降序探测，首个命中 root 胜出。
#
# root 目前只支持 `memory` 形态；其他形态（文件/网络等宿主能力源）
# 一律 fail-closed 产 `template.loader.host_capability`，不尝试任何 IO。

# 解析命中的源位：规范 id + 源条目下标。
structure TemplateResolution {
    canonical: utf8
    entry: usize
}

unite TemplateRefKind {
    RefScheme
    RefRelative
    RefBare
}

structure TemplateRef {
    kind: TemplateRefKind
    scheme: utf8
    path: utf8
}

# 段规格化产出：折叠后的段序列 + 是否发生越根 `..`。
structure TemplateSegments {
    segments: [utf8]
    escaped: bool
}

micro template_loader_failure(code: utf8, message: utf8) -> DataOutcome<TemplateResolution> {
    let mut diagnostics: [Diagnostic] = []
    diagnostics = push(diagnostics, new_diagnostic(code, Error, message, new_span(0, 0)))
    return data_outcome_failed(diagnostics)
}

# ── 引用分类 ──

micro template_classify_ref(reference: utf8) -> DataOutcome<TemplateRef> {
    if reference.length() == 0 {
        let mut diagnostics: [Diagnostic] = []
        diagnostics = push(diagnostics, new_diagnostic("template.loader.invalid_ref", Error, "模板引用为空", new_span(0, 0)))
        return data_outcome_failed(diagnostics)
    }
    if template_text_has_prefix(reference, "./") || template_text_has_prefix(reference, "../") {
        return data_outcome_of(TemplateRef { kind: RefRelative, scheme: "", path: template_normalize_separators(reference) })
    }
    let first: char = reference⁅0⁆
    if template_char_is_alpha(first) {
        let mut cursor: usize = 1
        let mut scanning: bool = true
        while scanning && cursor < reference.length() {
            let c: char = reference⁅cursor⁆
            if c == ':' {
                let scheme: utf8 = reference.slice(0, cursor)
                let path: utf8 = reference.slice(cursor + 1, reference.length() - cursor - 1)
                return data_outcome_of(TemplateRef { kind: RefScheme, scheme: scheme, path: template_normalize_separators(path) })
            }
            if template_char_is_scheme_tail(c) {
                cursor = cursor + 1
            }
            else {
                scanning = false
            }
        }
    }
    return data_outcome_of(TemplateRef { kind: RefBare, scheme: "", path: template_normalize_separators(reference) })
}

# ── 解析 ──

# `from_canonical` 为当前模板规范 id（相对引用的基准）；无基准传空串。
micro template_resolve(reference: utf8, from_canonical: utf8, catalog: TemplateCatalog) -> DataOutcome<TemplateResolution> {
    let classified: DataOutcome<TemplateRef> = template_classify_ref(reference)
    if data_outcome_has_errors(classified) {
        let failed: [Diagnostic] = data_outcome_diagnostics(classified)
        return data_outcome_failed(failed)
    }
    let fallback: TemplateRef = TemplateRef { kind: RefBare, scheme: "", path: "" }
    let reference_form: TemplateRef = data_outcome_value_or(classified, fallback)
    let kind: TemplateRefKind = reference_form.kind
    match kind {
        case RefScheme:
            return template_resolve_scheme(reference_form, catalog)
        case RefRelative:
            return template_resolve_relative(reference_form, from_canonical, catalog)
        case RefBare:
            return template_resolve_bare(reference_form, catalog)
    }
}

micro template_resolve_scheme(reference_form: TemplateRef, catalog: TemplateCatalog) -> DataOutcome<TemplateResolution> {
    let root: TemplateRoot? = template_source_root(catalog, reference_form.scheme)
    if root.is_none() {
        return template_loader_failure("template.loader.unknown_scheme", "未知模板根: " + reference_form.scheme)
    }
    let normalized: TemplateSegments = template_normalize_segments(template_split_segments(reference_form.path))
    if normalized.escaped {
        return template_loader_failure("template.loader.relative_escape_root", "模板引用越过根")
    }
    return template_probe_root(root.unwrap(), template_join_segments(normalized.segments), catalog)
}

micro template_resolve_relative(reference_form: TemplateRef, from_canonical: utf8, catalog: TemplateCatalog) -> DataOutcome<TemplateResolution> {
    if from_canonical.length() == 0 {
        return template_loader_failure("template.loader.relative_without_from", "相对模板引用缺少基准模板")
    }
    let colon: usize = template_text_index_of(from_canonical, ":")
    if colon == 0 {
        return template_loader_failure("template.loader.invalid_ref", "基准模板规范 id 形态非法")
    }
    let root_name: utf8 = from_canonical.slice(0, colon)
    let from_path: utf8 = from_canonical.slice(colon + 1, from_canonical.length() - colon - 1)
    let root: TemplateRoot? = template_source_root(catalog, root_name)
    if root.is_none() {
        return template_loader_failure("template.loader.unknown_scheme", "未知模板根: " + root_name)
    }
    # 基准目录 = 基准路径去末段。
    let base_segments: [utf8] = template_drop_last(template_split_segments(from_path))
    let combined: [utf8] = template_concat_text(base_segments, template_split_segments(reference_form.path))
    let normalized: TemplateSegments = template_normalize_segments(combined)
    if normalized.escaped {
        return template_loader_failure("template.loader.relative_escape_root", "模板引用越过根")
    }
    return template_probe_root(root.unwrap(), template_join_segments(normalized.segments), catalog)
}

micro template_resolve_bare(reference_form: TemplateRef, catalog: TemplateCatalog) -> DataOutcome<TemplateResolution> {
    let normalized: TemplateSegments = template_normalize_segments(template_split_segments(reference_form.path))
    if normalized.escaped {
        return template_loader_failure("template.loader.relative_escape_root", "模板引用越过根")
    }
    let path: utf8 = template_join_segments(normalized.segments)
    let ordered: [TemplateRoot] = template_roots_by_priority(catalog)
    let mut index: usize = 0
    while index < ordered.length() {
        let probed: DataOutcome<TemplateResolution> = template_probe_root(ordered⁅index⁆.unwrap(), path, catalog)
        if !template_resolution_is_not_found(probed) {
            return probed
        }
        index = index + 1
    }
    return template_loader_failure("template.loader.template_not_found", "模板未找到: " + path)
}

# 单 root 探测：扩展序 原文、`.html`、`.dejavu`；非 memory root fail-closed。
micro template_probe_root(root: TemplateRoot, path: utf8, catalog: TemplateCatalog) -> DataOutcome<TemplateResolution> {
    if root.kind != "memory" {
        return template_loader_failure("template.loader.host_capability", "模板根需要宿主能力: " + root.name)
    }
    let probes: [utf8] = ["", ".html", ".dejavu"]
    let mut index: usize = 0
    while index < probes.length() {
        let candidate: utf8 = path + probes⁅index⁆.unwrap()
        let entry: usize? = template_source_probe(catalog, root.name, candidate)
        if entry.is_some() {
            let resolution: TemplateResolution = TemplateResolution { canonical: root.name + ":" + candidate, entry: entry.unwrap() }
            return data_outcome_of(resolution)
        }
        index = index + 1
    }
    return template_loader_failure("template.loader.template_not_found", "模板未找到: " + root.name + ":" + path)
}

# not_found 之外的失败（host_capability 等）直接上抛，不继续探测下一 root。
micro template_resolution_is_not_found(outcome: DataOutcome<TemplateResolution>) -> bool {
    let diagnostics: [Diagnostic] = data_outcome_diagnostics(outcome)
    let mut index: usize = 0
    while index < diagnostics.length() {
        if diagnostic_code(diagnostics⁅index⁆.unwrap()) != "template.loader.template_not_found" {
            return false
        }
        index = index + 1
    }
    return diagnostics.length() > 0
}

# ── 策略侧源访问（经 source.v 窄接口）──

# priority 降序（插入排序，root 数小）。
micro template_roots_by_priority(catalog: TemplateCatalog) -> [TemplateRoot] {
    let roots: [TemplateRoot] = template_source_roots(catalog)
    let mut ordered: [TemplateRoot] = []
    let mut index: usize = 0
    while index < roots.length() {
        let root: TemplateRoot = roots⁅index⁆.unwrap()
        let mut position: usize = ordered.length()
        let mut cursor: usize = 0
        while cursor < ordered.length() {
            if ordered⁅cursor⁆.unwrap().priority < root.priority && position == ordered.length() {
                position = cursor
            }
            cursor = cursor + 1
        }
        ordered = template_insert_root(ordered, position, root)
        index = index + 1
    }
    return ordered
}

micro template_insert_root(items: [TemplateRoot], position: usize, root: TemplateRoot) -> [TemplateRoot] {
    let mut result: [TemplateRoot] = []
    let mut index: usize = 0
    while index < items.length() {
        if index == position {
            result = push(result, root)
        }
        result = push(result, items⁅index⁆.unwrap())
        index = index + 1
    }
    if position >= items.length() {
        result = push(result, root)
    }
    return result
}

# ── 路径文本原语 ──

micro template_normalize_separators(text: utf8) -> utf8 {
    let mut output: utf8 = ""
    let mut index: usize = 0
    while index < text.length() {
        let c: char = text⁅index⁆
        if c == r'\' {
            output = output + "/"
        }
        else {
            output = output + text.slice(index, 1)
        }
        index = index + 1
    }
    return output
}

micro template_split_segments(path: utf8) -> [utf8] {
    let mut segments: [utf8] = []
    let mut start: usize = 0
    let mut index: usize = 0
    while index < path.length() {
        if path⁅index⁆ == '/' {
            segments = push(segments, path.slice(start, index - start))
            start = index + 1
        }
        index = index + 1
    }
    segments = push(segments, path.slice(start, path.length() - start))
    return segments
}

micro template_join_segments(segments: [utf8]) -> utf8 {
    let mut output: utf8 = ""
    let mut index: usize = 0
    while index < segments.length() {
        if index > 0 {
            output = output + "/"
        }
        output = output + segments⁅index⁆.unwrap()
        index = index + 1
    }
    return output
}

micro template_normalize_segments(raw: [utf8]) -> TemplateSegments {
    let mut stack: [utf8] = []
    let mut escaped: bool = false
    let mut index: usize = 0
    while index < raw.length() {
        let segment: utf8 = raw⁅index⁆.unwrap()
        if segment.length() == 0 || segment == "." {
            # 空段与 `.` 段折叠。
        }
        else {
            if segment == ".." {
                if stack.length() == 0 {
                    escaped = true
                }
                else {
                    stack = template_drop_last(stack)
                }
            }
            else {
                stack = push(stack, segment)
            }
        }
        index = index + 1
    }
    return TemplateSegments { segments: stack, escaped: escaped }
}

micro template_drop_last(items: [utf8]) -> [utf8] {
    let mut result: [utf8] = []
    let mut index: usize = 0
    while index + 1 < items.length() {
        result = push(result, items⁅index⁆.unwrap())
        index = index + 1
    }
    return result
}

micro template_concat_text(first: [utf8], second: [utf8]) -> [utf8] {
    let mut result: [utf8] = first
    let mut index: usize = 0
    while index < second.length() {
        result = push(result, second⁅index⁆.unwrap())
        index = index + 1
    }
    return result
}

micro template_text_has_prefix(text: utf8, prefix: utf8) -> bool {
    if text.length() < prefix.length() {
        return false
    }
    let mut index: usize = 0
    while index < prefix.length() {
        if text⁅index⁆ != prefix⁅index⁆ {
            return false
        }
        index = index + 1
    }
    return true
}

# 首个命中下标；未命中返回文本长度（调用点按 `== 0`/`>= length` 判）。
micro template_text_index_of(text: utf8, needle: utf8) -> usize {
    if needle.length() == 0 {
        return 0
    }
    let mut index: usize = 0
    while index + needle.length() <= text.length() {
        if text.slice(index, needle.length()) == needle {
            return index
        }
        index = index + 1
    }
    return text.length()
}

micro template_char_is_alpha(c: char) -> bool {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

micro template_char_is_scheme_tail(c: char) -> bool {
    if template_char_is_alpha(c) {
        return true
    }
    if c >= '0' && c <= '9' {
        return true
    }
    return c == '+' || c == '-' || c == '.'
}
