namespace container;

using std.data::{DataOutcome, data_outcome_partial};
using std.data.digest::{digest_sha256, digest_sha512, digest_hex_text};
using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};

# 内容寻址摘要（算法无关，算法族可扩展）。
#
# 分层：
# - 文法层 `container_digest_parse`：`<algorithm>:<encoded>` 分隔符、字符集、非空
#   （algorithm agility：未注册算法也可解析），错误容许，走 `DataOutcome` 诊断。
# - 注册层 `container_digest_validate_registered`：已注册算法的定长小写 hex。
# - 内容层 `container_digest_compute`：按算法对字节求摘要并 hex 编码；算法计算
#   **委托 `std.data.digest`**，本包只按算法名分发与拼接，绝不重写哈希。
#
# 算法族注册：`container_digest_algorithm_register` 把新算法（编码长度 + 是否 hex）
# 加入 `container.digest` 包内注册表；算法计算本体仍在 `std.data.digest`。
#
# 诊断 span 单位：码点偏移（digest 文法 ASCII-only，与字节一一对应）。

structure Digest {
    algorithm: utf8
    encoded: utf8
}

# 算法族注册项：编码段定长与小写 hex 约束。
structure DigestAlgorithmRegistration {
    algorithm: utf8
    encoded_length: usize
    lower_hex: bool
}

# 已注册算法表（包内私有；经 register/lookup 访问，不直接改）。
# 初始含 sha256 / sha512。
micro container_digest_registered_algorithms() -> [DigestAlgorithmRegistration] {
    return [
        DigestAlgorithmRegistration { algorithm: "sha256", encoded_length: 64, lower_hex: true },
        DigestAlgorithmRegistration { algorithm: "sha512", encoded_length: 128, lower_hex: true }
    ]
}

micro container_digest_algorithm_sha256() -> utf8 {
    return "sha256"
}

micro container_digest_algorithm_sha512() -> utf8 {
    return "sha512"
}

# 算法族扩展：向注册表追加新算法（算法计算本体须已存在于 `std.data.digest`）。
micro container_digest_algorithm_register(registrations: [DigestAlgorithmRegistration], registration: DigestAlgorithmRegistration) -> [DigestAlgorithmRegistration] {
    return push(registrations, registration)
}

micro container_digest_lookup_registration(registrations: [DigestAlgorithmRegistration], algorithm: utf8) -> Option<DigestAlgorithmRegistration> {
    let mut index: usize = 0
    while index < registrations.length() {
        let registration = std::collection::array::get(registrations, index)
        if registration.algorithm == algorithm {
            return Some(registration)
        }
        index = index + 1
    }
    return None
}

# 算法字符集：[a-z0-9] 与内部分隔符 [+._-]。
micro container_digest_is_algorithm_char(code_point: u32) -> bool {
    if code_point >= 'a' && code_point <= 'z' {
        return true
    }
    if code_point >= '0' && code_point <= '9' {
        return true
    }
    if code_point == '+' || code_point == '.' || code_point == '_' || code_point == '-' {
        return true
    }
    return false
}

# 通用编码字符集（base64url-ish + hex）：[0-9a-zA-Z=_-]。
micro container_digest_is_generic_encoded_char(code_point: u32) -> bool {
    if code_point >= 'a' && code_point <= 'z' {
        return true
    }
    if code_point >= 'A' && code_point <= 'Z' {
        return true
    }
    if code_point >= '0' && code_point <= '9' {
        return true
    }
    if code_point == '=' || code_point == '_' || code_point == '-' {
        return true
    }
    return false
}

# 小写 hex：[0-9a-f]。
micro container_digest_is_lower_hex(code_point: u32) -> bool {
    if code_point >= '0' && code_point <= '9' {
        return true
    }
    if code_point >= 'a' && code_point <= 'f' {
        return true
    }
    return false
}

