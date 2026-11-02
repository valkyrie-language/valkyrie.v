namespace container;

# 容器侧失败模型：硬失败。
#
# 区别于 `std.data` 的容许式诊断（`DataOutcome` 携带部分结果 + 诊断集合，错误容许
# 合同是不首错返回），容器侧操作**没有"部分成功的结果"**：blob 未写入就是没有
# blob，引用的 blob 缺失就是链断裂，没有中间态可供消费方降级。因此容器侧失败一律
# 走语言错误通道——`unite` 错误 + `raise`，由调用方 `handle` 或向上传播，不带部分值。
#
# `ContainerFailure` 是容器核心所有硬失败的唯一错误载体；`code` 是稳定机器可读
# 分类码（见下表），`detail` 是给人看的补充文本（可含具体 digest、media type 等）。

unite ContainerFailure {
    [constructor]
    StorageFailure {
        code: utf8
        detail: utf8
    }
    [constructor]
    IntegrityFailure {
        code: utf8
        detail: utf8
    }
    [constructor]
    RegistryFailure {
        code: utf8
        detail: utf8
    }
    [constructor]
    ReferenceFailure {
        code: utf8
        detail: utf8
    }
    [constructor]
    RuntimeFailure {
        code: utf8
        detail: utf8
    }
}

micro container_failure_code(failure: ContainerFailure) -> utf8 {
    match failure {
        case StorageFailure(payload):
            payload.code
        case IntegrityFailure(payload):
            payload.code
        case RegistryFailure(payload):
            payload.code
        case ReferenceFailure(payload):
            payload.code
        case RuntimeFailure(payload):
            payload.code
    }
}

micro container_failure_detail(failure: ContainerFailure) -> utf8 {
    match failure {
        case StorageFailure(payload):
            payload.detail
        case IntegrityFailure(payload):
            payload.detail
        case RegistryFailure(payload):
            payload.detail
        case ReferenceFailure(payload):
            payload.detail
        case RuntimeFailure(payload):
            payload.detail
    }
}

# 分类码表（稳定机器可读；每个码的语义见下）。
#
#   存储：
#     container.store.not_found        按 digest 寻址的 blob 不存在
#     container.store.corrupt          已存 blob 的内容与 digest 不符（去重失效信号）
#   完整性：
#     container.integrity.digest_mismatch  内容摘要与声明 digest 不一致
#     container.integrity.unknown_algorithm 摘要算法未注册（不可扩展调用点）
#   注册表：
#     container.registry.unreachable   registry 不可达
#     container.registry.not_found     引用在 registry 中不存在
#     container.registry.denied        registry 拒绝（认证/授权失败）
#   引用：
#     container.reference.invalid      引用字符串不符合 name:tag / digest 文法
#     container.reference.ambiguous    引用缺 tag 且未提供默认规则
#   运行时：
#     container.runtime.invalid_state  生命周期状态不允许该操作（如对已停的容器 start）
#     container.runtime.missing_rootfs 容器缺 rootfs/快照
micro container_failure_raise_storage(code: utf8, detail: utf8) -> ContainerFailure {
    raise StorageFailure { code: code, detail: detail }
}

micro container_failure_raise_integrity(code: utf8, detail: utf8) -> ContainerFailure {
    raise IntegrityFailure { code: code, detail: detail }
}

micro container_failure_raise_registry(code: utf8, detail: utf8) -> ContainerFailure {
    raise RegistryFailure { code: code, detail: detail }
}

micro container_failure_raise_reference(code: utf8, detail: utf8) -> ContainerFailure {
    raise ReferenceFailure { code: code, detail: detail }
}

micro container_failure_raise_runtime(code: utf8, detail: utf8) -> ContainerFailure {
    raise RuntimeFailure { code: code, detail: detail }
}
