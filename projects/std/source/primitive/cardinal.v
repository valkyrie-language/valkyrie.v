namespace std.primitive;

# Cardinal: 0 基索引读写合同 —— `⁅ ⁆` / `⁅ ⁆=` 算子与同源的命名方法
# `get_cardinal` / `set_cardinal`。
#
# 语义基线（合同的一部分，实现必须遵守）：
# - 索引按 `Element` 计数、0 基：合法域 `0 <= offset < 元素个数`；
#   `⁅0⁆` 是首元素，`⁅元素个数 - 1⁆` 是末元素。
# - `⁅ ⁆` 是自动取值形态：返回裸 `Element`，不做 `Option` 包装；
#   越界属于契约违反，结构化失败（`std::types::panic` raise），
#   不许静默返回默认值、不许未定义行为。
# - `⁅ ⁆=` 改写既有槽位、不改变元素个数；越界同样结构化失败（panic）。
# - `get_cardinal` / `set_cardinal` 与 `⁅ ⁆` / `⁅ ⁆=` 同源同语义：
#   实现侧只保留一份索引访问逻辑，算子与命名方法互为委托，不许维护第二套。
# - 本合同不管元素个数：计数语义（`length` / `count()` 等）由类型自行声明，
#   不许把计数实现借道索引访问，也不许把索引读写借道计数方法。
# - 当前测试框架无 expected-panic 能力（legion `run_builtin_ovm_test` 只按
#   `vm.run` 的 Ok/Err 判通过/失败），越界 panic 语义由本注释固定，属已知测试缺口。
#
# `Element` 是自由关联类型；索引参数固定 `usize`（0 基偏移）。
trait Cardinal {
    type Element;

    suffix `⁅ ⁆`(self, offset: usize): Element

    suffix `⁅ ⁆=`(mut self, offset: usize, value: Element)

    micro get_cardinal(self, offset: usize): Element

    micro set_cardinal(mut self, offset: usize, value: Element)
}
