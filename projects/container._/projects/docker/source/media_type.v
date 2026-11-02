namespace container.docker;

using container::{MediaTypeRegistration, container_media_registry_empty, container_media_register, MediaLayer, MediaManifestFamily, MediaConfigFamily};

# Docker 规范 media type（注册进共享注册表，核心不硬编码）。

micro docker_media_type_manifest_v2() -> utf8 {
    return "application/vnd.docker.distribution.manifest.v2+json"
}

micro docker_media_type_config() -> utf8 {
    return "application/vnd.docker.container.image.v1+json"
}

micro docker_media_type_layer_tar_gzip() -> utf8 {
    return "application/vnd.docker.image.rootfs.diff.tar.gzip"
}

micro docker_media_registry() -> [MediaTypeRegistration] {
    let registry: [MediaTypeRegistration] = container_media_register(
        container_media_registry_empty(),
        docker_media_type_layer_tar_gzip(),
        MediaLayer
    )
    let registry2: [MediaTypeRegistration] = container_media_register(registry, docker_media_type_manifest_v2(), MediaManifestFamily)
    return container_media_register(registry2, docker_media_type_config(), MediaConfigFamily)
}
