namespace container.oci;

using container::{Digest};

# OCI Descriptor（image-spec descriptor.md）：核心 Descriptor + spec 注解与平台。

structure Annotation {
    key: utf8
    value: utf8
}

structure Platform {
    architecture: utf8
    os: utf8
    os_version: Option<utf8>
    variant: Option<utf8>
}

# OCI 描述符：在核心三要素之上补 annotations / platform。
structure Descriptor {
    media_type: utf8
    digest: Digest
    size: i64
    annotations: [Annotation]
    platform: Option<Platform>
}

micro oci_descriptor_is_empty(descriptor: Descriptor) -> bool {
    return descriptor.size == 0
        && descriptor.digest.algorithm == ""
        && descriptor.digest.encoded == ""
}
