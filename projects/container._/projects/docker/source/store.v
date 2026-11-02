namespace container.docker;

using container::{MemoryContentStore, container_memory_store_new};

# Docker 的 content store 就是 container 核心的 MemoryContentStore（共享实现）。
# 不另起炉灶，保证与 oci 走同一套 conformance。

micro docker_shared_store_new() -> MemoryContentStore {
    return container_memory_store_new()
}
