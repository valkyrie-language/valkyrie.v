namespace std.terminal;

using std.random::{entropy};
using std.types::{Option, Some, None};

# ────────── 终端会话 ──────────
⍝ 会话生命周期合同（本模块的语义事实，不是实现细节）：
⍝ - 创建：`TuiSession::new()` 产出空会话，不触碰终端。状态槽由
⍝   `declare_flag` / `declare_choice` / `declare_int` 分配，句柄身份是
⍝   「会话记号 + 槽位序号」：记号在构造时取自宿主熵源
⍝   （`std::random::entropy`），每个会话唯一；句柄只在分配它的会话内
⍝   有效，跨会话误用在读写处一律拒绝。
⍝ - 挂载：`mount` 把控件树渲染为帧并重建焦点表，可反复调用（重挂载）；
⍝   挂载本身不进入终端特殊状态。
⍝ - 运行：`run` 进入备用屏、渲染首帧、启动事件循环。运行期间重入 `run`
⍝   是契约违反（panic）。行为回调收到同一会话的可变引用，
⍝   可在回调内 `mount` 重挂载或 `set_*` / `patch_*` 改状态，循环继续直至
⍝   `quit` 被请求或输入流结束。
⍝ - 关闭：`run` 返回前必然退出备用屏；`run` 之外没有需要手工归还的终端状态。
⍝ - 作用域：会话由调用方显式持有并逐参数传递。std 不提供进程级隐式单例，
⍝   不提供替换或读取"全局运行时"的通道；共享可变状态只能经会话的
⍝   类型化状态槽表达。

# 会话状态：控件树 + 类型化状态槽 + 渲染期焦点表 + 终端尺寸。
structure TuiSession {
    roots: ArrayList<Widget>
    flag_slots: ArrayList<bool>
    choice_slots: ArrayList<utf8>
    int_slots: ArrayList<i32>
    focusables: ArrayList<Focusable>
    focus_index: usize
    term_rows: i32
    term_cols: i32
    help_text: utf8
    running: bool
    identity: u64
    failure_reason: Option<utf8>
}

