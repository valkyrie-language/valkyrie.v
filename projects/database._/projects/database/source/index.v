namespace database;

# 索引抽象（trait 面）。
#
# 有序索引与哈希索引是两类不同的能力：有序索引支持范围与顺序迭代，
# 哈希索引只支持点查。引擎声明各自能力（`cap_ordered_index` / `cap_hash_index`），
# 缺能力的索引操作一律 `capability_missing`，不以另一种索引冒充。
# 键与载荷均为不透明字节；索引不拥有值语义，只做键到载荷的映射。

# 有序索引：键按无符号字节字典序排列，支持范围查询。
trait DatabaseOrderedIndex {
    # 插入或替换键的载荷。
    micro index_insert(mut self, key: [u8], payload: [u8]) -> unit
    # 删除键；返回是否移除。
    micro index_remove(mut self, key: [u8]) -> bool
    # 点查。
    micro index_lookup(self, key: [u8]) -> Option<[u8]>
    # 范围枚举：`lower` 含、`upper` 不含，`limit` 为 0 表示不设上限；
    # 返回键按字典序升序。
    micro index_range(self, lower: Option<[u8]>, upper: Option<[u8]>, limit: i64) -> [[u8]]
    # 键总数。
    micro index_len(self) -> i64
}

# 哈希索引：只承诺点查；范围/顺序不在合同内。
trait DatabaseHashIndex {
    micro hash_insert(mut self, key: [u8], payload: [u8]) -> unit
    micro hash_remove(mut self, key: [u8]) -> bool
    micro hash_lookup(self, key: [u8]) -> Option<[u8]>
    micro hash_len(self) -> i64
}

# 内存有序索引见证实现：平行有序数组（键升序），纯 V 参考语义。
class MemoryOrderedIndex {
    _keys: [[u8]]
    _payloads: [[u8]]
}

imply MemoryOrderedIndex {
    micro new() -> Self {
        return MemoryOrderedIndex {
            _keys: [],
            _payloads: []
        }
    }
}

# 二分定位：返回键所在下标（0 基）；缺失时返回有序插入位置。
micro database_index_slot(index: MemoryOrderedIndex, key: [u8]) -> DatabaseSlot {
    let mut low: i64 = 0
    let mut high: i64 = index._keys.length() as i64
    while low < high {
        let middle: i64 = (low + high) / 2
        let order: i64 = database_compare_bytes(std::collection::array::get(index._keys, middle as usize), key)
        if order == 0 {
            return Found { index: middle }
        }
        if order < 0 {
            low = middle + 1
        }
        else {
            high = middle
        }
    }
    return Absent { insert_at: low }
}

imply MemoryOrderedIndex: DatabaseOrderedIndex {
    micro index_insert(mut self, key: [u8], payload: [u8]) -> unit {
        let slot: DatabaseSlot = database_index_slot(self, key)
        let at: i64 = database_slot_index(slot)
        let mut keys: [[u8]] = []
        let mut payloads: [[u8]] = []
        let size: i64 = self._keys.length() as i64
        let mut cursor: i64 = 0
        while cursor < size {
            if cursor == at {
                keys = push(keys, key)
                payloads = push(payloads, payload)
            }
            if database_slot_is_absent(slot) || cursor != at {
                keys = push(keys, std::collection::array::get(self._keys, cursor as usize))
                payloads = push(payloads, std::collection::array::get(self._payloads, cursor as usize))
            }
            cursor = cursor + 1
        }
        if at >= size {
            keys = push(keys, key)
            payloads = push(payloads, payload)
        }
        self._keys = keys
        self._payloads = payloads
    }

    micro index_remove(mut self, key: [u8]) -> bool {
        let slot: DatabaseSlot = database_index_slot(self, key)
        if database_slot_is_absent(slot) {
            return false
        }
        let at: i64 = database_slot_index(slot)
        let mut keys: [[u8]] = []
        let mut payloads: [[u8]] = []
        let size: i64 = self._keys.length() as i64
        let mut cursor: i64 = 0
        while cursor < size {
            if cursor != at {
                keys = push(keys, std::collection::array::get(self._keys, cursor as usize))
                payloads = push(payloads, std::collection::array::get(self._payloads, cursor as usize))
            }
            cursor = cursor + 1
        }
        self._keys = keys
        self._payloads = payloads
        return true
    }

    micro index_lookup(self, key: [u8]) -> Option<[u8]> {
        let slot: DatabaseSlot = database_index_slot(self, key)
        if database_slot_is_absent(slot) {
            return None
        }
        return Some(std::collection::array::get(self._payloads, database_slot_index(slot) as usize))
    }

    micro index_range(self, lower: Option<[u8]>, upper: Option<[u8]>, limit: i64) -> [[u8]] {
        let mut out: [[u8]] = []
        let size: i64 = self._keys.length() as i64
        let mut cursor: i64 = 0
        while cursor < size {
            let key: [u8] = std::collection::array::get(self._keys, cursor as usize)
            if database_index_in_range(key, lower, upper) {
                out = push(out, key)
                if limit > 0 && out.length() as i64 >= limit {
                    return out
                }
            }
            cursor = cursor + 1
        }
        return out
    }

    micro index_len(self) -> i64 {
        return self._keys.length() as i64
    }
}

# 范围判定：lower 含、upper 不含；None 不设该端。
micro database_index_in_range(key: [u8], lower: Option<[u8]>, upper: Option<[u8]>) -> bool {
    if lower.is_some() {
        if database_compare_bytes(key, lower.unwrap()) < 0 {
            return false
        }
    }
    if upper.is_some() {
        if database_compare_bytes(key, upper.unwrap()) >= 0 {
            return false
        }
    }
    return true
}
