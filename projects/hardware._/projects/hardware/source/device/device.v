namespace hardware;

# L1 设备层：适配器/设备、能力集合与限制结构（合同声明，实现见 C1 块）。

# 后端身份词汇。
micro hardware_backend_cpu() -> i64 {
    return 1
}

# DeviceKind 词汇。
micro hardware_device_kind_cpu() -> i64 {
    return 1
}

micro hardware_device_kind_discrete_gpu() -> i64 {
    return 2
}

micro hardware_device_kind_integrated_gpu() -> i64 {
    return 3
}

micro hardware_device_kind_virtual_gpu() -> i64 {
    return 4
}

micro hardware_device_kind_accelerator() -> i64 {
    return 5
}

# Features 位掩码（能力集合，按位组合）。
micro hardware_feature_compute() -> i64 {
    return 1
}

micro hardware_feature_transfer() -> i64 {
    return 2
}

micro hardware_feature_graphics() -> i64 {
    return 4
}

micro hardware_feature_timeline_semaphore() -> i64 {
    return 8
}

micro hardware_feature_multi_queue() -> i64 {
    return 16
}

micro hardware_feature_shader_f64() -> i64 {
    return 32
}

micro hardware_feature_texture() -> i64 {
    return 64
}

micro hardware_feature_device_lost_recovery() -> i64 {
    return 128
}

# Features — 能力集合（i64 位掩码）。
structure Features {
    bits: i64
}

micro hardware_features_has(set: Features, flag: i64) -> bool {
    return set.bits.bit_and(flag) != 0
}

# DeviceLimits — 限制结构（扁平标量；聚合嵌套聚合在当前工具链不可物化，
# 故 Limits 为独立结构由访问器给出，不内嵌进 Device）。
structure DeviceLimits {
    max_buffer_elements: i64
    max_workgroup_size_x: i64
    max_workgroup_size_y: i64
    max_workgroup_size_z: i64
    max_workgroup_count_x: i64
    max_workgroup_count_y: i64
    max_workgroup_count_z: i64
    max_shared_memory_bytes_per_workgroup: i64
    max_bind_groups: i64
    max_storage_buffers_per_stage: i64
    min_storage_buffer_offset_alignment: i64
}

# Adapter — 物理设备枚举快照身份（不透明句柄；构造归后端工厂）。
# `_features` 为枚举时刻冻结的支持集位掩码。
class Adapter {
    _backend: i64
    _ordinal: i64
    _kind: i64
    _features: i64
}

# Device — 逻辑设备句柄。`_features` 为 request 时冻结的支持集子集；
# `_lost` 单调（一旦丢失不回弹）。
class Device {
    _backend: i64
    _ordinal: i64
    _kind: i64
    _features: i64
    _lost: bool
}

# ---- CPU 参考后端工厂与能力事实 ----

# CPU 后端支持集：compute + transfer。
micro hardware_cpu_features_bits() -> i64 {
    return hardware_feature_compute().bit_or(hardware_feature_transfer())
}

# CPU 后端限制结构（合同最小档以上）。
micro hardware_cpu_limits() -> DeviceLimits {
    return DeviceLimits {
        max_buffer_elements: 1048576,
        max_workgroup_size_x: 256,
        max_workgroup_size_y: 256,
        max_workgroup_size_z: 64,
        max_workgroup_count_x: 65535,
        max_workgroup_count_y: 65535,
        max_workgroup_count_z: 65535,
        max_shared_memory_bytes_per_workgroup: 16384,
        max_bind_groups: 4,
        max_storage_buffers_per_stage: 8,
        min_storage_buffer_offset_alignment: 16,
    }
}

# CPU 参考适配器：身份 (cpu, 0)，kind cpu，features 为 CPU 支持集。
micro hardware_cpu_adapter() -> Adapter {
    return Adapter {
        _backend: hardware_backend_cpu(),
        _ordinal: 0,
        _kind: hardware_device_kind_cpu(),
        _features: hardware_cpu_features_bits(),
    }
}

# ---- L1 适配器/设备 API ----

# 物理设备枚举：返回全部已注册后端的适配器。
# 外部后端经 host capability 接入（当前无 provider，见 source/backend/host.v），不参与枚举。
micro hardware_enumerate_adapters() -> [Adapter] {
    return [hardware_cpu_adapter()]
}

micro adapter_kind(adapter: Adapter) -> i64 {
    return adapter._kind
}

micro adapter_backend(adapter: Adapter) -> i64 {
    return adapter._backend
}

micro adapter_ordinal(adapter: Adapter) -> i64 {
    return adapter._ordinal
}

# 适配器支持集（枚举时刻冻结）。
micro adapter_features(adapter: Adapter) -> Features {
    return Features { bits: adapter._features }
}

# 适配器限制结构：已注册后端给出冻结事实；未注册后端结构化失败。
micro adapter_limits(adapter: Adapter) -> Result<DeviceLimits, HardwareFault> {
    if adapter._backend == hardware_backend_cpu() {
        return Fine(hardware_cpu_limits())
    }
    return Fail(HardwareFault { code: hardware_fault_backend_unavailable() })
}

# 请求逻辑设备：required 必须 ⊆ supported，否则 feature_missing。
# 成功时 device 冻结 required 子集，limits 由 device_limits 按同一路由给出。
micro adapter_request_device(adapter: Adapter, required: Features) -> Result<Device, HardwareFault> {
    let supported: i64 = adapter._features
    # 子集判定：required 与 supported 的差集非空即超集请求（i64 无 bit_not，用算术补）。
    if required.bits - required.bits.bit_and(supported) != 0 {
        return Fail(HardwareFault { code: hardware_fault_feature_missing() })
    }
    return Fine(Device {
        _backend: adapter._backend,
        _ordinal: adapter._ordinal,
        _kind: adapter._kind,
        _features: required.bits,
        _lost: false,
    })
}

# 设备已冻结的支持集。
micro device_features(device: Device) -> Features {
    return Features { bits: device._features }
}

# 设备限制结构：与适配器同路由（已注册后端给事实，未注册结构化失败）。
micro device_limits(device: Device) -> Result<DeviceLimits, HardwareFault> {
    if device._backend == hardware_backend_cpu() {
        return Fine(hardware_cpu_limits())
    }
    return Fail(HardwareFault { code: hardware_fault_backend_unavailable() })
}

micro device_kind(device: Device) -> i64 {
    return device._kind
}

micro device_is_lost(device: Device) -> bool {
    return device._lost
}

# 设备身份相等：backend + ordinal 双因子。
micro hardware_device_equals(left: Device, right: Device) -> bool {
    return left._backend == right._backend && left._ordinal == right._ordinal
}
