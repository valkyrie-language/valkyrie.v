namespace database;

# 引擎记录：表空间 + 键 + 值 + revision，全部第一级字段。
#
# 表空间即命名空间：不同表的键域互不共享，扫描必带表空间。
# 记录在引擎内按（表空间, 键）无符号字节字典序排列。
# revision 在引擎内单调递增，每次成功写入消耗一个新 revision。
structure DatabaseRecord {
    table: [u8]
    key: [u8]
    value: [u8]
    revision: i64
}

micro database_record(table: [u8], key: [u8], value: [u8], revision: i64) -> DatabaseRecord {
    return DatabaseRecord {
        table: table,
        key: key,
        value: value,
        revision: revision
    }
}

# 记录序：先表空间，再键（均按无符号字节字典序）。
micro database_compare_records(a: DatabaseRecord, b: DatabaseRecord) -> i64 {
    let by_table: i64 = database_compare_bytes(a.table, b.table)
    if by_table != 0 {
        return by_table
    }
    return database_compare_bytes(a.key, b.key)
}

micro database_record_identity_equals(a: DatabaseRecord, table: [u8], key: [u8]) -> bool {
    if !database_bytes_equal(a.table, table) {
        return false
    }
    return database_bytes_equal(a.key, key)
}
