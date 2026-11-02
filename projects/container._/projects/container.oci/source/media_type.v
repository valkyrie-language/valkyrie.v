namespace container.oci;

using container::{MediaTypeRegistration, container_media_registry_empty, container_media_register, container_media_kind_is, MediaLayer, MediaManifestFamily, MediaConfigFamily};

# OCI image-spec media type（image-spec media-types.md）。
# 字符串常量保留在本包；分类判断委托核心注册表，不硬编码字符串分支。

micro oci_media_type_image_index() -> utf8 {
    return "application/vnd.oci.image.index.v1+json"
}

micro oci_media_type_image_manifest() -> utf8 {
    return "application/vnd.oci.image.manifest.v1+json"
}

micro oci_media_type_image_config() -> utf8 {
    return "application/vnd.oci.image.config.v1+json"
}

micro oci_media_type_layer_tar() -> utf8 {
    return "application/vnd.oci.image.layer.v1.tar"
}

micro oci_media_type_layer_tar_gzip() -> utf8 {
    return "application/vnd.oci.image.layer.v1.tar+gzip"
}

micro oci_media_type_layer_tar_zstd() -> utf8 {
    return "application/vnd.oci.image.layer.v1.tar+zstd"
}

micro oci_media_type_empty_json() -> utf8 {
    return "application/vnd.oci.empty.v1+json"
}

# Docker v2 兼容面：识别外来镜像用，本实现不输出这些类型。
micro docker_media_type_manifest_v2() -> utf8 {
    return "application/vnd.docker.distribution.manifest.v2+json"
}

micro docker_media_type_config() -> utf8 {
    return "application/vnd.docker.container.image.v1+json"
}

micro docker_media_type_layer_tar_gzip() -> utf8 {
    return "application/vnd.docker.image.rootfs.diff.tar.gzip"
}

# 把 OCI + Docker 兼容面注册进共享注册表。
micro oci_media_registry() -> [MediaTypeRegistration] {
    let registry: [MediaTypeRegistration] = container_media_register(container_media_registry_empty(), oci_media_type_layer_tar(), MediaLayer)
    let registry: [MediaTypeRegistration] = container_media_register(registry, oci_media_type_layer_tar_gzip(), MediaLayer)
    let registry: [MediaTypeRegistration] = container_media_register(registry, oci_media_type_layer_tar_zstd(), MediaLayer)
    let registry: [MediaTypeRegistration] = container_media_register(registry, docker_media_type_layer_tar_gzip(), MediaLayer)
    let registry: [MediaTypeRegistration] = container_media_register(registry, oci_media_type_image_index(), MediaManifestFamily)
    let registry: [MediaTypeRegistration] = container_media_register(registry, oci_media_type_image_manifest(), MediaManifestFamily)
    let registry: [MediaTypeRegistration] = container_media_register(registry, docker_media_type_manifest_v2(), MediaManifestFamily)
    let registry: [MediaTypeRegistration] = container_media_register(registry, oci_media_type_image_config(), MediaConfigFamily)
    return container_media_register(registry, docker_media_type_config(), MediaConfigFamily)
}

micro oci_media_type_is_layer(media_type: utf8) -> bool {
    return container_media_kind_is(media_type, oci_media_registry(), MediaLayer)
}

micro oci_media_type_is_manifest_family(media_type: utf8) -> bool {
    return container_media_kind_is(media_type, oci_media_registry(), MediaManifestFamily)
}

micro oci_media_type_is_config_family(media_type: utf8) -> bool {
    return container_media_kind_is(media_type, oci_media_registry(), MediaConfigFamily)
}
