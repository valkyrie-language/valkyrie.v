namespace hardware;

# L5 渲染资源层：Texture / Sampler（合同声明；实现未落地）。

# TextureFormat 词汇。
micro hardware_format_rgba8unorm() -> i64 {
    return 1
}

micro hardware_format_bgra8unorm() -> i64 {
    return 2
}

micro hardware_format_rgba16float() -> i64 {
    return 3
}

micro hardware_format_rgba32float() -> i64 {
    return 4
}

micro hardware_format_depth24plus() -> i64 {
    return 5
}

# TextureUsage 位掩码。
micro hardware_texture_sampled() -> i64 {
    return 1
}

micro hardware_texture_storage() -> i64 {
    return 2
}

micro hardware_texture_render_attachment() -> i64 {
    return 4
}

micro hardware_texture_copy_src() -> i64 {
    return 8
}

micro hardware_texture_copy_dst() -> i64 {
    return 16
}

# Tiling 词汇。
micro hardware_tiling_linear() -> i64 {
    return 1
}

micro hardware_tiling_optimal() -> i64 {
    return 2
}

# Sampler filter/address 词汇。
micro hardware_filter_nearest() -> i64 {
    return 1
}

micro hardware_filter_linear() -> i64 {
    return 2
}

micro hardware_address_clamp() -> i64 {
    return 1
}

micro hardware_address_repeat() -> i64 {
    return 2
}

micro hardware_address_mirror() -> i64 {
    return 3
}

# Texture — 渲染纹理资源（合同字段；创建校验：尺寸为正、mip ≤ log2(max 维)、format 受支持）。
class Texture {
    _backend: i64
    _device_ordinal: i64
    _format: i64
    _usage: i64
    _tiling: i64
    _width: i64
    _height: i64
    _depth: i64
    _mip_levels: i64
}

# Sampler — 采样器（filter/address/lod 范围）。
class Sampler {
    _backend: i64
    _device_ordinal: i64
    _filter: i64
    _address_mode: i64
    _lod_min: i64
    _lod_max: i64
}
