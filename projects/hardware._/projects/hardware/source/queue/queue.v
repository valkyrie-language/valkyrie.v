namespace hardware;

# L3 队列层：队列族/命令缓冲/Fence（合同声明，实现见对应块）。

# QueueFamily 词汇。
micro hardware_queue_compute() -> i64 {
    return 1
}

micro hardware_queue_transfer() -> i64 {
    return 2
}

micro hardware_queue_graphics() -> i64 {
    return 3
}

# CommandBuffer 状态词汇。
micro hardware_command_recording() -> i64 {
    return 1
}

micro hardware_command_ended() -> i64 {
    return 2
}

micro hardware_command_submitted() -> i64 {
    return 3
}

# Queue — 绑定设备与队列族的提交通道。
class Queue {
    _backend: i64
    _device_ordinal: i64
    _family: i64
    _ordinal: i64
    _submitted: i64
}

# CommandBuffer — 命令录制载体（状态机 + 录制记账）。
class CommandBuffer {
    _family: i64
    _state: i64
    _recorded_ops: i64
}

# Fence — 时间线同步原语（value 单调递增）。
class Fence {
    _backend: i64
    _device_ordinal: i64
    _value: i64
}
