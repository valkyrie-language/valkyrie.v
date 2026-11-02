namespace oci;

using std.data::{DataDiagnostic, Error, new_data_diagnostic, new_data_span};
using std.io::{directory_exists, file_exists, read_file_text};

# OCI Image Layout（image-spec image-layout.md）目录结构校验。
#
# 结构元素：
#   <root>/oci-layout          JSON 标记，含 imageLayoutVersion
#   <root>/index.json          image index（多平台入口）
#   <root>/blobs/<algo>/<hex>  内容寻址 blob
#
# 内容解析（oci-layout 版本字段、index.json 结构）依赖 std.data.text.json（尚未落地）；
# 本模块只做结构存在性与 oci-layout 版本字符串包含检查，不解析 JSON。
# blob 内容与摘要的一致性校验可经 container 核心 + std.data.digest（能力已具备），
# 本模块只查存在性。

micro oci_layout_marker_file_name() -> utf8 {
    return "oci-layout"
}

micro oci_layout_index_file_name() -> utf8 {
    return "index.json"
}

micro oci_layout_marker_path(root: utf8) -> utf8 {
    return root + "/" + oci_layout_marker_file_name()
}

micro oci_layout_index_path(root: utf8) -> utf8 {
    return root + "/" + oci_layout_index_file_name()
}

micro oci_layout_blobs_path(root: utf8) -> utf8 {
    return root + "/" + oci_blobs_directory_name()
}

micro oci_layout_blob_path(root: utf8, digest: Digest) -> utf8 {
    return root + "/" + oci_blob_relative_path(digest)
}

# 校验 image layout 结构：根目录、oci-layout、index.json、blobs/。
# oci-layout 版本仅做字符串包含检查（不解析 JSON）。
micro oci_layout_validate_structure(root: utf8) -> [DataDiagnostic] {
    let mut diagnostics: [DataDiagnostic] = []

    if !directory_exists(root) {
        diagnostics = push(diagnostics, new_data_diagnostic("oci.layout.missing_root", Error, "image layout 根目录不存在", new_data_span(0, 0)))
        return diagnostics
    }

    let marker_path: utf8 = oci_layout_marker_path(root)
    if !file_exists(marker_path) {
        diagnostics = push(diagnostics, new_data_diagnostic("oci.layout.missing_layout_file", Error, "缺少 oci-layout 标记文件", new_data_span(0, 0)))
    } else {
        let marker_text: utf8 = read_file_text(marker_path)
        if !marker_text.index_of(oci_layout_version_supported()).is_some() {
            diagnostics = push(diagnostics, new_data_diagnostic("oci.layout.unsupported_layout_version", Error, "oci-layout 版本不受支持", new_data_span(0, 0)))
        }
    }

    let index_path: utf8 = oci_layout_index_path(root)
    if !file_exists(index_path) {
        diagnostics = push(diagnostics, new_data_diagnostic("oci.layout.missing_index", Error, "缺少 index.json", new_data_span(0, 0)))
    }

    let blobs_path: utf8 = oci_layout_blobs_path(root)
    if !directory_exists(blobs_path) {
        diagnostics = push(diagnostics, new_data_diagnostic("oci.layout.missing_blobs_directory", Error, "缺少 blobs/ 目录", new_data_span(0, 0)))
    }

    return diagnostics
}

# 校验一组描述符引用的 blob 在 layout 中存在（不校验内容摘要一致性）。
micro oci_layout_validate_descriptor_blobs(root: utf8, descriptors: [Descriptor]) -> [DataDiagnostic] {
    let mut diagnostics: [DataDiagnostic] = []
    let mut index: usize = 0
    while index < descriptors.length() {
        let descriptor = std::collection::array::get(descriptors, index)
        let blob_path: utf8 = oci_layout_blob_path(root, descriptor.digest)
        if !file_exists(blob_path) {
            diagnostics = push(diagnostics, new_data_diagnostic("oci.layout.blob_missing", Error, "描述符引用的 blob 不存在", new_data_span(0, 0)))
        }
        index = index + 1
    }
    return diagnostics
}
