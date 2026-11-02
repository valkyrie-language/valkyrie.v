namespace yyds.kv;

# KvShardCursor — 分片有序游标（范围扫描载体）。
#
# 创建时刻冻结记录快照（分片记录为函数式不可变，共享安全）：之后的写入
# 不影响本次迭代。游标只读，作用域固定为单命名空间（可选键前缀）。
# 状态机：新建未定位；`first`/`last`/`seek` 命中进入定位态；
# `next`/`prev` 越界回到未定位；未定位取用一律 `kv_fault_cursor_invalid`。
class KvShardCursor {
    _records: [KvRecord]
    _index: i64
    _reverse: bool
}

# 单命名空间全量正向游标。
micro kv_memory_cursor_in(shard: KvMemoryShard, space: utf8) -> KvShardCursor {
    return kv_cursor_build(shard, space, [], false, false)
}

# 单命名空间前缀正向游标。
micro kv_memory_cursor_prefix(shard: KvMemoryShard, space: utf8, prefix: [u8]) -> KvShardCursor {
    return kv_cursor_build(shard, space, prefix, true, false)
}

# 单命名空间范围游标：lower 含、upper 不含（None 不设该端）。
micro kv_memory_cursor_range(shard: KvMemoryShard, space: utf8, lower: Option<[u8]>, upper: Option<[u8]>) -> KvShardCursor {
    let mut filtered: [KvRecord] = []
    let mut index: usize = 0
    while index < shard.records.length() {
        let record: KvRecord = shard.records⁅index⁆
        index = index + 1
        if !record.key.space.equals(space) {
            continue
        }
        if !kv_cursor_in_range(record.key.bytes, lower, upper) {
            continue
        }
        filtered = push(filtered, record)
    }
    return KvShardCursor {
        _records: filtered,
        _index: -1,
        _reverse: false
    }
}

# 单命名空间反向游标。
micro kv_memory_cursor_reverse(shard: KvMemoryShard, space: utf8) -> KvShardCursor {
    return kv_cursor_build(shard, space, [], false, true)
}

micro kv_cursor_build(shard: KvMemoryShard, space: utf8, prefix: [u8], use_prefix: bool, reverse: bool) -> KvShardCursor {
    let mut filtered: [KvRecord] = []
    let mut index: usize = 0
    while index < shard.records.length() {
        let record: KvRecord = shard.records⁅index⁆
        index = index + 1
        if !record.key.space.equals(space) {
            continue
        }
        if use_prefix && !kv_bytes_have_prefix(record.key.bytes, prefix) {
            continue
        }
        filtered = push(filtered, record)
    }
    return KvShardCursor {
        _records: filtered,
        _index: -1,
        _reverse: reverse
    }
}

micro kv_cursor_in_range(bytes: [u8], lower: Option<[u8]>, upper: Option<[u8]>) -> bool {
    if lower.is_some() {
        if kv_compare_bytes(bytes, lower.unwrap()) < 0 {
            return false
        }
    }
    if upper.is_some() {
        if kv_compare_bytes(bytes, upper.unwrap()) >= 0 {
            return false
        }
    }
    return true
}

imply KvShardCursor {
    # 定位到迭代序首条；空游标返回 false 且保持未定位。
    micro first(mut self) -> bool {
        let size: i64 = self._records.length() as i64
        if size == 0 {
            self._index = -1
            return false
        }
        if self._reverse {
            self._index = size - 1
            return true
        }
        self._index = 0
        return true
    }

    # 定位到迭代序末条。
    micro last(mut self) -> bool {
        let size: i64 = self._records.length() as i64
        if size == 0 {
            self._index = -1
            return false
        }
        if self._reverse {
            self._index = 0
            return true
        }
        self._index = size - 1
        return true
    }

    # 定位：正向为首个 key >= target，反向为迭代序首个 key <= target。
    micro seek(mut self, target: [u8]) -> bool {
        let size: i64 = self._records.length() as i64
        let mut cursor: i64 = 0
        while cursor < size {
            let record: KvRecord = self._records⁅cursor as usize⁆
            let order: i32 = kv_compare_bytes(record.key.bytes, target)
            if self._reverse {
                if order <= 0 {
                    self._index = cursor
                    return true
                }
            }
            else {
                if order >= 0 {
                    self._index = cursor
                    return true
                }
            }
            cursor = cursor + 1
        }
        self._index = -1
        return false
    }

    # 沿迭代方向前进一步；越界后失效并返回 false。
    micro next(mut self) -> bool {
        let size: i64 = self._records.length() as i64
        if self._index < 0 {
            return false
        }
        if self._reverse {
            self._index = self._index - 1
        }
        else {
            self._index = self._index + 1
        }
        if self._index < 0 || self._index >= size {
            self._index = -1
            return false
        }
        return true
    }

    # 逆迭代方向回退一步；越界后失效并返回 false。
    micro prev(mut self) -> bool {
        let size: i64 = self._records.length() as i64
        if self._index < 0 {
            return false
        }
        if self._reverse {
            self._index = self._index + 1
        }
        else {
            self._index = self._index - 1
        }
        if self._index < 0 || self._index >= size {
            self._index = -1
            return false
        }
        return true
    }

    micro valid(self) -> bool {
        return self._index >= 0
    }

    # 未定位取用即 `kv_fault_cursor_invalid`（硬失败，调用方先验 `valid`）。
    micro record(self) -> Result<KvRecord, KvFault> {
        if self._index < 0 {
            return Fail(KvFault { code: kv_fault_cursor_invalid() })
        }
        return Fine(self._records⁅self._index as usize⁆)
    }
}
