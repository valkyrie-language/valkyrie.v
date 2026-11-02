namespace std.primitive;

# Cardinal: 基数合同 —— 元素计数、规模调整，以及 0 基偏移算子 `⁅ ⁆` / `⁅ ⁆=`。
#
# 语义基线（合同的一部分，实现必须遵守）：
# - `⁅ ⁆` 的偏移按 `Element` 计数、0 基：合法域 `0 <= offset < get_cardinal()`；
#   `⁅0⁆` 是首元素，`⁅get_cardinal() - 1⁆` 是末元素。
# - `⁅ ⁆` 是自动取值形态：返回裸 `Element`，不做 `Option` 包装；
#   越界属于契约违反，结构化失败（`std::types::panic` raise），
#   不许静默返回默认值、不许未定义行为。
# - `⁅ ⁆=` 改写既有槽位、不改变规模；越界同样结构化失败（panic）。
#   `⁅ ⁆=` 与 `set_cardinal` 是两件独立的事：前者改元素，后者改规模，互不委托。
# - `get_cardinal` 返回 `Element` 计数；`set_cardinal` 把规模调整为 `count`。
#   规模不可调整的实现（定长序列、文本）对 `set_cardinal` 的任何调用必须结构化失败，
#   不许静默截断或扩容。
# - 当前测试框架无 expected-panic 能力（legion `run_builtin_ovm_test` 只按
#   `vm.run` 的 Ok/Err 判通过/失败），越界 panic 语义由本注释固定，属已知测试缺口。
#
# `Element` / `Count` 是自由关联类型：常规容器实现选 `Count = usize`；
# 非整数计数（容量位图、分代句柄等）只要语义自洽即可实现本合同。
trait Cardinal {
    type Element;
    type Count;

    suffix `⁅ ⁆`(self, offset: usize): Element

    suffix `⁅ ⁆=`(mut self, offset: usize, value: Element)

    micro get_cardinal(self): Count

    micro set_cardinal(mut self, count: Count)
}
