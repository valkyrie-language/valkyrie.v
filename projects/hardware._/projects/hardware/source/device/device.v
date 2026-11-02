namespace hardware;

# Device — 设备描述快照（枚举时刻冻结）。
#
# 字段全部为第一级标量（i64/bool）：当前工具链不接受聚合嵌套聚合
# ，能力面因此就地展开为 cap_* 布尔字段，不另设嵌套类型。
# 身份比较只看 backend_token + ordinal（kind/cap_* 为后端派生属性）。
structure Device {
    # 后端数值身份（`hardware_backend_cpu` 等）。
    backend_token: i64
    # 后端内枚举序号。
    ordinal: i64
    # 设备类别（`hardware_device_kind_cpu/gpu/accelerator`）。
    kind: i64
    # host 与 device 共享内存：传输即本地快照（CPU 为 true）。
    cap_unified_memory: bool
    # 支持 map 逐元素 kernel 调度。
    cap_map_kernel: bool
    # 支持异步 dispatch（CPU 同步执行，为 false）。
    cap_async_dispatch: bool
}

micro hardware_device_kind_cpu() -> i64 {
    return 1
}

micro hardware_device_kind_gpu() -> i64 {
    return 2
}

micro hardware_device_kind_accelerator() -> i64 {
    return 3
}

micro hardware_backend_cpu() -> i64 {
    return 1
}

# 设备身份相等：backend_token + ordinal 双因子。
micro hardware_device_equals(left: Device, right: Device) -> bool {
    return left.backend_token == right.backend_token && left.ordinal == right.ordinal
}

# 设备枚举：返回全部已注册后端的设备。
# 当前只有 CPU 参考后端在场；外部后端经 host capability 接入，
# provider 就位前不伪造设备。
micro hardware_enumerate_devices() -> [Device] {
    return [hardware_cpu_device()]
}
