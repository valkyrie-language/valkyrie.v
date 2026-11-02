namespace database;

# Catalog：表空间注册表。
#
# 表空间即命名空间：不同表的键域互不共享，扫描必带表空间。
# catalog_revision 随每次建表/删表递增，是 schema 变更的单调序号。

micro database_engine_table_exists(engine: DatabaseEngine, table: [u8]) -> bool {
    let count: i64 = engine._tables.length() as i64
    let mut index: i64 = 0
    while index < count {
        let existing: [u8] = std::collection::array::get(engine._tables, index as usize)
        if database_bytes_equal(existing, table) {
            return true
        }
        index = index + 1
    }
    return false
}

imply DatabaseEngine {
    # 建表：空名即 `table_invalid`，重名即 `table_exists`；成功返回新 catalog revision。
    micro create_table(mut self, table: [u8]) -> Result<i64, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        let name_size: i64 = table.length() as i64
        if name_size == 0 {
            return Fail(DatabaseFault { code: database_fault_table_invalid() })
        }
        if database_engine_table_exists(self, table) {
            return Fail(DatabaseFault { code: database_fault_table_exists() })
        }
        let revision: i64 = self._next_revision + 1
        database_engine_journal(self, database_journal_op_create_table(), table, [], [], revision)
        self._tables = push(self._tables, table)
        self._catalog_revision = self._catalog_revision + 1
        self._next_revision = revision
        return Fine(self._catalog_revision)
    }

    # 删表：表未注册即 `table_missing`；连表带行整体移除，不可部分生效。
    micro drop_table(mut self, table: [u8]) -> Result<i64, DatabaseFault> {
        if !self.is_open() {
            return Fail(DatabaseFault { code: database_fault_engine_closed() })
        }
        if !database_engine_table_exists(self, table) {
            return Fail(DatabaseFault { code: database_fault_table_missing() })
        }
        let revision: i64 = self._next_revision + 1
        database_engine_journal(self, database_journal_op_drop_table(), table, [], [], revision)
        self._tables = database_engine_tables_remove(self._tables, table)
        self._rows = database_engine_rows_drop_table(self._rows, table)
        self._catalog_revision = self._catalog_revision + 1
        self._next_revision = revision
        return Fine(self._catalog_revision)
    }

    micro table_exists(self, table: [u8]) -> bool {
        return database_engine_table_exists(self, table)
    }

    micro list_tables(self) -> [[u8]] {
        return self._tables
    }

    micro table_count(self) -> i64 {
        return self._tables.length() as i64
    }
}

micro database_engine_tables_remove(tables: [[u8]], table: [u8]) -> [[u8]] {
    let mut rebuilt: [[u8]] = []
    let count: i64 = tables.length() as i64
    let mut index: i64 = 0
    while index < count {
        let existing: [u8] = std::collection::array::get(tables, index as usize)
        if !database_bytes_equal(existing, table) {
            rebuilt = push(rebuilt, existing)
        }
        index = index + 1
    }
    return rebuilt
}

micro database_engine_rows_drop_table(rows: [DatabaseRecord], table: [u8]) -> [DatabaseRecord] {
    let mut rebuilt: [DatabaseRecord] = []
    let size: i64 = rows.length() as i64
    let mut cursor: i64 = 0
    while cursor < size {
        let row: DatabaseRecord = std::collection::array::get(rows, cursor as usize)
        if !database_bytes_equal(row.table, table) {
            rebuilt = push(rebuilt, row)
        }
        cursor = cursor + 1
    }
    return rebuilt
}
