namespace std.terminal;

# ────────── 终端宿主能力合同 ──────────
⍝ 宿主只提供语言级通用终端事实：帧输出、光标定位、尺寸、单通道输入事件、
⍝ 备用屏切换与退避。输入事件由 `poll_key` 一次性给出 `KeyEvent`
⍝ （种类与载荷同源），不存在第二条输入通道或旁路状态。
⍝ 本文件不出现任何产品导出命名、生成流程或运行时约定。

[host_contract]
micro clear(): unit

[host_contract]
micro set_foreground(color: i32): unit

[host_contract]
micro set_background(color: i32): unit

[host_contract]
micro reset_color(): unit

[host_contract]
micro move_to(row: i32, col: i32): unit

[host_contract]
micro size_rows(): i32

[host_contract]
micro size_cols(): i32

# 输入事件唯一入口：暂时无事件、输入流结束、读取失败都是事件变体，
# 不以负数、空串或旁路字段表达。
[host_contract]
micro poll_key(): KeyEvent

[host_contract]
micro enter_alt_screen(): unit

[host_contract]
micro exit_alt_screen(): unit

[host_contract]
micro flush(): unit

[host_contract]
micro put_char(ch: char): unit

[host_contract]
micro put_str(text: utf8): unit

[host_contract]
micro set_reverse(on: bool): unit

[host_contract]
micro sleep_ms(ms: i32): unit
