namespace std.terminal;

# ────────── 控件模型 ──────────
⍝ 每个控件变体只持有所需字段：容器持子节点、文本持内容、
⍝ 可交互控件持行为与状态引用。"带子节点的文本控件"这类无效组合
⍝ 在类型上不存在，构造阶段即被挡住，不靠运行时约定维持。
⍝
⍝ 行为是函数值（`micro(mut TuiSession) -> unit`），不是导出名字符串：
⍝ std 不认识任何宿主或产品的符号命名，也不提供按名分派的通道。
⍝ 状态引用是类型化句柄：句柄类型即值类型——布尔槽与选项槽
⍝ 是两个不同领域，把选项句柄递给复选框在构造处编译面非法。
⍝ 字符串在本模型中只承担展示职责（标签、内容、选项显示值），
⍝ 不参与身份判定，不存在"字符串真值"这类语义。

# 布尔状态槽句柄：身份由会话分配（`declare_flag`），值语义固定为 bool。
# `owner` 是分配会话的槽存储对象引用（`SessionSlots`，引用类型）：每次
# `TuiSession::new` 分配独立存储，活跃作用域内确定唯一——同一 tick 创建
# 的两个会话也持有不同对象，句柄只在同一 `owner` 的会话内可读写，跨会话
# 误用（A 会话的槽 0 递给 B 会话）在访问处按引用同一性拒绝，不静默命中
# 同名槽位。身份不取自熵、时钟或顶级可变变量（02 §4.3）。句柄只由
# `declare_flag` / `declare_choice` / `declare_int` 产出，作者面不手工构造。
structure FlagBinding {
    owner: SessionSlots
    slot: usize
}

# 选项状态槽句柄：身份由会话分配（`declare_choice`），值语义固定为当前选中项。
# `owner` 语义同 `FlagBinding`。
structure ChoiceBinding {
    owner: SessionSlots
    slot: usize
}

# 整数状态槽句柄：身份由会话分配（`declare_int`），值语义固定为带符号 `i32`。
# 承载值是响应式显示量而非容器索引/计数：索引与槽位序号按 01 §4.16 用
# `usize`，值本身取产品整数通道真实的带符号域——显示值可为负，不用无符号
# 载体冒充可负语义，也不借 `i64` 宽载体折叠类型化设计。
# `owner` 语义同 `FlagBinding`。
structure IntBinding {
    owner: SessionSlots
    slot: usize
}

# 控件树节点：变体即种类，字段即该种类的全部所需。
unite Widget {
    # 纵向容器
    [constructor]
    Column { children: ArrayList<Widget> },
    # 横向容器
    [constructor]
    Row { children: ArrayList<Widget> },
    # 带边框容器
    [constructor]
    Box { children: ArrayList<Widget> },
    # 纯文本行：只有内容，无可交互字段可填
    [constructor]
    Text { content: utf8 },
    # 按钮：聚焦后可用 Enter/Space 触发动作
    [constructor]
    Button { label: utf8, on_activate: micro(mut TuiSession) -> unit },
    # 列表条目：聚焦后可用 Enter/Space 触发选择动作
    [constructor]
    Item { label: utf8, on_select: micro(mut TuiSession) -> unit },
    # 复选框：激活时翻转所引布尔槽
    [constructor]
    Checkbox { label: utf8, state: FlagBinding },
    # 单选钮：激活时把选项显示值写入所引选项槽
    [constructor]
    Radio { label: utf8, group: ChoiceBinding, option: utf8 },
    # 列表容器：语义为列表，布局纵向
    [constructor]
    List { children: ArrayList<Widget> },
}

# 焦点目标：渲染期由控件变体派生，种类即变体本身，没有独立编码。
unite FocusTarget {
    [constructor]
    Activate { label: utf8, on_activate: micro(mut TuiSession) -> unit },
    [constructor]
    Select { label: utf8, on_select: micro(mut TuiSession) -> unit },
    [constructor]
    Toggle { label: utf8, state: FlagBinding },
    [constructor]
    Choose { label: utf8, group: ChoiceBinding, option: utf8 },
}

# 可聚焦实体：位置与尺寸是渲染期坐标事实，target 携带行为与状态引用。
structure Focusable {
    row: i32
    col: i32
    width: i32
    target: FocusTarget
}
