namespace database.conformance;

# C15 索引 trait 面：内存有序索引见证（插入/替换/点查/范围/删除/计数）与能力声明。
micro conformance_c15_index_surface(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let engine: database::DatabaseEngine = database::database_outcome_must(open())
    if !engine.cap_ordered_index() {
        return 1
    }
    if engine.cap_hash_index() {
        return 2
    }
    let mut index: database::MemoryOrderedIndex = database::MemoryOrderedIndex::new()
    if index.index_len() != 0 {
        return 3
    }
    if index.index_lookup([1]).is_some() {
        return 4
    }
    index.index_insert([30], [3])
    index.index_insert([10], [1])
    index.index_insert([20], [2])
    if index.index_len() != 3 {
        return 5
    }
    let hit: Option<[u8]> = index.index_lookup([10])
    if hit.is_none() {
        return 6
    }
    if !database::database_bytes_equal(hit.unwrap(), [1]) {
        return 7
    }
    index.index_insert([10], [9])
    if index.index_len() != 3 {
        return 8
    }
    let replaced: Option<[u8]> = index.index_lookup([10])
    if !database::database_bytes_equal(replaced.unwrap(), [9]) {
        return 9
    }
    let all: [[u8]] = index.index_range(None, None, 0)
    let total: i64 = all.length() as i64
    if total != 3 {
        return 10
    }
    if !database::database_bytes_equal(std::collection::array::get(all, 0), [10]) {
        return 11
    }
    if !database::database_bytes_equal(std::collection::array::get(all, 2), [30]) {
        return 12
    }
    let window: [[u8]] = index.index_range(Some([15]), Some([30]), 0)
    let window_size: i64 = window.length() as i64
    if window_size != 1 {
        return 13
    }
    if !database::database_bytes_equal(std::collection::array::get(window, 0), [20]) {
        return 14
    }
    let capped: [[u8]] = index.index_range(None, None, 1)
    let capped_size: i64 = capped.length() as i64
    if capped_size != 1 {
        return 15
    }
    if !database::database_bytes_equal(std::collection::array::get(capped, 0), [10]) {
        return 16
    }
    if !index.index_remove([20]) {
        return 17
    }
    if index.index_remove([20]) {
        return 18
    }
    let after_remove: [[u8]] = index.index_range(None, None, 0)
    let remaining: i64 = after_remove.length() as i64
    if remaining != 2 {
        return 19
    }
    if !database::database_bytes_equal(std::collection::array::get(after_remove, 1), [30]) {
        return 20
    }
    return 0
}
