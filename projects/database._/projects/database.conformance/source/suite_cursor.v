namespace database.conformance;

# C4 游标：有序迭代、定位、前缀、反向、无效取用、创建时刻快照隔离。
micro conformance_c04_cursor(open: micro() -> Result<database::DatabaseEngine, database::DatabaseFault>) -> i64 {
    let mut engine: database::DatabaseEngine = database::database_outcome_must(open())
    let created: Result<i64, database::DatabaseFault> = engine.create_table([1])
    if !database::database_outcome_is_fine(created) {
        return 1
    }
    let mut seed: Result<i64, database::DatabaseFault> = engine.put([1], [30], [3])
    seed = engine.put([1], [10], [1])
    seed = engine.put([1], [40], [4])
    seed = engine.put([1], [20], [2])
    if !database::database_outcome_is_fine(seed) {
        return 2
    }
    let forward: database::DatabaseCursor = database::database_outcome_must(engine.cursor([1]))
    let mut walker: database::DatabaseCursor = forward
    if !walker.first() {
        return 3
    }
    if !database::database_bytes_equal(database::database_outcome_must(walker.key()), [10]) {
        return 4
    }
    if !walker.next() {
        return 5
    }
    if !database::database_bytes_equal(database::database_outcome_must(walker.key()), [20]) {
        return 6
    }
    if !walker.last() {
        return 7
    }
    if !database::database_bytes_equal(database::database_outcome_must(walker.key()), [40]) {
        return 8
    }
    if !walker.prev() {
        return 9
    }
    if !database::database_bytes_equal(database::database_outcome_must(walker.key()), [30]) {
        return 10
    }
    if !walker.last() {
        return 11
    }
    if walker.next() {
        return 12
    }
    if walker.valid() {
        return 13
    }
    let invalid_key: Result<[u8], database::DatabaseFault> = walker.key()
    if database::database_outcome_fault_code(invalid_key) != database::database_fault_cursor_invalid() {
        return 14
    }
    let fresh: database::DatabaseCursor = database::database_outcome_must(engine.cursor([1]))
    let unpositioned: Result<[u8], database::DatabaseFault> = fresh.key()
    if database::database_outcome_fault_code(unpositioned) != database::database_fault_cursor_invalid() {
        return 15
    }
    let mut seeker: database::DatabaseCursor = database::database_outcome_must(engine.cursor([1]))
    if !seeker.seek([25]) {
        return 16
    }
    if !database::database_bytes_equal(database::database_outcome_must(seeker.key()), [30]) {
        return 17
    }
    if !seeker.seek([30]) {
        return 18
    }
    if !database::database_bytes_equal(database::database_outcome_must(seeker.key()), [30]) {
        return 19
    }
    if seeker.seek([99]) {
        return 20
    }
    if seeker.valid() {
        return 21
    }
    if !seeker.seek([1]) {
        return 22
    }
    if !database::database_bytes_equal(database::database_outcome_must(seeker.key()), [10]) {
        return 23
    }
    let prefixed: database::DatabaseCursor = database::database_outcome_must(engine.cursor_prefix([1], [3]))
    let mut prefix_walker: database::DatabaseCursor = prefixed
    if !prefix_walker.first() {
        return 24
    }
    if !database::database_bytes_equal(database::database_outcome_must(prefix_walker.key()), [30]) {
        return 25
    }
    if prefix_walker.next() {
        return 26
    }
    let mut reversed: database::DatabaseCursor = database::database_outcome_must(engine.cursor_reverse([1]))
    if !reversed.first() {
        return 27
    }
    if !database::database_bytes_equal(database::database_outcome_must(reversed.key()), [40]) {
        return 28
    }
    if !reversed.next() {
        return 29
    }
    if !database::database_bytes_equal(database::database_outcome_must(reversed.key()), [30]) {
        return 30
    }
    if !reversed.seek([25]) {
        return 31
    }
    if !database::database_bytes_equal(database::database_outcome_must(reversed.key()), [20]) {
        return 32
    }
    let snapshot_cursor: database::DatabaseCursor = database::database_outcome_must(engine.cursor([1]))
    let added: Result<i64, database::DatabaseFault> = engine.put([1], [15], [9])
    if !database::database_outcome_is_fine(added) {
        return 33
    }
    let mut isolated: database::DatabaseCursor = snapshot_cursor
    if !isolated.first() {
        return 34
    }
    let mut visited: i64 = 0
    let mut walking: bool = true
    while walking {
        visited = visited + 1
        walking = isolated.next()
    }
    if visited != 4 {
        return 35
    }
    return 0
}
