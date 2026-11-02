namespace hardware;

# buffer 层测试：host↔device 读写读回与 device↔device 传输（含反例）。

micro hardware_test_second_cpu_device() -> Device {
    return Device {
        backend_token: hardware_backend_cpu(),
        ordinal: 1,
        kind: hardware_device_kind_cpu(),
        cap_unified_memory: true,
        cap_map_kernel: true,
        cap_async_dispatch: false,
    }
}

micro hardware_test_foreign_device() -> Device {
    return Device {
        backend_token: 99,
        ordinal: 0,
        kind: hardware_device_kind_gpu(),
        cap_unified_memory: false,
        cap_map_kernel: true,
        cap_async_dispatch: true,
    }
}

[test]
micro test_buffer_create_and_read_back() -> unit {
    let device: Device = hardware_cpu_device()
    let data: [i64] = [10, 20, 30]
    let buffer: Buffer<i64> = Buffer::create(device, data)
    let size: i64 = buffer.length() as i64
    if size != 3 {
        panic("buffer length must match initial data")
    }
    let snapshot: [i64] = buffer.read()
    let third: i64 = std::collection::array::get(snapshot, 2)
    if third != 30 {
        panic("read-back must return the written elements")
    }
}

[test]
micro test_buffer_write_replaces_and_snapshot_is_stable() -> unit {
    let device: Device = hardware_cpu_device()
    let data: [i64] = [10, 20, 30]
    let mut buffer: Buffer<i64> = Buffer::create(device, data)
    let snapshot: [i64] = buffer.read()
    let replacement: [i64] = [1, 2]
    buffer.write(replacement)
    let written_size: i64 = buffer.length() as i64
    if written_size != 2 {
        panic("write must replace the buffer contents")
    }
    let snapshot_size: i64 = snapshot.length() as i64
    if snapshot_size != 3 {
        panic("earlier read snapshot must stay stable after write (value semantics)")
    }
    if buffer.is_empty() {
        panic("buffer with two elements must not be empty")
    }
}

[test]
micro test_buffer_identity_queries() -> unit {
    let device: Device = hardware_cpu_device()
    let data: [i64] = [7]
    let buffer: Buffer<i64> = Buffer::create(device, data)
    if !hardware_buffer_on_device(buffer, device) {
        panic("buffer must report being on its creation device")
    }
    let other: Device = hardware_test_second_cpu_device()
    if hardware_buffer_on_device(buffer, other) {
        panic("buffer must not report a different device")
    }
    let kind: i64 = buffer.device_kind()
    if kind != hardware_device_kind_cpu() {
        panic("buffer device kind must be cpu")
    }
}

[test]
micro test_buffer_transfer_cpu_to_cpu() -> unit {
    let source_device: Device = hardware_cpu_device()
    let target: Device = hardware_test_second_cpu_device()
    let data: [i64] = [5, 6, 7]
    let buffer: Buffer<i64> = Buffer::create(source_device, data)
    let outcome: Result<Buffer<i64>, HardwareFault> = buffer.transfer_to(target)
    if !hardware_outcome_is_fine(outcome) {
        panic("cpu-to-cpu transfer must succeed")
    }
    let empty: [i64] = []
    let moved: Buffer<i64> = hardware_outcome_value_or(outcome, Buffer::create(source_device, empty))
    let moved_size: i64 = moved.length() as i64
    if moved_size != 3 {
        panic("transferred buffer must carry all elements")
    }
    let elements: [i64] = moved.read()
    let second: i64 = std::collection::array::get(elements, 1)
    if second != 6 {
        panic("transferred contents must match the source")
    }
    if !hardware_buffer_on_device(moved, target) {
        panic("transferred buffer must be bound to the target device")
    }
}

[test]
micro test_buffer_transfer_foreign_backend_rejected() -> unit {
    let source_device: Device = hardware_cpu_device()
    let foreign: Device = hardware_test_foreign_device()
    let data: [i64] = [1]
    let buffer: Buffer<i64> = Buffer::create(source_device, data)
    let outcome: Result<Buffer<i64>, HardwareFault> = buffer.transfer_to(foreign)
    if hardware_outcome_is_fine(outcome) {
        panic("transfer to an unregistered backend must fail")
    }
    let code: i64 = hardware_outcome_fault_code(outcome)
    if code != hardware_fault_backend_unavailable() {
        panic("unregistered backend transfer must report backend_unavailable")
    }
}
