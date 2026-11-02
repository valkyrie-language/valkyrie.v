namespace hardware;

# Buffer<T> — 绑定设备的元素缓冲。CPU 后端以值语义数组承载。
#
# 设备关联以身份标量（backend_token/ordinal/kind）存储而非 Device 值：
# 聚合嵌套聚合在当前工具链不可物化；
# 身份问题经 `backend_token()` / `device_ordinal()` / `hardware_buffer_on_device` 回答。
class Buffer<T> {
    _backend_token: i64
    _device_ordinal: i64
    _device_kind: i64
    _elements: [T]
}

imply Buffer<T> {
    # 在设备上创建缓冲并写入初始内容（host→device）。
    micro create(device: Device, data: [T]) -> Self {
        return Buffer {
            _backend_token: device.backend_token,
            _device_ordinal: device.ordinal,
            _device_kind: device.kind,
            _elements: data,
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

    # 设备类别（`hardware_device_kind_*`）。
    micro device_kind(self) -> i64 {
        return self._device_kind
    }

    # 元素个数。
    micro length(self) -> usize {
        return self._elements.length()
    }

    # 计数比较先转 i64：usize 无符号比较在 OVM 运行时缺 host import。
    micro is_empty(self) -> bool {
        return self._elements.length() as i64 == 0
    }

    # host→device 写入：整体替换缓冲内容。
    micro write(mut self, data: [T]) -> unit {
        self._elements = data
    }

    # device→host 读回：值语义快照（后续 write 不影响已读出的数组）。
    micro read(self) -> [T] {
        return self._elements
    }

    # device↔device 传输：在目标设备上产出内容一致的新缓冲。
    # 两端均为已注册 CPU 后端时执行本地拷贝；任一端为外部后端且无 provider 时
    # Fail(hardware_fault_backend_unavailable())，不伪造传输。
    micro transfer_to(self, target: Device) -> Result<Buffer<T>, HardwareFault> {
        if self._backend_token != hardware_backend_cpu() || target.backend_token != hardware_backend_cpu() {
            return Fail(HardwareFault { code: hardware_fault_backend_unavailable() })
        }
        return Fine(Buffer::create(target, hardware_cpu_transfer(self.read())))
    }
}

# 缓冲身份核对：是否绑定指定设备（backend_token + ordinal 双因子）。
micro hardware_buffer_on_device<T>(buffer: Buffer<T>, device: Device) -> bool {
    return buffer.backend_token() == device.backend_token && buffer.device_ordinal() == device.ordinal
}

# 由身份标量直接构造：调度路径内部使用，输出缓冲继承输入设备身份，
# 不从注册表重建设备描述（避免伪造能力事实）。
micro hardware_buffer_with_identity<T>(backend_token: i64, device_ordinal: i64, device_kind: i64, data: [T]) -> Buffer<T> {
    return Buffer {
        _backend_token: backend_token,
        _device_ordinal: device_ordinal,
        _device_kind: device_kind,
        _elements: data,
    }
}
