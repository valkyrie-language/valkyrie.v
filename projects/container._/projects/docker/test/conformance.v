namespace container.docker;

using container::{
    MemoryContentStore, Descriptor, container_digest_equals, container_digest_algorithm_sha256,
    container_conformance_bytes_of, container_conformance_abc_sha256
};

# docker conformance：跑同一套核心用例（共享 MemoryContentStore 实现）。

[test]
micro test_docker_conformance_digest_consistency() -> unit {
    let bytes: [u8] = container_conformance_bytes_of("abc")
    let mut store: MemoryContentStore = docker_shared_store_new()
    let descriptor: Descriptor = store.put("application/vnd.docker.image.rootfs.diff.tar.gzip", bytes)
    if descriptor.digest.encoded != container_conformance_abc_sha256() {
        panic("docker store digest must equal known answer")
    }
}

[test]
micro test_docker_conformance_blob_dedup() -> unit {
    let bytes: [u8] = container_conformance_bytes_of("docker-dedup")
    let mut store: MemoryContentStore = docker_shared_store_new()
    let first: Descriptor = store.put("application/vnd.docker.image.rootfs.diff.tar.gzip", bytes)
    let second: Descriptor = store.put("application/vnd.docker.image.rootfs.diff.tar.gzip", bytes)
    if !container_digest_equals(first.digest, second.digest) {
        panic("identical bytes must dedup")
    }
}

[test]
micro test_docker_media_registry_classifies() -> unit {
    let registry = docker_media_registry()
    if !container::container_media_kind_is(docker_media_type_layer_tar_gzip(), registry, container::MediaLayer) {
        panic("docker layer must classify as layer")
    }
    if !container::container_media_kind_is(docker_media_type_config(), registry, container::MediaConfigFamily) {
        panic("docker config must classify as config family")
    }
}
