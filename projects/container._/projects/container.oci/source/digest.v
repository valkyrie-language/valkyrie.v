namespace container.oci;

using container::{Digest};
using std.data::{DataOutcome};

# OCI digest 文法校验：复用 container 核心的两层校验，oci 不再重复实现。
# 保留 `oci_digest_parse` / `oci_digest_validate_registered` 名（algorithm agility 与
# 注册层能力不变），委托 `container_digest_parse` / `container_digest_validate_registered`。

micro oci_digest_algorithm_sha256() -> utf8 {
    return "sha256"
}

micro oci_digest_algorithm_sha512() -> utf8 {
    return "sha512"
}

micro oci_digest_parse(text: utf8) -> DataOutcome<Digest> {
    return container::container_digest_parse(text)
}

micro oci_digest_validate_registered(digest: Digest) -> DataOutcome<Digest> {
    return container::container_digest_validate_registered(digest)
}

micro oci_digest_equals(left: Digest, right: Digest) -> bool {
    return container::container_digest_equals(left, right)
}

micro oci_digest_to_string(digest: Digest) -> utf8 {
    return container::container_digest_to_string(digest)
}

micro oci_blobs_directory_name() -> utf8 {
    return "blobs"
}

micro oci_blob_relative_path(digest: Digest) -> utf8 {
    return oci_blobs_directory_name() + "/" + digest.algorithm + "/" + digest.encoded
}
