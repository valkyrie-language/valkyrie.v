namespace container;

# Media type 注册表：新类型经注册加入，**不硬编码字符串分支**。
#
# 每个注册项标注 `kind`（layer / manifest-family / config-family / other），
# 分类判断遍历注册表按 kind 匹配，而非 if-else 比对具体字符串。
# `container_oci` / `container_docker` 各自把规范 media type 注册进同一注册表，
# 核心不内置任何具体类型。

unite MediaTypeKind {
    MediaLayer
    MediaManifestFamily
    MediaConfigFamily
    MediaOther
}

structure MediaTypeRegistration {
    media_type: utf8
    kind: MediaTypeKind
}

micro container_media_registry_empty() -> [MediaTypeRegistration] {
    return []
}

micro container_media_register(registry: [MediaTypeRegistration], media_type: utf8, kind: MediaTypeKind) -> [MediaTypeRegistration] {
    return push(registry, MediaTypeRegistration { media_type: media_type, kind: kind })
}

micro container_media_lookup(registry: [MediaTypeRegistration], media_type: utf8) -> Option<MediaTypeRegistration> {
    let mut index: usize = 0
    while index < registry.length() {
        let registration = std::collection::array::get(registry, index)
        if registration.media_type == media_type {
            return Some(registration)
        }
        index = index + 1
    }
    return None
}

micro container_media_kind_is(media_type: utf8, registry: [MediaTypeRegistration], wanted: MediaTypeKind) -> bool {
    let found: Option<MediaTypeRegistration> = container_media_lookup(registry, media_type)
    match found {
        case None:
            false
        case Some(registration): {
            match registration.kind {
                case MediaLayer: {
                    match wanted {
                        case MediaLayer: true
                        case MediaManifestFamily: false
                        case MediaConfigFamily: false
                        case MediaOther: false
                    }
                }
                case MediaManifestFamily: {
                    match wanted {
                        case MediaLayer: false
                        case MediaManifestFamily: true
                        case MediaConfigFamily: false
                        case MediaOther: false
                    }
                }
                case MediaConfigFamily: {
                    match wanted {
                        case MediaLayer: false
                        case MediaManifestFamily: false
                        case MediaConfigFamily: true
                        case MediaOther: false
                    }
                }
                case MediaOther: {
                    match wanted {
                        case MediaLayer: false
                        case MediaManifestFamily: false
                        case MediaConfigFamily: false
                        case MediaOther: true
                    }
                }
            }
        }
    }
}
