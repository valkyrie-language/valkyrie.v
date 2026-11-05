namespace std.negative;

using std.collection::{BTreeMap, BTreeSet, HashMap, HashSet};

# 编译期反例（不属于 `test/` 扫描范围，也不进 `source/` 构建闭包）：
# map/set 只提供 `Ordinal`（1 基 `[ ]`，索引类型 = 键 K），**不提供** `Cardinal`
# （0 基 `⁅ ⁆`）。`Cardinal` 只属于序列类容器（Array / ArrayList / ArrayView /
# Utf8Text / Utf16Text）。
#
# 最小复现：把本文件放进任意临时项目的 `source/` 后执行
# `legion build <临时项目> --target ovm`。
# 预期结果：编译期报找不到 `⁅ ⁆` 的索引实现（不满足 `Cardinal`），
# 不是运行期 panic，也不是按插入顺序取第 N 条。

micro negative_cardinal_on_hash_map(map: HashMap<i64, i64>): i64 {
    return map⁅0⁆
}

micro negative_cardinal_on_hash_set(set: HashSet<i64>): i64 {
    return set⁅0⁆
}

micro negative_cardinal_on_btree_map(map: BTreeMap<i64, i64>): i64 {
    return map⁅0⁆
}

micro negative_cardinal_on_btree_set(set: BTreeSet<i64>): i64 {
    return set⁅0⁆
}
