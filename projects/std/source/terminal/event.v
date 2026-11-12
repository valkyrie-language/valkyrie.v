namespace std.terminal;

# ────────── 输入事件词汇 ──────────
⍝ 方向、功能键名、字符载荷是三个互不相干的领域，各用独立类型表达：
⍝ - `Direction` 是焦点空间查询的方向词汇，只有四个取值；
⍝ - `NamedKey` 是不携带文本载荷的离散功能键名；
⍝ - 可打印输入由 `KeyEvent.Character` 直接携带 `char` 码位。
⍝ 三个领域不共享任何数值空间：把方向当键名、把键名当控件种类，
⍝ 在构造与传参处即编译面非法，不存在"撞值"的可能。

# 焦点导航方向：渲染层空间查询的唯一方向词汇。
enums Direction {
    Up
    Down
    Left
    Right
}

# 具名功能键：离散键名，无载荷。字符输入不属于本领域，
# 由 `KeyEvent.Character` 单独承载，避免"键名"与"字符"混写一套编码。
enums NamedKey {
    Enter
    Tab
    BackTab
    Escape
    Backspace
    Home
    End
    PageUp
    PageDown
}

# 输入事件：一次轮询一次性给出种类与载荷，不存在第二通道旁路状态。
⍝ - `Character` 携带码位本身；
⍝ - `Arrow` 携带导航方向；
⍝ - `Named` 携带功能键名；
⍝ - `Idle` 表示本次轮询暂时无事件（调用方可退避后再轮询）；
⍝ - `EndOfInput` 表示输入流结束，是正常终点而非错误；
⍝ - `ReadFailed` 表示读取失败，携带失败描述。
unite KeyEvent {
    # 可打印字符输入，载荷为码位
    [constructor]
    Character { ch: char },
    # 方向键，载荷为导航方向
    [constructor]
    Arrow { direction: Direction },
    # 功能键，载荷为键名
    [constructor]
    Named { key: NamedKey },
    # 本次轮询无事件
    Idle,
    # 输入流结束
    EndOfInput,
    # 读取失败
    [constructor]
    ReadFailed { reason: utf8 },
}
