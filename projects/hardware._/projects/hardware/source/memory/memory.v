namespace hardware;

# L2 内存层：堆/缓冲/map 会话（合同声明，实现见对应块）。

# HeapClass 词汇（内存可见性分类）。
micro hardware_heap_device_local() -> i64 {
    return 1
}

micro hardware_heap_host_visible() -> i64 {
    return 2
}

micro hardware_heap_unified() -> i64 {
    return 3
}

# BufferUsage 位掩码。
micro hardware_usage_storage_read() -> i64 {
    return 1
}

micro hardware_usage_storage_read_write() -> i64 {
    return 2
}

micro hardware_usage_uniform() -> i64 {
    return 4
}

micro hardware_usage_staging_upload() -> i64 {
    return 8
}

micro hardware_usage_staging_readback() -> i64 {
    return 16
}

micro hardware_usage_indirect() -> i64 {
    return 32
}

micro hardware_usage_map_read() -> i64 {
    return 64
}

micro hardware_usage_map_write() -> i64 {
    return 128
}

# Heap — 设备内存堆（不透明；容量与已分配记账驱动 OOM 语义）。
class Heap {
    _backend: i64
    _device_ordinal: i64
    _class: i64
    _capacity_elements: i64
    _allocated_elements: i64
}

# Buffer<T> — 堆上的元素缓冲。`_mapped` 与 `_map_epoch` 承担 map 会话纪律：
# map 发放递增 epoch 作为会话令牌，unmap 后旧令牌失效。
class Buffer<T> {
    _backend: i64
    _device_ordinal: i64
    _heap_class: i64
    _offset: i64
    _length: i64
    _usage: i64
    _mapped: bool
    _map_epoch: i64
    _elements: [T]
}
