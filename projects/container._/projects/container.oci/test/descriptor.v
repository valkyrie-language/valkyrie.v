namespace container.oci;

using std.data::{data_outcome_value_or};

micro oci_descriptor_test_sha256_zeros() -> utf8 {
    return "0000000000000000000000000000000000000000000000000000000000000000"
}

[test]
micro test_descriptor_construction_and_blob_path() -> unit {
    let digest = data_outcome_value_or(oci_digest_parse("sha256:" + oci_descriptor_test_sha256_zeros()), Digest { algorithm: "", encoded: "" })
    let descriptor: Descriptor = Descriptor {
        media_type: oci_media_type_layer_tar(),
        digest: digest,
        size: 42,
        annotations: [],
        platform: None
    }
    if descriptor.size != 42 {
        panic("descriptor size mismatch")
    }
    if descriptor.media_type != oci_media_type_layer_tar() {
        panic("descriptor media type mismatch")
    }
    let expected_path: utf8 = "blobs/sha256/" + oci_descriptor_test_sha256_zeros()
    if oci_blob_relative_path(descriptor.digest) != expected_path {
        panic("descriptor blob path mismatch")
    }
}

[test]
micro test_descriptor_empty_detector() -> unit {
    let empty_descriptor: Descriptor = Descriptor {
        media_type: "",
        digest: Digest { algorithm: "", encoded: "" },
        size: 0,
        annotations: [],
        platform: None
    }
    if !oci_descriptor_is_empty(empty_descriptor) {
        panic("zero descriptor must be empty")
    }
    let digest = data_outcome_value_or(oci_digest_parse("sha256:" + oci_descriptor_test_sha256_zeros()), Digest { algorithm: "", encoded: "" })
    let non_empty: Descriptor = Descriptor {
        media_type: oci_media_type_layer_tar(),
        digest: digest,
        size: 1,
        annotations: [],
        platform: None
    }
    if oci_descriptor_is_empty(non_empty) {
        panic("non-zero descriptor must not be empty")
    }
}

[test]
micro test_image_index_construction() -> unit {
    let index: ImageIndex = ImageIndex {
        schema_version: oci_schema_version_image(),
        media_type: oci_media_type_image_index(),
        manifests: [],
        subject: None,
        annotations: []
    }
    if index.schema_version != 2 {
        panic("image index schema version must be 2")
    }
    if index.media_type != oci_media_type_image_index() {
        panic("image index media type mismatch")
    }
}

[test]
micro test_image_layout_marker_version() -> unit {
    if oci_layout_version_supported() != "1.0.0" {
        panic("supported oci-layout version must be 1.0.0")
    }
}
