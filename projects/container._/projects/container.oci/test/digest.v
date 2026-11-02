namespace container.oci;

using std.data::{data_diagnostic_code, data_outcome_diagnostics, data_outcome_has_errors, data_outcome_value_or};
using std.diagnostic::{Diagnostic};

# 64 个 '0'，合法 sha256 编码段。
micro oci_digest_test_sha256_zeros() -> utf8 {
    return "0000000000000000000000000000000000000000000000000000000000000000"
}

# `data_outcome_value_or` 的回退值：解析失败时返回空 digest。
micro oci_digest_test_empty_digest() -> Digest {
    return Digest { algorithm: "", encoded: "" }
}

micro oci_digest_test_has_code(diagnostics: [Diagnostic], code: utf8) -> bool {
    let mut index: usize = 0
    while index < diagnostics.length() {
        if data_diagnostic_code(std::collection::array::get(diagnostics, index)) == code {
            return true
        }
        index = index + 1
    }
    return false
}

[test]
micro test_digest_parse_sha256_ok() -> unit {
    let text: utf8 = "sha256:" + oci_digest_test_sha256_zeros()
    let outcome = oci_digest_parse(text)
    if data_outcome_has_errors(outcome) {
        panic("valid sha256 digest must parse without error")
    }
    let digest = data_outcome_value_or(outcome, oci_digest_test_empty_digest())
    if digest.algorithm != "sha256" {
        panic("algorithm mismatch")
    }
    if digest.encoded != oci_digest_test_sha256_zeros() {
        panic("encoded mismatch")
    }
}

[test]
micro test_digest_validate_registered_sha256_ok() -> unit {
    let outcome = oci_digest_parse("sha256:" + oci_digest_test_sha256_zeros())
    let digest = data_outcome_value_or(outcome, oci_digest_test_empty_digest())
    let validated = oci_digest_validate_registered(digest)
    if data_outcome_has_errors(validated) {
        panic("registered sha256 must validate")
    }
}

[test]
micro test_digest_parse_missing_separator() -> unit {
    let outcome = oci_digest_parse("sha256" + oci_digest_test_sha256_zeros())
    if !data_outcome_has_errors(outcome) {
        panic("missing separator must error")
    }
    if !oci_digest_test_has_code(data_outcome_diagnostics(outcome), "container.digest.missing_separator") {
        panic("must report missing_separator")
    }
}

[test]
micro test_digest_parse_empty_algorithm() -> unit {
    let outcome = oci_digest_parse(":" + oci_digest_test_sha256_zeros())
    if !oci_digest_test_has_code(data_outcome_diagnostics(outcome), "container.digest.empty_algorithm") {
        panic("must report empty_algorithm")
    }
}

[test]
micro test_digest_parse_empty_encoded() -> unit {
    let outcome = oci_digest_parse("sha256:")
    if !oci_digest_test_has_code(data_outcome_diagnostics(outcome), "container.digest.empty_encoded") {
        panic("must report empty_encoded")
    }
}

[test]
micro test_digest_parse_bad_algorithm_character() -> unit {
    let outcome = oci_digest_parse("SHA256:" + oci_digest_test_sha256_zeros())
    if !oci_digest_test_has_code(data_outcome_diagnostics(outcome), "container.digest.bad_algorithm_character") {
        panic("uppercase algorithm must report bad_algorithm_character")
    }
}

[test]
micro test_digest_parse_bad_encoded_character() -> unit {
    let outcome = oci_digest_parse("sha256:????????????????????????????????????????????????????????????????")
    if !oci_digest_test_has_code(data_outcome_diagnostics(outcome), "container.digest.bad_encoded_character") {
        panic("non-charset encoded chars must report bad_encoded_character")
    }
}

[test]
micro test_digest_validate_unsupported_algorithm() -> unit {
    let outcome = oci_digest_parse("blake3:" + oci_digest_test_sha256_zeros())
    if data_outcome_has_errors(outcome) {
        panic("blake3 should pass generic grammar")
    }
    let validated = oci_digest_validate_registered(data_outcome_value_or(outcome, oci_digest_test_empty_digest()))
    if !oci_digest_test_has_code(data_outcome_diagnostics(validated), "container.digest.unsupported_algorithm") {
        panic("unregistered algorithm must report unsupported_algorithm")
    }
}

[test]
micro test_digest_validate_bad_length() -> unit {
    let outcome = oci_digest_parse("sha256:0000")
    let validated = oci_digest_validate_registered(data_outcome_value_or(outcome, oci_digest_test_empty_digest()))
    if !oci_digest_test_has_code(data_outcome_diagnostics(validated), "container.digest.bad_encoded_length") {
        panic("wrong length must report bad_encoded_length")
    }
}

[test]
micro test_digest_validate_uppercase_rejected() -> unit {
    let mut encoded: utf8 = ""
    let mut index: usize = 0
    while index < 64 {
        encoded = encoded + "A"
        index = index + 1
    }
    let outcome = oci_digest_parse("sha256:" + encoded)
    if data_outcome_has_errors(outcome) {
        panic("uppercase should pass generic grammar")
    }
    let validated = oci_digest_validate_registered(data_outcome_value_or(outcome, oci_digest_test_empty_digest()))
    if !oci_digest_test_has_code(data_outcome_diagnostics(validated), "container.digest.bad_encoded_case") {
        panic("uppercase must report bad_encoded_case")
    }
}

[test]
micro test_digest_round_trip_and_blob_path() -> unit {
    let text: utf8 = "sha256:" + oci_digest_test_sha256_zeros()
    let digest = data_outcome_value_or(oci_digest_parse(text), oci_digest_test_empty_digest())
    if oci_digest_to_string(digest) != text {
        panic("digest round-trip must equal input")
    }
    let expected_path: utf8 = "blobs/sha256/" + oci_digest_test_sha256_zeros()
    if oci_blob_relative_path(digest) != expected_path {
        panic("blob relative path mismatch")
    }
}

[test]
micro test_digest_equals() -> unit {
    let left = data_outcome_value_or(oci_digest_parse("sha256:" + oci_digest_test_sha256_zeros()), oci_digest_test_empty_digest())
    let right = data_outcome_value_or(oci_digest_parse("sha256:" + oci_digest_test_sha256_zeros()), oci_digest_test_empty_digest())
    if !oci_digest_equals(left, right) {
        panic("same digest must be equal")
    }
}
