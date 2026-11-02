namespace container;

# 内存 ContentStore 实现：纯数组条目列表（避免 HashMap 在 ovm lane 的
# `⁅ ⁆`/`infix ==` unresolved_call 泛洪；去重语义不变，寻址仍是 O(n) 线性查找）。
#
# 条目：digest 字符串键 → 字节 + 首次记录的 media type。put 按内容重算 sha256
# 寻址实现去重；get/exists 线性扫描。硬失败走 `ContainerFailure`。

structure MemoryBlobEntry {
    key: utf8
    media_type: utf8
    bytes: [u8]
}

structure MemoryContentStore {
    entries: [MemoryBlobEntry]
}

micro container_memory_store_new() -> MemoryContentStore {
    return MemoryContentStore { entries: [] }
}

micro container_memory_store_key(digest: Digest) -> utf8 {
    return container_digest_to_string(digest)
}

micro container_memory_store_find_index(store: MemoryContentStore, key: utf8) -> i64 {
    let mut index: usize = 0
    while index < store.entries.length() {
        if std::collection::array::get(store.entries, index).key == key {
            return index as i64
        }
        index = index + 1
    }
    return -1
}

micro container_memory_store_has(store: MemoryContentStore, key: utf8) -> bool {
    return container_memory_store_find_index(store, key) >= 0
}

imply MemoryContentStore: ContentStore {
    micro put(mut self, media_type: utf8, bytes: [u8]) -> Descriptor {
        let digest: Digest = container_digest_of(container_digest_algorithm_sha256(), bytes)
        let key: utf8 = container_memory_store_key(digest)
        let size: i64 = bytes.length() as i64
        if !container_memory_store_has(self, key) {
            self.entries = push(self.entries, MemoryBlobEntry { key: key, media_type: media_type, bytes: bytes })
        }
        return container_descriptor_new(media_type, digest, size)
    }

    micro get(self, digest: Digest) -> [u8] {
        let key: utf8 = container_memory_store_key(digest)
        let index: i64 = container_memory_store_find_index(self, key)
        if index < 0 {
            container_failure_raise_storage("container.store.not_found", "blob 不存在：" + key)
        }
        return std::collection::array::get(self.entries, index as usize).bytes
    }

    micro exists(self, digest: Digest) -> bool {
        return container_memory_store_has(self, container_memory_store_key(digest))
    }

    micro remove(mut self, digest: Digest) -> bool {
        let key: utf8 = container_memory_store_key(digest)
        let target: i64 = container_memory_store_find_index(self, key)
        if target < 0 {
            return false
        }
        let mut next: [MemoryBlobEntry] = []
        let mut index: usize = 0
        while index < self.entries.length() {
            if index != (target as usize) {
                next = push(next, std::collection::array::get(self.entries, index))
            }
            index = index + 1
        }
        self.entries = next
        return true
    }
}

# 读取已存 blob 的 media type（不存在返回 None）。
micro container_memory_store_media_type(store: MemoryContentStore, digest: Digest) -> Option<utf8> {
    let index: i64 = container_memory_store_find_index(store, container_memory_store_key(digest))
    if index < 0 {
        return None
    }
    return Some(std::collection::array::get(store.entries, index as usize).media_type)
}
