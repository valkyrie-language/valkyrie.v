namespace std.operator;

# Ordinal: 序数合同 —— "第几个位置" 的读写，即 `a[ordinal]` 与 `a[ordinal] = value`。
#
# 语义基线（合同的一部分，实现必须遵守）：
# - 序数 1 基：`get(1)` / `[1]` 是首元素；合法域 `1 <= ordinal <= 元素个数`。
# - `ordinal <= 0`（含负数）或超出元素个数为越界：
#   - 读路径（`get` / `[ ]`）返回 `None`：位置缺失是可恢复常态，由调用方处理；
#   - 写路径（`set` / `[ ]=`）结构化失败（`std::types::panic` raise）：
#     越界写入是契约违反，不许静默丢弃写入。
#   当前测试框架无 expected-panic 能力（legion `run_builtin_ovm_test` 只按
#   `vm.run` 的 Ok/Err 判通过/失败），越界写 panic 语义由本注释固定，属已知测试缺口。
# - `get`/`set` 与 `[ ]`/`[ ]=` 同语义同形态，实现侧只保留一份访问逻辑，
#   算子成员委托 `get`/`set`，不许维护第二套存储访问路径。
# - 有序且支持 0 基索引读写的容器应先实现 `Cardinal`，再把序数 `n`（1 基）落到
#   0 基偏移 `n - 1` 委托给自身的 `Cardinal` 实现；不要反向维护一套独立的序数下标逻辑。
# - 只有位置语义、没有计数语义的类型（如 `HashMap` 按键存取）只实现本合同，
#   不实现 `Cardinal`。
#
# `Index` 是自由关联类型：常规容器实现选 `isize`（允许负值进入越界判定）；
# 非整数索引（CST 节点句柄、utf8 字节偏移等）只要能给出上述等价语义即可实现本合同。
trait Ordinal {
    type Index;
    type Element;

    suffix `[ ]`(self, ordinal: Index): Option<Element>

    suffix `[ ]=`(mut self, ordinal: Index, value: Element)

    micro get(self, ordinal: Index): Option<Element>

    micro set(mut self, ordinal: Index, value: Element)
}
