namespace database;

# Cursor — 有序迭代。
#
# 游标在创建时刻冻结行快照（值语义），之后的引擎写入不影响本次迭代：
# 迭代一致性由构造保证，不加锁。游标只读。
# `_rows` 已按表空间与前缀过滤并升序排列；`_reverse` 只改变迭代方向，
# 不改变快照内容。反向游标需要引擎声明 `cap_reverse_cursor`。
class DatabaseCursor {
    _rows: [DatabaseRecord]
    _reverse: bool
    _index: i64
}

# 游标构造共享入口：表未注册即 `table_missing`。
micro database_cursor_build(rows: [DatabaseRecord], tables: [[u8]], table: [u8], prefix: [u8], use_prefix: bool, reverse: bool) -> Result<DatabaseCursor, DatabaseFault> {
    if !database_catalog_tables_have(tables, table) {
        return Fail(DatabaseFault { code: database_fault_table_missing() })
    }
    let mut filtered: [DatabaseRecord] = []
    let size: i64 = rows.length() as i64
    let mut cursor: i64 = 0
    while cursor < size {
        let row: DatabaseRecord = std::collection::array::get(rows, cursor as usize)
        if database_bytes_equal(row.table, table) {
            if !use_prefix || database_bytes_have_prefix(row.key, prefix) {
                filtered = push(filtered, row)
            }
        }
        cursor = cursor + 1
    }
    return Fine(DatabaseCursor {
        _rows: filtered,
        _reverse: reverse,
        _index: -1
    })
}

micro database_catalog_tables_have(tables: [[u8]], table: [u8]) -> bool {
    let count: i64 = tables.length() as i64
    let mut index: i64 = 0
    while index < count {
        if database_bytes_equal(std::collection::array::get(tables, index as usize), table) {
            return true
        }
        index = index + 1
    }
    return false
}

imply DatabaseEngine {
    # 全表正向游标。
    micro cursor(self, table: [u8]) -> Result<DatabaseCursor, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        return database_cursor_build(self._rows, self._tables, table, [], false, false)
    }

    # 前缀正向游标：只迭代键带指定前缀的记录。
    micro cursor_prefix(self, table: [u8], prefix: [u8]) -> Result<DatabaseCursor, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        return database_cursor_build(self._rows, self._tables, table, prefix, true, false)
    }

    # 全表反向游标；引擎未声明反向能力即 `capability_missing`。
    micro cursor_reverse(self, table: [u8]) -> Result<DatabaseCursor, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        if !self._cap_reverse_cursor {
            return Fail(DatabaseFault { code: database_fault_capability_missing() })
        }
        return database_cursor_build(self._rows, self._tables, table, [], false, true)
    }
}

imply DatabaseCursor {
    # 定位到迭代序首条；空游标返回 false 且保持无效。
    micro first(mut self) -> bool {
        let size: i64 = self._rows.length() as i64
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

    # 定位到迭代序末条；空游标返回 false 且保持无效。
    micro last(mut self) -> bool {
        let size: i64 = self._rows.length() as i64
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

    # 定位：正向为首个 key >= target，反向为首个（迭代序）key <= target。
    # 未命中返回 false 且保持无效。
    micro seek(mut self, target: [u8]) -> bool {
        let size: i64 = self._rows.length() as i64
        let mut cursor: i64 = 0
        while cursor < size {
            let row: DatabaseRecord = std::collection::array::get(self._rows, cursor as usize)
            let order: i64 = database_compare_bytes(row.key, target)
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
        let size: i64 = self._rows.length() as i64
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
        let size: i64 = self._rows.length() as i64
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

    # 无效位置取用即 `cursor_invalid`（硬失败，调用方先验 `valid`）。
    micro key(self) -> Result<[u8], DatabaseFault> {
        if self._index < 0 {
            return Fail(DatabaseFault { code: database_fault_cursor_invalid() })
        }
        let row: DatabaseRecord = std::collection::array::get(self._rows, self._index as usize)
        return Fine(row.key)
    }

    micro value(self) -> Result<[u8], DatabaseFault> {
        if self._index < 0 {
            return Fail(DatabaseFault { code: database_fault_cursor_invalid() })
        }
        let row: DatabaseRecord = std::collection::array::get(self._rows, self._index as usize)
        return Fine(row.value)
    }

    micro cursor_revision(self) -> Result<i64, DatabaseFault> {
        if self._index < 0 {
            return Fail(DatabaseFault { code: database_fault_cursor_invalid() })
        }
        let row: DatabaseRecord = std::collection::array::get(self._rows, self._index as usize)
        return Fine(row.revision)
    }
}
