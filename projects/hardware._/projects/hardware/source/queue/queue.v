namespace hardware;

# Queue — 绑定设备的命令队列。CPU 后端同步执行。
#
# 与 Buffer 同理，设备关联以身份标量存储；`cap_map_kernel`
# 在创建时从设备描述快照读入，供调度准入检查。
class Queue {
    _backend_token: i64
    _device_ordinal: i64
    _device_kind: i64
    _cap_map_kernel: bool
    _submitted: i64
}

imply Queue {
    # 在设备上创建空队列。
    micro create(device: Device) -> Self {
        return Queue {
            _backend_token: device.backend_token,
            _device_ordinal: device.ordinal,
            _device_kind: device.kind,
            _cap_map_kernel: device.cap_map_kernel,
            _submitted: 0,
        }
    }

    # 后端数值身份。
    micro backend_token(self) -> i64 {
        return self._backend_token
    }

    # 后端内设备序号。
    micro device_ordinal(self) -> i64 {
        return self._device_ordinal
    }

    # 累计已提交批次数。
    micro submitted(self) -> i64 {
        return self._submitted
    }

    # 等待队列清空。CPU 后端提交即完成，wait 为空操作；
    # 异步后端的 fence 语义经 host capability 接入（后续块）。
    micro wait(self) -> unit {
        return
    }

    # 提交计数累加。仅调度路径在成功提交后调用。
    micro record_submission(mut self) -> unit {
        self._submitted = self._submitted + 1
    }
}

# map kernel 调度：逐元素应用 mapper，产出同设备的新缓冲。
#
# 校验顺序：队列与输入缓冲同设备（device_mismatch）→ 设备声明 map_kernel 能力
# （capability_missing）→ 后端已注册（backend_unavailable）。
# CPU 后端同步执行并在成功后累加提交计数。
#
# 自由函数形态：方法级泛型（`imply` 内 `<T, U>`）与函数值实参的组合在当前编译器
# 调用点不可解析，故调度入口为自由函数；`queue` 为 class 引用，
# 提交计数经 `record_submission` 写回同一实例。
micro hardware_dispatch_map<T, U>(queue: Queue, input: Buffer<T>, mapper: micro(T) -> U) -> Result<Buffer<U>, HardwareFault> {
    if queue.backend_token() != input.backend_token() || queue.device_ordinal() != input.device_ordinal() {
        return Fail(HardwareFault { code: hardware_fault_device_mismatch() })
    }
    if !queue._cap_map_kernel {
        return Fail(HardwareFault { code: hardware_fault_capability_missing() })
    }
    if queue.backend_token() != hardware_backend_cpu() {
        return Fail(HardwareFault { code: hardware_fault_backend_unavailable() })
    }
    let output: [U] = hardware_cpu_map(input.read(), mapper)
    let mut active: Queue = queue
    active.record_submission()
    return Fine(hardware_buffer_with_identity(input.backend_token(), input.device_ordinal(), input.device_kind(), output))
}
