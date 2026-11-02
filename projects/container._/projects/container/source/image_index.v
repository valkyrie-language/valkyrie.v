namespace container;

# ImageIndex / manifest 骨架（核心通用）：schemaVersion + mediaType + 描述符列表。
#
# OCI 的 `manifests` 数组语义、平台匹配、subject/annotations 等 spec 细节
# 留在 `container.oci` 扩展；核心只承载"一个 index 指向若干 descriptor"的骨架。

structure ImageIndexSkeleton {
    schema_version: i64
    media_type: utf8
    manifests: [Descriptor]
}

micro container_image_index_skeleton_new(schema_version: i64, media_type: utf8, manifests: [Descriptor]) -> ImageIndexSkeleton {
    return ImageIndexSkeleton { schema_version: schema_version, media_type: media_type, manifests: manifests }
}
