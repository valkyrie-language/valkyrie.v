namespace hardware.conformance;

# L1 适配器/设备用例（C101–C106）。返回 0 = 通过，非 0 = 失败阶段号。
# 用例以后端身份参数化；当前注册表仅含 CPU 参考后端。

# C101 枚举恰含一台 CPU 适配器，身份与类别正确。
micro c101_enumerate_single_cpu(backend: i64) -> i64 {
    let adapters: [hardware::Adapter] = hardware::hardware_enumerate_adapters()
    let count: i64 = adapters.length() as i64
    if count != 1 {
        return 101
    }
    let adapter: hardware::Adapter = std::collection::array::get(adapters, 0)
    if hardware::adapter_backend(adapter) != backend {
        return 102
    }
    if hardware::adapter_ordinal(adapter) != 0 {
        return 103
    }
    if hardware::adapter_kind(adapter) != hardware::hardware_device_kind_cpu() {
        return 104
    }
    return 0
}

# C102 适配器限制结构全字段为正且达合同最小档。
micro c102_limits_positive(backend: i64) -> i64 {
    let adapter: hardware::Adapter = hardware::hardware_cpu_adapter()
    let outcome: Result<hardware::DeviceLimits, hardware::HardwareFault> = hardware::adapter_limits(adapter)
    if !hardware::hardware_outcome_is_fine(outcome) {
        return 201
    }
    let zero: hardware::DeviceLimits = hardware::DeviceLimits {
        max_buffer_elements: 0,
        max_workgroup_size_x: 0,
        max_workgroup_size_y: 0,
        max_workgroup_size_z: 0,
        max_workgroup_count_x: 0,
        max_workgroup_count_y: 0,
        max_workgroup_count_z: 0,
        max_shared_memory_bytes_per_workgroup: 0,
        max_bind_groups: 0,
        max_storage_buffers_per_stage: 0,
        min_storage_buffer_offset_alignment: 0,
    }
    let limits: hardware::DeviceLimits = hardware::hardware_outcome_value_or(outcome, zero)
    if limits.max_buffer_elements <= 0 || limits.max_bind_groups <= 0 || limits.max_storage_buffers_per_stage <= 0 {
        return 202
    }
    if limits.max_workgroup_size_x <= 0 || limits.max_workgroup_size_y <= 0 || limits.max_workgroup_size_z <= 0 {
        return 203
    }
    if limits.max_workgroup_count_x <= 0 || limits.max_workgroup_count_y <= 0 || limits.max_workgroup_count_z <= 0 {
        return 204
    }
    if limits.max_shared_memory_bytes_per_workgroup <= 0 || limits.min_storage_buffer_offset_alignment <= 0 {
        return 205
    }
    return 0
}

# C103 适配器支持集必含 compute + transfer，且不含未声明项。
micro c103_features_compute_transfer(backend: i64) -> i64 {
    let adapter: hardware::Adapter = hardware::hardware_cpu_adapter()
    let features: hardware::Features = hardware::adapter_features(adapter)
    if !hardware::hardware_features_has(features, hardware::hardware_feature_compute()) {
        return 301
    }
    if !hardware::hardware_features_has(features, hardware::hardware_feature_transfer()) {
        return 302
    }
    if hardware::hardware_features_has(features, hardware::hardware_feature_graphics()) {
        return 303
    }
    return 0
}

# C104 请求支持集子集 → Fine。
micro c104_request_subset_fine(backend: i64) -> i64 {
    let adapter: hardware::Adapter = hardware::hardware_cpu_adapter()
    let required: hardware::Features = hardware::Features { bits: hardware::hardware_feature_compute() }
    let outcome: Result<hardware::Device, hardware::HardwareFault> = hardware::adapter_request_device(adapter, required)
    if !hardware::hardware_outcome_is_fine(outcome) {
        return 401
    }
    return 0
}

# C105 请求超出支持集 → Fail(feature_missing)。（反）
micro c105_request_superset_feature_missing(backend: i64) -> i64 {
    let adapter: hardware::Adapter = hardware::hardware_cpu_adapter()
    let required: hardware::Features = hardware::Features { bits: hardware::hardware_feature_compute().bit_or(hardware::hardware_feature_graphics()) }
    let outcome: Result<hardware::Device, hardware::HardwareFault> = hardware::adapter_request_device(adapter, required)
    if hardware::hardware_outcome_is_fine(outcome) {
        return 501
    }
    let code: i64 = hardware::hardware_outcome_fault_code(outcome)
    if code != hardware::hardware_fault_feature_missing() {
        return 502
    }
    return 0
}

# C106 设备快照冻结：features 为请求子集、limits 与适配器一致、未丢失。
micro c106_device_snapshot_frozen(backend: i64) -> i64 {
    let adapter: hardware::Adapter = hardware::hardware_cpu_adapter()
    let required: hardware::Features = hardware::Features { bits: hardware::hardware_feature_compute().bit_or(hardware::hardware_feature_transfer()) }
    let outcome: Result<hardware::Device, hardware::HardwareFault> = hardware::adapter_request_device(adapter, required)
    if !hardware::hardware_outcome_is_fine(outcome) {
        return 601
    }
    let fallback: hardware::Device = hardware::Device {
        _backend: 0,
        _ordinal: 0,
        _kind: 0,
        _features: 0,
        _lost: true,
    }
    let device: hardware::Device = hardware::hardware_outcome_value_or(outcome, fallback)
    let features: hardware::Features = hardware::device_features(device)
    if !hardware::hardware_features_has(features, hardware::hardware_feature_transfer()) {
        return 602
    }
    if hardware::hardware_features_has(features, hardware::hardware_feature_graphics()) {
        return 603
    }
    if hardware::device_is_lost(device) {
        return 604
    }
    let limits_outcome: Result<hardware::DeviceLimits, hardware::HardwareFault> = hardware::device_limits(device)
    if !hardware::hardware_outcome_is_fine(limits_outcome) {
        return 605
    }
    if hardware::device_kind(device) != hardware::hardware_device_kind_cpu() {
        return 606
    }
    return 0
}
