namespace container;

# Reference：镜像引用 `name[:tag][@digest]`，解析与规范化。
#
# 规范化规则：
# - name 可含 `/` 分隔的段（registry/namespace/repo），必须非空、不含 `@` 与 `:`。
# - tag 与 digest 至少给其一；都不给视为歧义（container.reference.ambiguous）。
# - digest 用文法层解析（algorithm agility）。
# 解析失败是硬失败（ReferenceFailure）。

structure Reference {
    name: utf8
    tag: Option<utf8>
    digest: Option<Digest>
}

micro container_reference_name(name: utf8) -> Reference {
    return Reference { name: name, tag: None, digest: None }
}

micro container_reference_new(name: utf8, tag: Option<utf8>, digest: Option<Digest>) -> Reference {
    return Reference { name: name, tag: tag, digest: digest }
}

micro container_reference_is_valid_name(name: utf8) -> bool {
    if name.length() == 0 {
        return false
    }
    let mut index: usize = 0
    while index < name.length() {
        # name 不允许含 '@' 与 ':'。
        if name⁅index⁆ == '@' || name⁅index⁆ == ':' {
            return false
        }
        index = index + 1
    }
    return true
}

# 规范化：`name:tag` 或 `name@digest` 或 `name`（歧义）。
# 这里只做结构与规范化，不做 registry 解析。
micro container_reference_parse_tagged(name: utf8, tag: utf8) -> Reference {
    if !container_reference_is_valid_name(name) {
        container_failure_raise_reference("container.reference.invalid", "非法 name：" + name)
    }
    if tag.length() == 0 {
        container_failure_raise_reference("container.reference.invalid", "空 tag")
    }
    return Reference { name: name, tag: Some(tag), digest: None }
}

micro container_reference_parse_digested(name: utf8, digest_text: utf8) -> Reference {
    if !container_reference_is_valid_name(name) {
        container_failure_raise_reference("container.reference.invalid", "非法 name：" + name)
    }
    let parsed = data_outcome_value(container_digest_parse(digest_text))
    if parsed.algorithm.length() == 0 {
        container_failure_raise_reference("container.reference.invalid", "非法 digest：" + digest_text)
    }
    return Reference { name: name, tag: None, digest: Some(parsed) }
}

micro container_reference_to_string(reference: Reference) -> utf8 {
    let mut text: utf8 = reference.name
    match reference.tag {
        case Some(tag):
            text = text + ":" + tag
        case None:
            text = text
    }
    match reference.digest {
        case Some(digest):
            text = text + "@" + container_digest_to_string(digest)
        case None:
            text = text
    }
    return text
}
