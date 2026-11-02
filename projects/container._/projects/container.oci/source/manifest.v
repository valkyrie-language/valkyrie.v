namespace container.oci;

# OCI Image Manifest / Config / Index（image-spec manifest.md / config.md / image-index.md）。
# 复用核心 Digest 与 OCI 描述符；spec 专属字段（schemaVersion、history、rootfs）在此。

structure ImageManifest {
    schema_version: i64
    media_type: utf8
    configuration: Descriptor
    layers: [Descriptor]
    subject: Option<Descriptor>
    annotations: [Annotation]
}

# image-spec schemaVersion（manifest / index 均为 2）。
micro oci_schema_version_image() -> i64 {
    return 2
}

structure HistoryEntry {
    created: Option<utf8>
    created_by: utf8
    empty_layer: bool
    comment: utf8
}

# OCI Image Config（image-spec config.md）：rootfs.diff_ids 与 history 是 spec 专属。
structure ImageConfiguration {
    architecture: utf8
    os: utf8
    created: Option<utf8>
    author: Option<utf8>
    environment: [utf8]
    entrypoint: [utf8]
    command: [utf8]
    working_directory: utf8
    labels: [Annotation]
    rootfs_type: utf8
    diff_ids: [container::Digest]
    history: [HistoryEntry]
}

structure ImageIndex {
    schema_version: i64
    media_type: utf8
    manifests: [Descriptor]
    subject: Option<Descriptor>
    annotations: [Annotation]
}

# `oci-layout` 标记文件内容模型（image-spec image-layout.md）。
structure ImageLayoutMarker {
    version: utf8
}

# 当前实现支持的 oci-layout 版本。
micro oci_layout_version_supported() -> utf8 {
    return "1.0.0"
}
