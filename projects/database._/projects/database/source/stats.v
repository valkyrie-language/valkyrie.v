namespace database;

# 观测：尺寸估算与统计。
#
# 估算是诚实的下界近似：逐记录 键长 + 值长 + 记录结构常数（32），
# 不含索引/日志放大；后端各自在文档中登记口径，不冒充精确占用。

micro database_stats_record_overhead() -> i64 {
    return 32
}

imply DatabaseEngine {
    # 占用估算（字节）：全部记录 键 + 值 + 记录开销。
    micro estimate_size(self) -> i64 {
        let mut total: i64 = 0
        let size: i64 = self._rows.length() as i64
        let mut cursor: i64 = 0
        while cursor < size {
            let row: DatabaseRecord = std::collection::array::get(self._rows, cursor as usize)
            let key_size: i64 = row.key.length() as i64
            let value_size: i64 = row.value.length() as i64
            total = total + key_size + value_size + database_stats_record_overhead()
            cursor = cursor + 1
        }
        return total
    }

    micro record_count(self) -> i64 {
        return self._rows.length() as i64
    }

    # 单表记录数；表未注册即 `table_missing`。
    micro table_records(self, table: [u8]) -> Result<i64, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        if !database_engine_table_exists(self, table) {
            return Fail(DatabaseFault { code: database_fault_table_missing() })
        }
        let mut total: i64 = 0
        let size: i64 = self._rows.length() as i64
        let mut cursor: i64 = 0
        while cursor < size {
            let row: DatabaseRecord = std::collection::array::get(self._rows, cursor as usize)
            if database_bytes_equal(row.table, table) {
                total = total + 1
            }
            cursor = cursor + 1
        }
        return Fine(total)
    }

    micro flush_calls(self) -> i64 {
        return self._flush_calls
    }
}