imply TuiSession {
    micro new() -> Self {
        return TuiSession {
            roots: ArrayList::new(16),
            flag_slots: ArrayList::new(16),
            choice_slots: ArrayList::new(16),
            int_slots: ArrayList::new(16),
            focusables: ArrayList::new(64),
            focus_index: 0,
            term_rows: 24,
            term_cols: 80,
            help_text: "Arrows/hjkl: navigate | Enter/Space: activate | Tab: next | Esc: quit",
            running: false,
            identity: entropy(),
            failure_reason: None
        }
    }

    # 分配布尔状态槽，返回类型化句柄；槽位初值由调用方给出。
    micro declare_flag(mut self, initial: bool) -> FlagBinding {
        let slot: usize = self.flag_slots.length()
        self.flag_slots.push(initial)
        return FlagBinding { owner: self.identity, slot: slot }
    }

    # 分配选项状态槽，返回类型化句柄；槽位初值为当前选中项显示值。
    micro declare_choice(mut self, initial: utf8) -> ChoiceBinding {
        let slot: usize = self.choice_slots.length()
        self.choice_slots.push(initial)
        return ChoiceBinding { owner: self.identity, slot: slot }
    }

    # 分配整数状态槽，返回类型化句柄；槽位初值为带符号显示值（可为负）。
    micro declare_int(mut self, initial: i32) -> IntBinding {
        let slot: usize = self.int_slots.length()
        self.int_slots.push(initial)
        return IntBinding { owner: self.identity, slot: slot }
    }

    # 句柄归属校验：`owner` 与本会话记号不符即契约违反——A 会话的
    # 槽位号在 B 会话里可能指向另一格，静默命中就是把误用伪装成成功。
    private micro check_flag_owner(self, binding: FlagBinding) -> unit {
        if binding.owner != self.identity {
            std::types::panic("TuiSession: FlagBinding 不属于本会话，拒绝跨会话读写")
        }
    }

    private micro check_choice_owner(self, binding: ChoiceBinding) -> unit {
        if binding.owner != self.identity {
            std::types::panic("TuiSession: ChoiceBinding 不属于本会话，拒绝跨会话读写")
        }
    }

    private micro check_int_owner(self, binding: IntBinding) -> unit {
        if binding.owner != self.identity {
            std::types::panic("TuiSession: IntBinding 不属于本会话，拒绝跨会话读写")
        }
    }

    micro flag(self, binding: FlagBinding) -> bool {
        self.check_flag_owner(binding)
        return self.flag_slots.get((binding.slot + 1) as isize).unwrap()
    }

    micro choice(self, binding: ChoiceBinding) -> utf8 {
        self.check_choice_owner(binding)
        return self.choice_slots.get((binding.slot + 1) as isize).unwrap()
    }

    micro int(self, binding: IntBinding) -> i32 {
        self.check_int_owner(binding)
        return self.int_slots⁅binding.slot⁆
    }

    micro set_flag(mut self, binding: FlagBinding, on: bool) -> unit {
        self.check_flag_owner(binding)
        self.flag_slots.set((binding.slot + 1) as isize, on)
    }

    micro set_choice(mut self, binding: ChoiceBinding, selected: utf8) -> unit {
        self.check_choice_owner(binding)
        self.choice_slots.set((binding.slot + 1) as isize, selected)
    }

    micro set_int(mut self, binding: IntBinding, value: i32) -> unit {
        self.check_int_owner(binding)
        self.int_slots⁅binding.slot⁆ = value
    }

    micro toggle_flag(mut self, binding: FlagBinding) -> unit {
        self.set_flag(binding, !self.flag(binding))
    }

    # 写布尔槽并重渲染。
    micro patch_flag(mut self, binding: FlagBinding, on: bool) -> unit {
        self.set_flag(binding, on)
        self.render()
    }

    # 写选项槽并重渲染。
    micro patch_choice(mut self, binding: ChoiceBinding, selected: utf8) -> unit {
        self.set_choice(binding, selected)
        self.render()
    }

    # 写整数槽并重渲染。
    micro patch_int(mut self, binding: IntBinding, value: i32) -> unit {
        self.set_int(binding, value)
        self.render()
    }

    # 挂载控件树并重渲染（首帧与重挂载共用同一条路径）。
    micro mount(mut self, roots: ArrayList<Widget>) -> unit {
        self.roots = roots
        self.render()
    }

    # 请求事件循环退出；`run` 在当轮收尾后返回。
    micro quit(mut self) -> unit {
        self.running = false
    }

    # 自定义底部帮助行；空串关闭帮助行。
    micro set_help_text(mut self, text: utf8) -> unit {
        self.help_text = text
    }

    # 事件循环终止原因的可观察面：`Some(reason)` 表示输入读取失败
    # （区别于正常 `quit` / EOF 的 `None`）。
    micro input_failure(self) -> Option<utf8> {
        return self.failure_reason
    }

    micro run(mut self) -> i32 {
        if self.running {
            std::types::panic("TuiSession.run: 会话运行期间重入 run")
        }
        self.running = true
        self.failure_reason = None
        enter_alt_screen()
        self.render()
        while self.running {
            self.handle_key(poll_key())
        }
        exit_alt_screen()
        # 正常退出（`quit` 请求或输入流 EOF）返回 0；读取失败返回非零，
        # 原因经 `input_failure` 观察——EOF 与输入失败不再压成同一成功。
        # 循环体内的 panic 属契约违反路径：语言尚无跨帧清理/finally 合同，
        # 备用屏归还无法在 std 侧覆盖该路径（登记为上游缺口，不伪造兜底）。
        if self.failure_reason.is_some() {
            return 1
        }
        return 0
    }

    # 事件单通道：一次轮询事件一次性决定导航、激活或退出，
    # 不依赖任何旁路状态（旧模型中"键种类"与"最后字符"分两条通道传递，
    # 本函数把种类与载荷收敛为 `KeyEvent` 一个事实源）。
    micro handle_key(mut self, event: KeyEvent) -> unit {
        match event {
            case Arrow(direction):
                self.focus_index = self.find_in_direction(direction)
                self.render()
            case Named(key):
                self.handle_named(key)
            case Character(ch):
                self.handle_character(ch)
            case Idle:
                sleep_ms(10)
            case EndOfInput:
                self.quit()
            case ReadFailed(reason):
                # 保留失败原因并退出循环：`run` 以非零结果收尾，
                # 调用方经 `input_failure` 取回原因。
                self.failure_reason = Some(reason)
                self.quit()
        }
    }

    micro handle_named(mut self, key: NamedKey) -> unit {
        match key {
            case Enter:
                self.activate_current()
            case Tab:
                self.focus_index = self.find_linear(true, 1)
                self.render()
            case BackTab:
                self.focus_index = self.find_linear(false, 1)
                self.render()
            case Backspace:
                self.focus_index = self.find_linear(false, 1)
                self.render()
            case Home:
                self.focus_index = 0
                self.render()
            case End:
                if self.focusables.length() > 0 {
                    self.focus_index = self.focusables.length() - 1
                }
                self.render()
            case PageUp:
                self.focus_index = self.find_linear(false, 5)
                self.render()
            case PageDown:
                self.focus_index = self.find_linear(true, 5)
                self.render()
            case Escape:
                self.quit()
        }
    }

    # 字符事件按码位判定，字面量即词汇：q/Q 退出，hjkl 方向导航，
    # Space 激活当前焦点，1..9 直达并激活第 n 个可聚焦项；其余字符无操作。
    micro handle_character(mut self, ch: char) -> unit {
        if ch == 'q' || ch == 'Q' {
            self.quit()
            return
        }
        if ch == 'h' {
            self.focus_index = self.find_in_direction(Left)
            self.render()
            return
        }
        if ch == 'j' {
            self.focus_index = self.find_in_direction(Down)
            self.render()
            return
        }
        if ch == 'k' {
            self.focus_index = self.find_in_direction(Up)
            self.render()
            return
        }
        if ch == 'l' {
            self.focus_index = self.find_in_direction(Right)
            self.render()
            return
        }
        if ch == ' ' {
            self.activate_current()
            return
        }
        if ch >= '1' && ch <= '9' {
            let idx: usize = (ch as u32 - '1' as u32) as usize
            if idx < self.focusables.length() {
                self.focus_index = idx
                self.activate_current()
            }
            return
        }
    }

    micro render(mut self) -> unit {
        self.term_rows = size_rows()
        self.term_cols = size_cols()
        if self.term_rows == 0 {
            self.term_rows = 24
        }
        if self.term_cols == 0 {
            self.term_cols = 80
        }
        clear()
        self.focusables.clear()
        let mut row: i32 = 0
        let mut remaining: i32 = self.term_rows
        let mut i: usize = 0
        while i < self.roots.length() {
            if remaining <= 0 {
                break
            }
            let w: Widget = self.roots.get((i + 1) as isize).unwrap()
            let used: i32 = self.render_widget(w, row, 0, self.term_cols, remaining)
            row = row + used
            remaining = remaining - used
            i = i + 1
        }
        if self.focusables.length() > 0 && self.focus_index >= self.focusables.length() {
            self.focus_index = 0
        }
        self.render_focus_highlight()
        self.render_help_bar()
        flush()
    }

    # 渲染分派按变体解构：每个分支只拿到该控件实际持有的字段。
    micro render_widget(mut self, w: Widget, row: i32, col: i32, width: i32, height: i32) -> i32 {
        if width <= 0 || height <= 0 {
            return 0
        }
        match w {
            case Column(children):
                self.render_column(children, row, col, width, height)
            case Row(children):
                self.render_row(children, row, col, width, height)
            case Box(children):
                self.render_box(children, row, col, width, height)
            case Text(content):
                self.render_text(content, row, col)
            case Button(label, on_activate):
                self.render_button(label, on_activate, row, col)
            case Item(label, on_select):
                self.render_item(label, on_select, row, col)
            case Checkbox(label, state):
                self.render_checkbox(label, state, row, col)
            case Radio(label, group, option):
                self.render_radio(label, group, option, row, col)
            case List(children):
                self.render_column(children, row, col, width, height)
        }
    }

    micro render_text(self, content: utf8, row: i32, col: i32) -> i32 {
        self.draw_text(row, col, content)
        return 1
    }

    micro render_button(mut self, label: utf8, on_activate: micro(mut TuiSession) -> unit, row: i32, col: i32) -> i32 {
        self.draw_text(row, col, "[ " ++ label ++ " ]")
        self.register_focusable(row, col, Activate { label: label, on_activate: on_activate })
        return 1
    }

    micro render_item(mut self, label: utf8, on_select: micro(mut TuiSession) -> unit, row: i32, col: i32) -> i32 {
        self.draw_text(row, col, "  " ++ label)
        self.register_focusable(row, col, Select { label: label, on_select: on_select })
        return 1
    }

    micro render_checkbox(mut self, label: utf8, state: FlagBinding, row: i32, col: i32) -> i32 {
        self.draw_text(row, col, self.toggle_display(label, state))
        self.register_focusable(row, col, Toggle { label: label, state: state })
        return 1
    }

    micro render_radio(mut self, label: utf8, group: ChoiceBinding, option: utf8, row: i32, col: i32) -> i32 {
        self.draw_text(row, col, self.choose_display(label, group, option))
        self.register_focusable(row, col, Choose { label: label, group: group, option: option })
        return 1
    }

    micro toggle_display(self, label: utf8, state: FlagBinding) -> utf8 {
        if self.flag(state) {
            return "[x] " ++ label
        }
        return "[ ] " ++ label
    }

    micro choose_display(self, label: utf8, group: ChoiceBinding, option: utf8) -> utf8 {
        if self.choice(group) == option {
            return "(x) " ++ label
        }
        return "( ) " ++ label
    }

    micro render_column(mut self, children: ArrayList<Widget>, row: i32, col: i32, width: i32, height: i32) -> i32 {
        let mut cur_row: i32 = row
        let mut remaining: i32 = height
        let mut i: usize = 0
        while i < children.length() {
            if remaining <= 0 {
                break
            }
            let child: Widget = children.get((i + 1) as isize).unwrap()
            let used: i32 = self.render_widget(child, cur_row, col, width, remaining)
            cur_row = cur_row + used
            remaining = remaining - used
            i = i + 1
        }
        return cur_row - row
    }

    micro render_row(mut self, children: ArrayList<Widget>, row: i32, col: i32, width: i32, height: i32) -> i32 {
        let count: i32 = children.length() as i32
        if count == 0 {
            return 0
        }
        let child_width: i32 = width / count
        let mut cur_col: i32 = col
        let mut max_height: i32 = 0
        let mut i: usize = 0
        while i < children.length() {
            let mut actual_w: i32 = child_width
            if i as i32 == count - 1 {
                actual_w = width - child_width * (count - 1)
            }
            let child: Widget = children.get((i + 1) as isize).unwrap()
            let used: i32 = self.render_widget(child, row, cur_col, actual_w, height)
            cur_col = cur_col + actual_w
            if used > max_height {
                max_height = used
            }
            i = i + 1
        }
        return max_height
    }

    micro render_box(mut self, children: ArrayList<Widget>, row: i32, col: i32, width: i32, height: i32) -> i32 {
        self.draw_box_border(row, col, width, height)
        if width >= 2 && height >= 2 {
            self.render_column(children, row + 1, col + 1, width - 2, height - 2)
        }
        return height
    }

    micro register_focusable(mut self, row: i32, col: i32, target: FocusTarget) -> unit {
        # 标签长度是 `usize` 计数；`Focusable` 的渲染坐标为 `i32`，
        # 在显式边界收窄，不把无界计数直接钉进有界坐标。
        let width: i32 = (self.focus_label(target).length() as i32) + 4
        self.focusables.push(Focusable {
            row: row,
            col: col,
            width: width,
            target: target
        })
    }

    micro focus_label(self, target: FocusTarget) -> utf8 {
        match target {
            case Activate(label, on_activate):
                label
            case Select(label, on_select):
                label
            case Toggle(label, state):
                label
            case Choose(label, group, option):
                label
        }
    }

    micro draw_text(self, row: i32, col: i32, text: utf8) -> unit {
        if row < 0 || row >= self.term_rows {
            return
        }
        if col < 0 || col >= self.term_cols {
            return
        }
        move_to(row, col)
        put_str(text)
    }

    micro draw_box_border(self, row: i32, col: i32, width: i32, height: i32) -> unit {
        if width < 1 || height < 1 {
            return
        }
        self.draw_char_at(row, col, '+')
        if width > 1 {
            self.draw_char_at(row, col + width - 1, '+')
        }
        if height > 1 {
            self.draw_char_at(row + height - 1, col, '+')
            if width > 1 {
                self.draw_char_at(row + height - 1, col + width - 1, '+')
            }
        }
        let mut c: i32 = col + 1
        while c < col + width - 1 {
            self.draw_char_at(row, c, '-')
            if height > 1 {
                self.draw_char_at(row + height - 1, c, '-')
            }
            c = c + 1
        }
        let mut r: i32 = row + 1
        while r < row + height - 1 {
            self.draw_char_at(r, col, '|')
            if width > 1 {
                self.draw_char_at(r, col + width - 1, '|')
            }
            r = r + 1
        }
    }

    micro draw_char_at(self, row: i32, col: i32, ch: char) -> unit {
        if row < 0 || row >= self.term_rows {
            return
        }
        if col < 0 || col >= self.term_cols {
            return
        }
        move_to(row, col)
        put_char(ch)
    }

    micro render_focus_highlight(self) -> unit {
        if self.focusables.length() == 0 {
            return
        }
        let f: Focusable = self.focusables.get((self.focus_index + 1) as isize).unwrap()
        move_to(f.row, f.col)
        set_reverse(true)
        put_str(self.focus_display(f.target))
        set_reverse(false)
    }

    micro focus_display(self, target: FocusTarget) -> utf8 {
        match target {
            case Activate(label, on_activate):
                "[ " ++ label ++ " ]"
            case Select(label, on_select):
                "> " ++ label
            case Toggle(label, state):
                self.toggle_display(label, state)
            case Choose(label, group, option):
                self.choose_display(label, group, option)
        }
    }

    micro render_help_bar(self) -> unit {
        if self.help_text == "" {
            return
        }
        let mut bottom: i32 = self.term_rows - 1
        if bottom < 0 {
            bottom = 0
        }
        move_to(bottom, 0)
        put_str(self.help_text)
    }

    # 方向导航：按变体解构方向，主位移 + 次偏移取最近候选；无候选保持当前焦点。
    micro find_in_direction(self, direction: Direction) -> usize {
        if self.focusables.length() == 0 {
            return 0
        }
        let cur: Focusable = self.focusables.get((self.focus_index + 1) as isize).unwrap()
        let mut best: i64 = -1
        let mut best_primary: i32 = 0
        let mut best_secondary: i32 = 0
        let mut i: usize = 0
        while i < self.focusables.length() {
            if i == self.focus_index {
                i = i + 1
                continue
            }
            let f: Focusable = self.focusables.get((i + 1) as isize).unwrap()
            let dr: i32 = f.row - cur.row
            let dc: i32 = f.col - cur.col
            let mut valid: bool = false
            let mut primary: i32 = 0
            let mut secondary: i32 = 0
            match direction {
                case Up:
                    if dr < 0 {
                        valid = true
                        primary = -dr
                        if dc < 0 { secondary = -dc } else { secondary = dc }
                    }
                case Down:
                    if dr > 0 {
                        valid = true
                        primary = dr
                        if dc < 0 { secondary = -dc } else { secondary = dc }
                    }
                case Left:
                    if dc < 0 {
                        valid = true
                        primary = -dc
                        if dr < 0 { secondary = -dr } else { secondary = dr }
                    }
                case Right:
                    if dc > 0 {
                        valid = true
                        primary = dc
                        if dr < 0 { secondary = -dr } else { secondary = dr }
                    }
            }
            if valid {
                # 真正的两级排序：主轴优先，主轴同值才比次轴。
                # 旧 `primary * 1000 + secondary` 隐含次轴差 < 1000 的尺寸
                # 假设，大终端/远列候选会错序；字典序比较不依赖任何尺寸界。
                let mut take: bool = best < 0
                if !take {
                    let mut order: std::operator::Ordering = primary.compare(best_primary)
                    if order == std::operator::Ordering.Equal {
                        order = secondary.compare(best_secondary)
                    }
                    if order == std::operator::Ordering.Less {
                        take = true
                    }
                }
                if take {
                    best = i as i64
                    best_primary = primary
                    best_secondary = secondary
                }
            }
            i = i + 1
        }
        if best >= 0 {
            return best as usize
        }
        return self.focus_index
    }

    micro find_linear(self, forward: bool, step: usize) -> usize {
        let count: usize = self.focusables.length()
        if count == 0 || count == 1 {
            return 0
        }
        let mut idx: i64 = self.focus_index as i64
        if forward {
            idx = idx + step as i64
            while idx >= count as i64 {
                idx = idx - count as i64
            }
        } else {
            idx = idx - step as i64
            while idx < 0 {
                idx = idx + count as i64
            }
        }
        return idx as usize
    }

    # 激活当前焦点：行为按目标变体执行——动作类调用其函数值并传入本会话，
    # 状态类翻转/写入类型化槽并重渲染。
    micro activate_current(mut self) -> unit {
        let count: usize = self.focusables.length()
        if count == 0 {
            return
        }
        if self.focus_index >= count {
            self.focus_index = 0
        }
        let f: Focusable = self.focusables.get((self.focus_index + 1) as isize).unwrap()
        match f.target {
            case Activate(label, on_activate):
                on_activate(self)
            case Select(label, on_select):
                on_select(self)
            case Toggle(label, state):
                self.toggle_flag(state)
                self.render()
            case Choose(label, group, option):
                self.set_choice(group, option)
                self.render()
        }
    }
}
