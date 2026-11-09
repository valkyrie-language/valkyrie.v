namespace hardware_harness;

using hardware.conformance::{c101_enumerate_single_cpu, c102_limits_positive, c103_features_compute_transfer, c104_request_subset_fine, c105_request_superset_feature_missing, c106_device_snapshot_frozen};

# hardware 合同的验证 harness：逐项构造各层声明，
# 断言词汇、位掩码、注册表三元组与声明可物化。0 = 通过，非 0 = 失败阶段号。
# Fine 侧运行时用例当前不可构造：调用解析当前无法解析该调用，运行时用例暂不执行；
# 本文件只执行 Fail 侧通道，Fine 侧检查器已编译通过。

# L1：Features 位掩码语义。
[export]
micro c0_features_bitset() -> i64 {
    let compute_bit: i64 = hardware::hardware_feature_compute()
    let texture_bit: i64 = hardware::hardware_feature_texture()
    let both: hardware::Features = hardware::Features { bits: compute_bit.bit_or(texture_bit) }
    if !hardware::hardware_features_has(both, compute_bit) {
        return 1
    }
    if !hardware::hardware_features_has(both, texture_bit) {
        return 2
    }
    if hardware::hardware_features_has(both, hardware::hardware_feature_graphics()) {
        return 3
    }
    return 0
}

