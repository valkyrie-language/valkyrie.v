namespace std.negative;

using std.collection::{ArrayList, sort};

# 编译期反例（不属于 `test/` 扫描范围，也不进 `source/` 构建闭包）：
# 元素类型没有 `Comparable` 实现时，`sort(list)` 必须被签名约束拒绝，
# 不得静默按原序返回。
#
# 最小复现：把本文件放进任意临时项目的 `source/` 后执行
# `legion build <临时项目> --target ovm`。
# 预期结果：编译期报缺 `Comparable`，不是运行期 panic，也不是排序被跳过。

structure NotComparable {
    value: i64
}

micro negative_sort_without_comparable(): unit {
    let list: ArrayList<NotComparable> = ArrayList::new(0)
    list.push(NotComparable { value: 2 })
    list.push(NotComparable { value: 1 })

    sort(list)
}
