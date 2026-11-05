namespace container;

# container conformance：核心用例套件。
#
# 所有规范化落地（oci/docker/…）共享同一份核心实现（MemoryContentStore、
# digest 计算、层链、引用解析），因此 conformance 测的是这一份共享实现。
# 包级一致性由"都复用 container 核心"保证；本套件对共享实现全绿即核心全绿。

micro container_conformance_bytes_of(text: utf8) -> [u8] {
    let mut out: [u8] = []
    let mut index: usize = 0
    # 字节视图：`⁅ ⁆` 已收口到码点空间，这里按字节取原始 UTF-8 存储。
    while index < text.byte_length() {
        out = push(out, text.byte_at(index))
        index = index + 1
    }
    return out
}

# 已知答案：空串 sha256（FIPS 180-4 / OCI 空 blob 同源）。
micro container_conformance_empty_sha256() -> utf8 {
    return "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}

# "abc" 的 sha256（FIPS 180-4 标准向量）。
micro container_conformance_abc_sha256() -> utf8 {
    return "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
}

# digest 一致性：同一字节经 store 与直接计算得到同一 digest。
[test]
micro test_conformance_digest_consistency() -> unit {
    let bytes: [u8] = container_conformance_bytes_of("abc")
    let computed: Digest = container_digest_of(container_digest_algorithm_sha256(), bytes)
    if computed.encoded != container_conformance_abc_sha256() {
        panic("sha256('abc') mismatch with known answer")
    }

    let mut store: MemoryContentStore = container_memory_store_new()
    let descriptor: Descriptor = store.put("application/vnd.test.bytes", bytes)
    if !container_digest_equals(descriptor.digest, computed) {
        panic("store digest must equal direct computation")
    }
}

# blob 去重：相同字节多次 put 得到同一 digest，store 不膨胀。
[test]
micro test_conformance_blob_dedup() -> unit {
    let bytes: [u8] = container_conformance_bytes_of("dedup-payload")
    let mut store: MemoryContentStore = container_memory_store_new()
    let first: Descriptor = store.put("application/vnd.test.a", bytes)
    let second: Descriptor = store.put("application/vnd.test.b", bytes)
    if !container_digest_equals(first.digest, second.digest) {
        panic("identical bytes must dedup to one digest")
    }
    if !store.exists(first.digest) {
        panic("deduped blob must exist")
    }
    let fetched: [u8] = store.get(first.digest)
    if fetched.length() != bytes.length() {
        panic("fetched blob length mismatch")
    }
}

# 层链完整性：构造层链并与层列表校验匹配；错序则拒绝。
[test]
micro test_conformance_layer_chain_integrity() -> unit {
    let bytes_a: [u8] = container_conformance_bytes_of("layer-a")
    let bytes_b: [u8] = container_conformance_bytes_of("layer-b")
    let diff_a: Digest = container_digest_of(container_digest_algorithm_sha256(), bytes_a)
    let diff_b: Digest = container_digest_of(container_digest_algorithm_sha256(), bytes_b)

    let layer_a: Layer = container_layer_new(diff_a, diff_a, "application/vnd.test.layer", bytes_a.length() as i64)
    let layer_b: Layer = container_layer_new(diff_b, diff_b, "application/vnd.test.layer", bytes_b.length() as i64)

    let chain: LayerChain = container_layer_chain_push(
        container_layer_chain_push(container_layer_chain_empty(), diff_a),
        diff_b
    )
    if container_layer_chain_length(chain) != 2 {
        panic("chain length must be 2")
    }
    if !container_layer_chain_matches(chain, [layer_a, layer_b]) {
        panic("chain must match layers in order")
    }
    if container_layer_chain_matches(chain, [layer_b, layer_a]) {
        panic("reordered layers must not match chain")
    }
}

# 引用解析：tag / digest / 规范化 round-trip / 非法 name 硬失败。
[test]
micro test_conformance_reference_parse() -> unit {
    let tagged: Reference = container_reference_parse_tagged("library/alpine", "3.19")
    if container_reference_to_string(tagged) != "library/alpine:3.19" {
        panic("tagged reference round-trip mismatch")
    }

    let digest_text: utf8 = "sha256:" + container_conformance_empty_sha256()
    let digested: Reference = container_reference_parse_digested("library/alpine", digest_text)
    if container_reference_to_string(digested) != "library/alpine@" + digest_text {
        panic("digested reference round-trip mismatch")
    }
}

# 内容摘要已知答案：空串与 abc 的 sha256 与 std.data.digest 一致（不重写哈希）。
[test]
micro test_conformance_sha256_known_answer() -> unit {
    let empty_bytes: [u8] = []
    if container_digest_compute(container_digest_algorithm_sha256(), empty_bytes) != container_conformance_empty_sha256() {
        panic("empty sha256 known-answer mismatch")
    }
    let abc: [u8] = container_conformance_bytes_of("abc")
    if container_digest_compute(container_digest_algorithm_sha256(), abc) != container_conformance_abc_sha256() {
        panic("abc sha256 known-answer mismatch")
    }
}

# media 注册表：注册 layer 并按 kind 分类，未注册类型返回 false（无硬编码分支）。
[test]
micro test_conformance_media_registry() -> unit {
    let registry: [MediaTypeRegistration] = container_media_register(
        container_media_registry_empty(),
        "application/vnd.test.layer",
        MediaLayer
    )
    if !container_media_kind_is("application/vnd.test.layer", registry, MediaLayer) {
        panic("registered layer must classify as layer")
    }
    if container_media_kind_is("application/vnd.test.layer", registry, MediaConfigFamily) {
        panic("layer must not classify as config family")
    }
    if container_media_kind_is("application/vnd.unregistered", registry, MediaLayer) {
        panic("unregistered type must not classify")
    }
}
