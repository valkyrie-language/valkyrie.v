namespace container;

# 运行时模型：Container 生命周期、Rootfs/快照、挂载与网络命名空间、资源限制。
#
# 只立抽象位（合同），具体 runc/namespace/cgroup 绑定由实现侧完成。
# 非法状态迁移是硬失败（RuntimeFailure：container.runtime.invalid_state）。

unite ContainerState {
    StateCreated
    StateRunning
    StateStopped
    StateExited
}

structure Mount {
    source: utf8
    target: utf8
    read_only: bool
}

structure ResourceLimits {
    cpu_milli: i64
    memory_bytes: i64
    pids: i64
}

structure Rootfs {
    # 由层链叠加得到的快照标识（实现侧决定形态）。
    snapshot_id: utf8
    mounts: [Mount]
}

structure Container {
    id: utf8
    image: Reference
    state: ContainerState
    rootfs: Option<Rootfs>
    limits: ResourceLimits
}

micro container_runtime_new(id: utf8, image: Reference, limits: ResourceLimits) -> Container {
    return Container { id: id, image: image, state: StateCreated, rootfs: None, limits: limits }
}

micro container_runtime_state(container: Container) -> ContainerState {
    return container.state
}

# create → start：仅 StateCreated 可启动。
micro container_runtime_start(mut container: Container) -> Container {
    match container.state {
        case StateCreated: {
            container.state = StateRunning
            return container
        }
        case StateRunning:
            container_failure_raise_runtime("container.runtime.invalid_state", "容器已在运行")
        case StateStopped:
            container_failure_raise_runtime("container.runtime.invalid_state", "已停容器不可直接启动")
        case StateExited:
            container_failure_raise_runtime("container.runtime.invalid_state", "已退出容器不可启动")
    }
}

# start → stop：仅 StateRunning 可停止。
micro container_runtime_stop(mut container: Container) -> Container {
    match container.state {
        case StateRunning: {
            container.state = StateStopped
            return container
        }
        case StateCreated:
            container_failure_raise_runtime("container.runtime.invalid_state", "未启动容器不可停止")
        case StateStopped:
            container_failure_raise_runtime("container.runtime.invalid_state", "容器已停止")
        case StateExited:
            container_failure_raise_runtime("container.runtime.invalid_state", "已退出容器不可停止")
    }
}

# exec：仅运行中可 exec（只校验状态，不改状态）。
micro container_runtime_can_exec(container: Container) -> bool {
    match container.state {
        case StateRunning: true
        case StateCreated: false
        case StateStopped: false
        case StateExited: false
    }
}

micro container_runtime_attach_rootfs(mut container: Container, rootfs: Rootfs) -> Container {
    container.rootfs = Some(rootfs)
    return container
}
