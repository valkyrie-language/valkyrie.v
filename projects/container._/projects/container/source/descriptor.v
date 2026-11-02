namespace container;

# Descriptor：digest + media type + size 的内容寻址引用（核心通用，不含 spec 注解）。

structure Descriptor {
    media_type: utf8
    digest: Digest
    size: i64
}

micro container_descriptor_new(media_type: utf8, digest: Digest, size: i64) -> Descriptor {
    return Descriptor { media_type: media_type, digest: digest, size: size }
}

micro container_descriptor_is_empty(descriptor: Descriptor) -> bool {
    return descriptor.size == 0
        && descriptor.digest.algorithm == ""
        && descriptor.digest.encoded == ""
}
