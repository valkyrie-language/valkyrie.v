namespace container;

# Layer / diff / 层链。
#
# 层是内容寻址的字节块（diff 内容 + diff_id）；层链是有序的 diff_id 序列，
# 代表从空 rootfs 逐层叠加得到最终 rootfs 的应用顺序。diff_id 是**未压缩**层
# 内容的摘要（与 OCI config rootfs.diff_ids 同源）。

structure Layer {
    # 未压缩内容的摘要（diff_id），参与链完整性校验。
    diff_id: Digest
    # 实际存储内容（可能压缩）的摘要，寻址用。
    digest: Digest
    media_type: utf8
    size: i64
}

micro container_layer_new(diff_id: Digest, digest: Digest, media_type: utf8, size: i64) -> Layer {
    return Layer { diff_id: diff_id, digest: digest, media_type: media_type, size: size }
}

# 层链：有序 diff_id。
structure LayerChain {
    diff_ids: [Digest]
}

micro container_layer_chain_empty() -> LayerChain {
    return LayerChain { diff_ids: [] }
}

micro container_layer_chain_push(chain: LayerChain, diff_id: Digest) -> LayerChain {
    return LayerChain { diff_ids: push(chain.diff_ids, diff_id) }
}

micro container_layer_chain_length(chain: LayerChain) -> usize {
    return chain.diff_ids.length()
}

# 校验层链与层列表一一对应且 diff_id 匹配（完整性）。
micro container_layer_chain_matches(chain: LayerChain, layers: [Layer]) -> bool {
    if chain.diff_ids.length() != layers.length() {
        return false
    }
    let mut index: usize = 0
    while index < layers.length() {
        let layer = std::collection::array::get(layers, index)
        let expected = std::collection::array::get(chain.diff_ids, index)
        if !container_digest_equals(layer.diff_id, expected) {
            return false
        }
        index = index + 1
    }
    return true
}
