namespace hardware;

# device 层测试。计数比较一律先转 i64（usize 无符号比较在 OVM 运行时缺 host import）。

[test]
micro test_enumerate_contains_exactly_cpu() -> unit {
    let devices: [Device] = hardware_enumerate_devices()
    let count: i64 = devices.length() as i64
    if count != 1 {
        panic("enumeration must contain exactly the CPU reference device")
    }
    let device: Device = std::collection::array::get(devices, 0)
    if device.backend_token != hardware_backend_cpu() {
        panic("enumerated device must be the cpu backend")
    }
    if device.ordinal != 0 {
        panic("cpu reference device ordinal must be 0")
    }
    if device.kind != hardware_device_kind_cpu() {
        panic("enumerated device kind must be cpu")
    }
}

[test]
micro test_cpu_device_capabilities() -> unit {
    let device: Device = hardware_cpu_device()
    if !device.cap_unified_memory {
        panic("cpu must declare unified memory")
    }
    if !device.cap_map_kernel {
        panic("cpu must declare map kernel")
    }
    if device.cap_async_dispatch {
        panic("cpu executes synchronously and must not declare async dispatch")
    }
}

[test]
micro test_device_equals_same_identity() -> unit {
    let left: Device = hardware_cpu_device()
    let right: Device = hardware_cpu_device()
    if !hardware_device_equals(left, right) {
        panic("same backend identity must compare equal")
    }
}

[test]
micro test_device_equals_different_ordinal() -> unit {
    let left: Device = hardware_cpu_device()
    let right: Device = Device {
        backend_token: hardware_backend_cpu(),
        ordinal: 1,
        kind: hardware_device_kind_cpu(),
        cap_unified_memory: true,
        cap_map_kernel: true,
        cap_async_dispatch: false,
    }
    if hardware_device_equals(left, right) {
        panic("different ordinals must not compare equal")
    }
}

[test]
micro test_device_equals_different_backend() -> unit {
    let left: Device = hardware_cpu_device()
    let right: Device = Device {
        backend_token: 99,
        ordinal: 0,
        kind: hardware_device_kind_gpu(),
        cap_unified_memory: false,
        cap_map_kernel: true,
        cap_async_dispatch: true,
    }
    if hardware_device_equals(left, right) {
        panic("different backends must not compare equal")
    }
}
