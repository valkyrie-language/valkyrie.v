namespace container.oci;

using std.data::{data_diagnostic_code};
using std.diagnostic::{Diagnostic};

micro oci_layout_test_has_code(diagnostics: [Diagnostic], code: utf8) -> bool {
    let mut index: usize = 0
    while index < diagnostics.length() {
        if data_diagnostic_code(std::collection::array::get(diagnostics, index)) == code {
            return true
        }
        index = index + 1
    }
    return false
}

micro oci_layout_test_minimal_root() -> utf8 {
    return "test-fixtures/minimal-image"
}

micro oci_layout_test_broken_root() -> utf8 {
    return "test-fixtures/broken-image"
}

# 合法最小镜像：oci-layout / index.json / blobs/ 齐全。
[test]
micro test_layout_minimal_image_structure_ok() -> unit {
    let diagnostics = oci_layout_validate_structure(oci_layout_test_minimal_root())
    if diagnostics.length() != 0 {
        panic("minimal image layout must be structurally valid")
    }
}

# 残缺镜像：缺 oci-layout 与 blobs/。
[test]
micro test_layout_broken_image_reports_missing_layout_and_blobs() -> unit {
    let diagnostics = oci_layout_validate_structure(oci_layout_test_broken_root())
    if !oci_layout_test_has_code(diagnostics, "oci.layout.missing_layout_file") {
        panic("broken image must report missing_layout_file")
    }
    if !oci_layout_test_has_code(diagnostics, "oci.layout.missing_blobs_directory") {
        panic("broken image must report missing_blobs_directory")
    }
}

# 根目录不存在。
[test]
micro test_layout_missing_root_reports_error() -> unit {
    let diagnostics = oci_layout_validate_structure("test-fixtures/does-not-exist")
    if !oci_layout_test_has_code(diagnostics, "oci.layout.missing_root") {
        panic("non-existent root must report missing_root")
    }
}

# 描述符引用的 blob 存在性校验（minimal-image 含空串 sha256 blob）。
[test]
micro test_layout_descriptor_blob_exists_in_minimal_image() -> unit {
    let digest = Digest {
        algorithm: "sha256",
        encoded: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    }
    let descriptor: Descriptor = Descriptor {
        media_type: oci_media_type_layer_tar(),
        digest: digest,
        size: 0,
        annotations: [],
        platform: None
    }
    let diagnostics = oci_layout_validate_descriptor_blobs(oci_layout_test_minimal_root(), [descriptor])
    if diagnostics.length() != 0 {
        panic("referenced blob must exist in minimal image")
    }
}
