namespace hardware;

# L4 计算管线层：shader 字节码 / 管线 / 绑定（合同声明，实现见对应块）。

# element_kind 词汇（模块元素类型）。
micro hardware_element_i64() -> i64 {
    return 1
}

micro hardware_element_f32() -> i64 {
    return 2
}

micro hardware_element_f64() -> i64 {
    return 3
}

# BindSlotKind 词汇（绑定槽分档）。
micro hardware_slot_storage_read() -> i64 {
    return 1
}

micro hardware_slot_storage_read_write() -> i64 {
    return 2
}

micro hardware_slot_uniform() -> i64 {
    return 3
}

# shader 字节码 opcode 词汇 v1（4 字定长：opcode, a0, a1, a2；寄存器机、线性流）。
micro hardware_op_const() -> i64 {
    return 1
}

micro hardware_op_workitem_id() -> i64 {
    return 2
}

micro hardware_op_workgroup_id() -> i64 {
    return 3
}

micro hardware_op_load_storage() -> i64 {
    return 4
}

micro hardware_op_store_storage() -> i64 {
    return 5
}

micro hardware_op_add() -> i64 {
    return 10
}

micro hardware_op_sub() -> i64 {
    return 11
}

micro hardware_op_mul() -> i64 {
    return 12
}

micro hardware_op_div() -> i64 {
    return 13
}

micro hardware_op_rem() -> i64 {
    return 14
}

micro hardware_op_neg() -> i64 {
    return 15
}

micro hardware_op_barrier() -> i64 {
    return 20
}

micro hardware_op_return() -> i64 {
    return 255
}

# ShaderModule — shader 程序与元数据（element_kind / workgroup 尺寸 / 寄存器数 / 字节码流）。
class ShaderModule {
    _element_kind: i64
    _workgroup_size_x: i64
    _workgroup_size_y: i64
    _workgroup_size_z: i64
    _register_count: i64
    _program: [i64]
}

# ComputePipeline — 冻结的模块快照 + 绑定布局（并行标量数组：槽号 + 槽 kind）。
class ComputePipeline {
    _backend: i64
    _device_ordinal: i64
    _element_kind: i64
    _workgroup_size_x: i64
    _workgroup_size_y: i64
    _workgroup_size_z: i64
    _register_count: i64
    _program: [i64]
    _layout_slots: [i64]
    _layout_kinds: [i64]
}

# BindGroup — 布局关校验凭证（校验通过的槽位/kind 标量集；实体资源由 dispatch 调用点携带）。
class BindGroup {
    _slots: [i64]
    _kinds: [i64]
}