# 文法层解析（错误容许）。算法名满足文法即接受（algorithm agility）。
micro container_digest_parse(text: utf8) -> DataOutcome<Digest> {
    let length: usize = text.length()
    if length == 0 {
        return data_outcome_partial(
            Digest { algorithm: "", encoded: "" },
            [new_diagnostic("container.digest.empty", Error, "digest 不能为空", new_span(0, 0))]
        )
    }

    let mut diagnostics: [Diagnostic] = []
    let mut separator: usize = 0
    let mut found: bool = false
    let mut index: usize = 0
    while index < length {
        if text⁅index⁆ == ':' {
            separator = index
            found = true
            break
        }
        index = index + 1
    }

    if !found {
        diagnostics = push(diagnostics, new_diagnostic("container.digest.missing_separator", Error, "digest 缺少 `:` 分隔符", new_span(0, length)))
        return data_outcome_partial(Digest { algorithm: "", encoded: "" }, diagnostics)
    }

    if separator == 0 {
        diagnostics = push(diagnostics, new_diagnostic("container.digest.empty_algorithm", Error, "digest 算法段为空", new_span(0, 0)))
    } else {
        index = 0
        while index < separator {
            if !container_digest_is_algorithm_char(text⁅index⁆ as u32) {
                diagnostics = push(diagnostics, new_diagnostic("container.digest.bad_algorithm_character", Error, "digest 算法段含非法字符", new_span(index, index + 1)))
            }
            index = index + 1
        }
    }

    let encoded_start: usize = separator + 1
    if encoded_start >= length {
        diagnostics = push(diagnostics, new_diagnostic("container.digest.empty_encoded", Error, "digest 编码段为空", new_span(length, length)))
    } else {
        index = encoded_start
        while index < length {
            if !container_digest_is_generic_encoded_char(text⁅index⁆ as u32) {
                diagnostics = push(diagnostics, new_diagnostic("container.digest.bad_encoded_character", Error, "digest 编码段含非法字符", new_span(index, index + 1)))
            }
            index = index + 1
        }
    }

    let algorithm: utf8 = text.slice(0, separator)
    let encoded: utf8 = text.slice(encoded_start, length - encoded_start)
    return data_outcome_partial(Digest { algorithm: algorithm, encoded: encoded }, diagnostics)
}

# 注册层校验（错误容许）：算法已注册则查编码长度与 hex 约束；未注册给 unsupported。
micro container_digest_validate_registered(digest: Digest) -> DataOutcome<Digest> {
    let registrations: [DigestAlgorithmRegistration] = container_digest_registered_algorithms()
    return container_digest_validate_with_registrations(registrations, digest)
}

micro container_digest_validate_with_registrations(registrations: [DigestAlgorithmRegistration], digest: Digest) -> DataOutcome<Digest> {
    let mut diagnostics: [Diagnostic] = []
    let algorithm: utf8 = digest.algorithm
    let encoded: utf8 = digest.encoded
    let encoded_length: usize = encoded.length()

    let found: Option<DigestAlgorithmRegistration> = container_digest_lookup_registration(registrations, algorithm)
    match found {
        case None: {
            diagnostics = push(diagnostics, new_diagnostic("container.digest.unsupported_algorithm", Error, "未注册的摘要算法", new_span(0, algorithm.length())))
            return data_outcome_partial(digest, diagnostics)
        }
        case Some(registration): {
            if encoded_length != registration.encoded_length {
                diagnostics = push(diagnostics, new_diagnostic("container.digest.bad_encoded_length", Error, "摘要编码段长度不符", new_span(0, encoded_length)))
            }
            if registration.lower_hex {
                let mut index: usize = 0
                while index < encoded_length {
                    let code_point: u32 = encoded⁅index⁆ as u32
                    if code_point >= 'A' && code_point <= 'Z' {
                        diagnostics = push(diagnostics, new_diagnostic("container.digest.bad_encoded_case", Error, "digest 编码段必须为小写", new_span(index, index + 1)))
                    } else if !container_digest_is_lower_hex(code_point) {
                        diagnostics = push(diagnostics, new_diagnostic("container.digest.bad_encoded_character", Error, "digest 编码段含非法字符", new_span(index, index + 1)))
                    }
                    index = index + 1
                }
            }
            return data_outcome_partial(digest, diagnostics)
        }
    }
}

# 内容层摘要：按算法对字节求摘要并 hex 编码。算法计算委托 `std.data.digest`；
# 未注册算法 raise 硬失败（container.integrity.unknown_algorithm）。
micro container_digest_compute(algorithm: utf8, bytes: [u8]) -> utf8 {
    if algorithm == container_digest_algorithm_sha256() {
        return digest_hex_text(digest_sha256(bytes))
    }
    if algorithm == container_digest_algorithm_sha512() {
        return digest_hex_text(digest_sha512(bytes))
    }
    container_failure_raise_integrity("container.integrity.unknown_algorithm", "算法未注册：" + algorithm)
}

# 对字节求完整 digest（algorithm:encoded）。
micro container_digest_of(algorithm: utf8, bytes: [u8]) -> Digest {
    let encoded: utf8 = container_digest_compute(algorithm, bytes)
    return Digest { algorithm: algorithm, encoded: encoded }
}

micro container_digest_equals(left: Digest, right: Digest) -> bool {
    return left.algorithm == right.algorithm && left.encoded == right.encoded
}

micro container_digest_to_string(digest: Digest) -> utf8 {
    return digest.algorithm + ":" + digest.encoded
}
