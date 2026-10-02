namespace nyar.language.valkyrie;

# Node/Wasm 目标必须由已贯通的 Semantic MIR 编译器直接产出。
# 当前 V 侧没有该编译器实现，明确拒绝，不向宿主请求代编译。

micro target_uses_wasm_node_backend(canonical_target: utf8) -> bool {
    if canonical_target == "node" {
        return true
    }
    if canonical_target.starts_with("wasm32-node") {
        return true
    }
    if canonical_target.starts_with("wasm32-") && canonical_target.contains("wasm") {
        return true
    }
    return false
}
