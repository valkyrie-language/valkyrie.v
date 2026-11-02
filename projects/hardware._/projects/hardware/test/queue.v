namespace hardware;

# queue 层测试：map 调度、提交计数与两条反例。

micro hardware_test_double(value: i64) -> i64 {
    return value * 2
}

micro hardware_test_queue_second_cpu_device() -> Device {
    return Device {
        backend_token: hardware_backend_cpu(),
        ordinal: 1,
        kind: hardware_device_kind_cpu(),
        cap_unified_memory: true,
        cap_map_kernel: true,
        cap_async_dispatch: false,
    }
}

[test]
micro test_queue_create_initial_state() -> unit {
    let device: Device = hardware_cpu_device()
    let queue: Queue = Queue::create(device)
    let submitted: i64 = queue.submitted()
    if submitted != 0 {
        panic("a fresh queue must report zero submissions")
    }
    queue.wait()
}

[test]
micro test_dispatch_map_doubles_elements() -> unit {
    let device: Device = hardware_cpu_device()
    let queue: Queue = Queue::create(device)
    let data: [i64] = [1, 2, 3]
    let input: Buffer<i64> = Buffer::create(device, data)
    let outcome: Result<Buffer<i64>, HardwareFault> = hardware_dispatch_map(queue, input, hardware_test_double)
    if !hardware_outcome_is_fine(outcome) {
        panic("map dispatch on the cpu backend must succeed")
    }
    let empty: [i64] = []
    let output: Buffer<i64> = hardware_outcome_value_or(outcome, Buffer::create(device, empty))
    let output_size: i64 = output.length() as i64
    if output_size != 3 {
        panic("map dispatch must produce one output per input element")
    }
    let elements: [i64] = output.read()
    let third: i64 = std::collection::array::get(elements, 2)
    if third != 6 {
        panic("map dispatch must apply the kernel to every element")
    }
    if !hardware_buffer_on_device(output, device) {
        panic("the output buffer must inherit the input device identity")
    }
    let submitted: i64 = queue.submitted()
    if submitted != 1 {
        panic("a successful dispatch must increment the submission count")
    }
}

[test]
micro test_dispatch_map_device_mismatch() -> unit {
    let device: Device = hardware_cpu_device()
    let other: Device = hardware_test_queue_second_cpu_device()
    let queue: Queue = Queue::create(device)
    let data: [i64] = [1, 2]
    let input: Buffer<i64> = Buffer::create(other, data)
    let outcome: Result<Buffer<i64>, HardwareFault> = hardware_dispatch_map(queue, input, hardware_test_double)
    if hardware_outcome_is_fine(outcome) {
        panic("dispatch with a buffer on another device must fail")
    }
    let code: i64 = hardware_outcome_fault_code(outcome)
    if code != hardware_fault_device_mismatch() {
        panic("cross-device dispatch must report device_mismatch")
    }
    let submitted: i64 = queue.submitted()
    if submitted != 0 {
        panic("a rejected dispatch must not count as submitted")
    }
}

[test]
micro test_dispatch_map_capability_missing() -> unit {
    let limited: Device = Device {
        backend_token: hardware_backend_cpu(),
        ordinal: 0,
        kind: hardware_device_kind_cpu(),
        cap_unified_memory: true,
        cap_map_kernel: false,
        cap_async_dispatch: false,
    }
    let queue: Queue = Queue::create(limited)
    let data: [i64] = [1]
    let input: Buffer<i64> = Buffer::create(limited, data)
    let outcome: Result<Buffer<i64>, HardwareFault> = hardware_dispatch_map(queue, input, hardware_test_double)
    if hardware_outcome_is_fine(outcome) {
        panic("dispatch on a device without map_kernel must fail")
    }
    let code: i64 = hardware_outcome_fault_code(outcome)
    if code != hardware_fault_capability_missing() {
        panic("a device without map_kernel must report capability_missing")
    }
}
