namespace container;

# Image / ImageConfig（核心通用字段：env、entrypoint/cmd、ports、volumes、workdir、labels）。
#
# 与 OCI `ImageConfiguration` 的区别：核心是运行时无关的镜像配置通用面；
# OCI 的 history/rootfs.diff_ids 等 spec 字段留在 `container.oci` 扩展。

structure PortBinding {
    port: i64
    protocol: utf8
}

structure Label {
    key: utf8
    value: utf8
}

structure ImageConfig {
    environment: [utf8]
    entrypoint: [utf8]
    command: [utf8]
    exposed_ports: [PortBinding]
    volumes: [utf8]
    working_directory: utf8
    labels: [Label]
}

micro container_image_config_empty() -> ImageConfig {
    return ImageConfig {
        environment: [],
        entrypoint: [],
        command: [],
        exposed_ports: [],
        volumes: [],
        working_directory: "",
        labels: []
    }
}

# Image：config + 层链（rootfs）。
structure Image {
    config: ImageConfig
    layers: LayerChain
}
