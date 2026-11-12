namespace std.crypto;

using std.data.digest::{digest_sha256, digest_sha512, digest_hex, digest_hex_text, DigestSha256, DigestSha512, digest_sha256_new, digest_sha512_new};
using std.types::{Result};

# std.crypto: 摘要门面与熵源合同。
#
# 摘要所有权：算法的唯一权威实现在 `std.data.digest`（纯函数、字节模型、
# 流式三件套）。本层是面向 std 消费者的正式门面——只做委托与编码入口，
# 不维护第二套实现，也不为未交付算法携带占位：
# - `md5`、`hmac_sha256` 在权威层没有实现，本层即不提供这些入口；
#   消费方不得期待「返回空串的成功占位」，需要这些算法时应先在
#   `std.data.digest` 落地权威实现，门面再行委托。
# - 输入与摘要一律是字节（`[u8]`）；hex 是独立编码层（`digest_hex` /
#   `digest_hex_text`），文本化只在显式编码入口发生，摘要本体不经字符串。

# ── 一次性摘要（委托权威实现）────────────────────────────────────────

micro sha256(data: [u8]) -> [u8] {
    return digest_sha256(data)
}

micro sha512(data: [u8]) -> [u8] {
    return digest_sha512(data)
}

# ── 流式摘要（直接交付权威状态，update/finalize 合同归 digest 层）──

micro sha256_stream() -> DigestSha256 {
    return digest_sha256_new()
}

micro sha512_stream() -> DigestSha512 {
    return digest_sha512_new()
}

# ── 编码层（独立于摘要本体）──────────────────────────────────────────

# 摘要字节 → 小写 hex 字节（编码层原语，可级联任意摘要）。
micro hex_encode(digest: [u8]) -> [u8] {
    return digest_hex(digest)
}

# 摘要字节 → 小写 hex 文本。
micro hex_text(digest: [u8]) -> utf8 {
    return digest_hex_text(digest)
}

micro sha256_hex(data: [u8]) -> utf8 {
    return digest_hex_text(digest_sha256(data))
}

micro sha512_hex(data: [u8]) -> utf8 {
    return digest_hex_text(digest_sha512(data))
}

# ── 熵源合同（宿主绑定；无内建兜底）─────────────────────────────────

# 熵源失败种类（结构化）。
enums RandomSourceErrorKind {
    # 目标缺少可用的宿主熵源。
    EntropyUnavailable
    # 请求长度非法。
    InvalidLength
}

structure RandomSourceError {
    kind: RandomSourceErrorKind
}

micro random_source_error(kind: RandomSourceErrorKind) -> RandomSourceError {
    return RandomSourceError { kind: kind }
}

# 取 `length` 字节强随机数据：字节模型，失败经种类表达——
# 不存在以空串兼作失败哨兵的形态。缺 provider 绑定的目标在计划阶段
# 结构化失败，无默认返回值兜底。
[host_contract]
micro random_bytes(length: usize) -> Result<[u8], RandomSourceError>

# 取 RFC 4122 形态的随机 UUID 文本（文本是标识符的原生形态，非摘要数据）。
# 失败经种类表达；缺 provider 绑定的目标计划阶段结构化失败。
[host_contract]
micro random_uuid() -> Result<utf8, RandomSourceError>
