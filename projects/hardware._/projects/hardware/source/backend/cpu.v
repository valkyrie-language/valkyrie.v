namespace hardware;

# CPU 参考后端：纯 V 实现，始终可用。

# CPU 设备描述：身份 (cpu, 0)，能力为统一内存 + map kernel + 同步执行。
micro hardware_cpu_device() -> Device {
    return Device {
        backend_token: hardware_backend_cpu(),
        ordinal: 0,
        kind: hardware_device_kind_cpu(),
        cap_unified_memory: true,
        cap_map_kernel: true,
        cap_async_dispatch: false,
    }
}

# CPU 传输体：函数式重建拷贝（值语义数组，按元素 push 重建）。
# 循环计数用 i64 再转 usize：usize 无符号比较在 OVM 运行时缺 host import。
micro hardware_cpu_transfer<T>(data: [T]) -> [T] {
    let mut copied: [T] = []
    let size: i64 = data.length() as i64
    let mut index: i64 = 0
    while index < size {
        copied = push(copied, std::collection::array::get(data, index as usize))
        index = index + 1
    }
    return copied
}

# CPU map 执行体：同步逐元素应用 mapper。
micro hardware_cpu_map<T, U>(input: [T], mapper: micro(T) -> U) -> [U] {
    let mut output: [U] = []
    let size: i64 = input.length() as i64
    let mut index: i64 = 0
    while index < size {
        output = push(output, mapper(std::collection::array::get(input, index as usize)))
        index = index + 1
    }
    return output
}