# L1：DeviceLimits/Device/Adapter 声明可构造且字段冻结。
[export]
micro c0_device_declarations() -> i64 {
    let limits: hardware::DeviceLimits = hardware::DeviceLimits {
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
    let alignment: i64 = limits.min_storage_buffer_offset_alignment
    if alignment != 16 {
        return 1
    }
    let adapter: hardware::Adapter = hardware::hardware_cpu_adapter()
    let kind: i64 = adapter._kind
    if kind != hardware::hardware_device_kind_cpu() {
        return 2
    }
    let device: hardware::Device = hardware::Device {
        _backend: hardware::hardware_backend_cpu(),
        _ordinal: 0,
        _kind: hardware::hardware_device_kind_cpu(),
        _features: hardware::hardware_feature_compute().bit_or(hardware::hardware_feature_transfer()),
        _lost: false,
    }
    if device._lost {
        return 3
    }
    return 0
}

# L2：Heap/Buffer 声明与 usage 词汇。
[export]
micro c0_memory_declarations() -> i64 {
    let heap: hardware::Heap = hardware::Heap {
        _backend: hardware::hardware_backend_cpu(),
        _device_ordinal: 0,
        _class: hardware::hardware_heap_unified(),
        _capacity_elements: 1024,
        _allocated_elements: 0,
    }
    let class_bit: i64 = heap._class
    if class_bit != hardware::hardware_heap_unified() {
        return 1
    }
    let data: [i64] = [1, 2, 3]
    let buffer: hardware::Buffer<i64> = hardware::Buffer {
        _backend: heap._backend,
        _device_ordinal: heap._device_ordinal,
        _heap_class: heap._class,
        _offset: 0,
        _length: 3,
        _usage: hardware::hardware_usage_storage_read_write().bit_or(hardware::hardware_usage_map_write()),
        _mapped: false,
        _map_epoch: 0,
        _elements: data,
    }
    let length: i64 = buffer._length
    if length != 3 {
        return 2
    }
    let usage: i64 = buffer._usage
    if usage.bit_and(hardware::hardware_usage_map_write()) == 0 {
        return 3
    }
    return 0
}

# L3：Queue/CommandBuffer/Fence 声明与状态词汇。
[export]
micro c0_queue_declarations() -> i64 {
    let queue: hardware::Queue = hardware::Queue {
        _backend: hardware::hardware_backend_cpu(),
        _device_ordinal: 0,
        _family: hardware::hardware_queue_compute(),
        _ordinal: 0,
        _submitted: 0,
    }
    let family: i64 = queue._family
    if family != hardware::hardware_queue_compute() {
        return 1
    }
    let command: hardware::CommandBuffer = hardware::CommandBuffer {
        _family: queue._family,
        _state: hardware::hardware_command_recording(),
        _recorded_ops: 0,
    }
    let state: i64 = command._state
    if state != hardware::hardware_command_recording() {
        return 2
    }
    let fence: hardware::Fence = hardware::Fence { _backend: queue._backend, _device_ordinal: queue._device_ordinal, _value: 0 }
    let value: i64 = fence._value
    if value != 0 {
        return 3
    }
    return 0
}

# L4：ShaderModule/ComputePipeline/BindGroup 声明与 opcode 词汇。
[export]
micro c0_pipeline_declarations() -> i64 {
    let program: [i64] = [
        hardware::hardware_op_const(), 0, 2, 0,
        hardware::hardware_op_return(), 0, 0, 0,
    ]
    let module: hardware::ShaderModule = hardware::ShaderModule {
        _element_kind: hardware::hardware_element_i64(),
        _workgroup_size_x: 4,
        _workgroup_size_y: 1,
        _workgroup_size_z: 1,
        _register_count: 1,
        _program: program,
    }
    let program_size: i64 = module._program.length() as i64
    if program_size != 8 {
        return 1
    }
    let layout_slots: [i64] = [0]
    let layout_kinds: [i64] = [hardware::hardware_slot_storage_read_write()]
    let pipeline: hardware::ComputePipeline = hardware::ComputePipeline {
        _backend: hardware::hardware_backend_cpu(),
        _device_ordinal: 0,
        _element_kind: module._element_kind,
        _workgroup_size_x: module._workgroup_size_x,
        _workgroup_size_y: module._workgroup_size_y,
        _workgroup_size_z: module._workgroup_size_z,
        _register_count: module._register_count,
        _program: module._program,
        _layout_slots: layout_slots,
        _layout_kinds: layout_kinds,
    }
    let layout_size: i64 = pipeline._layout_slots.length() as i64
    if layout_size != 1 {
        return 2
    }
    let group: hardware::BindGroup = hardware::BindGroup { _slots: layout_slots, _kinds: layout_kinds }
    let group_size: i64 = group._slots.length() as i64
    if group_size != 1 {
        return 3
    }
    return 0
}

# L5：Texture/Sampler 声明与词汇（合同 only）。
[export]
micro c0_texture_declarations() -> i64 {
    let texture: hardware::Texture = hardware::Texture {
        _backend: hardware::hardware_backend_cpu(),
        _device_ordinal: 0,
        _format: hardware::hardware_format_rgba8unorm(),
        _usage: hardware::hardware_texture_sampled().bit_or(hardware::hardware_texture_copy_dst()),
        _tiling: hardware::hardware_tiling_optimal(),
        _width: 256,
        _height: 256,
        _depth: 1,
        _mip_levels: 1,
    }
    let width: i64 = texture._width
    if width != 256 {
        return 1
    }
    let sampler: hardware::Sampler = hardware::Sampler {
        _backend: hardware::hardware_backend_cpu(),
        _device_ordinal: 0,
        _filter: hardware::hardware_filter_linear(),
        _address_mode: hardware::hardware_address_clamp(),
        _lod_min: 0,
        _lod_max: 0,
    }
    let filter: i64 = sampler._filter
    if filter != hardware::hardware_filter_linear() {
        return 2
    }
    return 0
}

# L6：fault 注册表三元组一致性（category/recoverable 经注册表函数派生）。
[export]
micro c0_fault_registry() -> i64 {
    let oom_code: i64 = hardware::hardware_fault_out_of_memory()
    if hardware::hardware_fault_category_of(oom_code) != hardware::hardware_category_out_of_memory() {
        return 1
    }
    if !hardware::hardware_fault_recoverable_of(oom_code) {
        return 2
    }
    let lost_code: i64 = hardware::hardware_fault_device_lost()
    if hardware::hardware_fault_category_of(lost_code) != hardware::hardware_category_device_lost() {
        return 3
    }
    if hardware::hardware_fault_recoverable_of(lost_code) {
        return 4
    }
    let mismatch_code: i64 = hardware::hardware_fault_device_mismatch()
    if hardware::hardware_fault_category_of(mismatch_code) != hardware::hardware_category_validation() {
        return 5
    }
    if hardware::hardware_fault_recoverable_of(mismatch_code) {
        return 6
    }
    let backend_down_code: i64 = hardware::hardware_fault_backend_unavailable()
    if hardware::hardware_fault_category_of(backend_down_code) != hardware::hardware_category_unsupported() {
        return 7
    }
    return 0
}

# L6 Fail 侧：construction + 检查器运行时通道。
[export]
micro c0b_fail_code_only() -> i64 {
    let outcome: Result<i64, hardware::HardwareFault> = Fail(hardware::HardwareFault { code: hardware::hardware_fault_out_of_memory() })
    if hardware::hardware_outcome_is_fine(outcome) {
        return 1
    }
    let code: i64 = hardware::hardware_outcome_fault_code(outcome)
    if code != hardware::hardware_fault_out_of_memory() {
        return 2
    }
    return 0
}

[export]
micro c0b_fail_category_only() -> i64 {
    let outcome: Result<i64, hardware::HardwareFault> = Fail(hardware::HardwareFault { code: hardware::hardware_fault_out_of_memory() })
    let category: i64 = hardware::hardware_outcome_fault_category(outcome)
    if category != hardware::hardware_category_out_of_memory() {
        return 1
    }
    return 0
}

[export]
micro c0b_fail_recoverable_only() -> i64 {
    let outcome: Result<i64, hardware::HardwareFault> = Fail(hardware::HardwareFault { code: hardware::hardware_fault_out_of_memory() })
    if !hardware::hardware_outcome_fault_recoverable(outcome) {
        return 1
    }
    return 0
}

# conformance L1 套件接线（当前注册表仅 CPU 后端）。
[export]
micro conformance_c101() -> i64 {
    return c101_enumerate_single_cpu(hardware::hardware_backend_cpu())
}

[export]
micro conformance_c102() -> i64 {
    return c102_limits_positive(hardware::hardware_backend_cpu())
}

[export]
micro conformance_c103() -> i64 {
    return c103_features_compute_transfer(hardware::hardware_backend_cpu())
}

[export]
micro conformance_c104() -> i64 {
    return c104_request_subset_fine(hardware::hardware_backend_cpu())
}

[export]
micro conformance_c105() -> i64 {
    return c105_request_superset_feature_missing(hardware::hardware_backend_cpu())
}

[export]
micro conformance_c106() -> i64 {
    return c106_device_snapshot_frozen(hardware::hardware_backend_cpu())
}
