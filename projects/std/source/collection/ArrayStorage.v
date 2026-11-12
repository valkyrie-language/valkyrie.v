namespace std.collection;

# ArrayStorage：带初始化范围标记的容量存储。
#
# 容量与有效性分离：
# - `_slots` 是 host 分配的容量载体（`std.collection.array::allocate`），槽位不是元素；
# - `_initialized` 是初始化前沿：只有 `[0, _initialized)` 是有效元素，前沿之外
#   的槽位禁止当普通 `[T]` 读出。
#
# 写入只有两条路：
# - `initialize`：恰好在前沿写一格，前沿同步前进——这是唯一的初始化路径；
# - `set`：已初始化区域内的覆写，不改变前沿。
# `place` 按偏移自动择其一，供序列容器追加/搬移使用。
#
# 分配与 GC 语义归 host provider（载体经 `array::allocate` 取得）；有效性语义
# 收归 std（本类型的前沿账目）。
class ArrayStorage<T> {
    _slots: [T]
    _initialized: usize
}

imply ArrayStorage<T> {
    # 取得 `capacity` 个容量槽位；一个都未初始化。
    micro with_capacity(capacity: usize): Self {
        return ArrayStorage { _slots: std::collection::array::allocate::<T>(capacity), _initialized: 0 }
    }

    # 容量（槽位总数）。
    micro capacity(self): usize {
        return self._slots.length
    }

    # 初始化前沿（有效元素个数上界）。
    micro initialized(self): usize {
        return self._initialized
    }

    # 唯一初始化路径：恰好在前沿槽写入，前沿前进一格；容量耗尽结构化失败。
    micro initialize(mut self, value: T): unit {
        if self._initialized >= self._slots.length {
            std::types::panic("ArrayStorage initialize：容量槽位已耗尽")
        }

        self._slots⁅self._initialized⁆ = value
        self._initialized = self._initialized + 1
    }

    # 已初始化区域内的覆写：不改变前沿；越出区域结构化失败。
    micro set(mut self, offset: usize, value: T): unit {
        if offset >= self._initialized {
            std::types::panic("ArrayStorage set：写入未初始化槽位")
        }

        self._slots⁅offset⁆ = value
    }

    # 已初始化区域内的读取；未初始化槽位不是元素，返回 `None`，不伪造成员值。
    micro get(self, offset: usize): Option<T> {
        if offset >= self._initialized {
            return None
        }

        return Some(self._slots⁅offset⁆)
    }

    # 按偏移落子：前沿处即初始化，区域内即覆写，其余是跳写（合同违例）。
    micro place(mut self, offset: usize, value: T): unit {
        if offset == self._initialized {
            self.initialize(value)
            return
        }

        self.set(offset, value)
    }

    # 终局化：只有全部容量槽位都已初始化，载体才整体作为可读 `[T]` 交出。
    micro finalize(self): [T] {
        if self._initialized < self._slots.length {
            std::types::panic("ArrayStorage finalize：存在未初始化槽位")
        }

        return self._slots
    }

    # 有效前缀的零拷贝窗口：`count` 必须落在已初始化区域内。
    micro window(self, count: usize): ArrayView<T> {
        if count > self._initialized {
            std::types::panic("ArrayStorage window：窗口越过初始化前沿")
        }

        return ArrayView { _source: self._slots, _offset: 0, _length: count }
    }
}
