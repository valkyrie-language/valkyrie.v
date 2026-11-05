namespace std.operator;

# Ordinal: 序数合同 —— "第几个位置" 的读写，即 `a[ordinal]` 与 `a[ordinal] = value`。
#
# 语义基线（合同的一部分，实现必须遵守）：
# - 序数 1 基：`get(1)` / `[1]` 是首元素；合法域 `1 <= ordinal <= 元素个数`。
# - 下标访问（`[ ]` / `[ ]=`）是裸值形态：`ordinal <= 0`（含负数）或超出
#   元素个数为越界，结构化失败（`std::types::panic` raise），不返回默认值、
#   不做 `Option` 包装。
# - 命名读路径 `get` 是可恢复形态：越界返回 `None`，位置缺失由调用方显式处理；
#   不另设第二个可选访问器。
#   当前测试框架无 expected-panic 断言能力，越界 panic 语义由本注释固定，
#   用例待能力到位后补。
# - `get` 是可恢复读路径（越界 `None`），与 `[ ]` 共享同一存储路径、只把越界判定
#   外露；`set` 是 `[ ]=` 的命名形态，与算子同源。实现必须在 impl 中提供，
#   不许维护第二套存储访问路径。trait 只做抽象声明，不给默认体
#   （默认体在当前前端无法解析 `self[ordinal]` 算子调用）。
# - 有序且支持 0 基索引读写的容器应先实现 `Cardinal`，再把序数 `n`（1 基）落到
#   0 基偏移 `n - 1` 委托给自身的 `Cardinal` 实现；不要反向维护一套独立的序数下标逻辑。
# - 映射与集合（`HashMap` / `HashSet` / `BTreeMap` / `BTreeSet`）只有按键语义、
#   没有位置计数语义：只实现本合同，`Index = K`（键），不实现 `Cardinal`
#   （`⁅ ⁆` 对它们不存在入口）。对它们而言"序数"就是键：`[key]` 读、
#   `[key] = value` 写（缺键即新增，与 `insert` 同源），删除走类型自身的 `remove`。
#   集合里键与元素同型，`Index = Element = T`。
#
# `Index` 是自由关联类型，下标参数一律写 `Self::Index`：常规序列实现选 `isize`
# （允许负值进入越界判定）；键即索引的映射/集合直接选 `Index = K`，
# 不许拿 `isize` / `usize` 硬套；非整数索引（CST 节点句柄、utf8 字节偏移等）
# 只要能给出上述等价语义即可实现本合同。
#
# 键索引实现的合法域是"键存在"（不是 `1 <= ordinal <= 元素个数`）：
# 键缺失等价于越界，`[ ]` 结构化失败、`get` 返回 `None`，两者语义一致。
trait Ordinal {
    type Index;
    type Element;

    suffix `[ ]`(self, ordinal: Self::Index): Element

    suffix `[ ]=`(mut self, ordinal: Self::Index, value: Element)

    # 命名读路径：可恢复形态，越界返回 `None`（位置缺失由调用方处理）。
    micro get(self, ordinal: Self::Index): Option<Element>

    # 命名写路径与 `[ ]=` 同源：实现体委托算子。
    micro set(mut self, ordinal: Self::Index, value: Element)
}
