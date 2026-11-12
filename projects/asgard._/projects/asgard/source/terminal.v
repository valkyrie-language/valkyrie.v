namespace asgard.terminal;

using std.terminal;

# ────────── Asgard 终端目标 · 产品接入 ──────────
⍝ 本模块是 AWSL 终端目标与 `std.terminal` 的唯一接触点：
⍝ 导出命名约定、显示名登记、生成流程入口全部是产品合同，
⍝ `std.terminal` 不认识 Asgard、AWSL 或任何生成符号。
⍝
⍝ 接入方式：
⍝ - 事件行为：AWSL lower 为每个 `@click` / `@change` 生成形如
⍝   `micro awsl_call_<name>(session: mut TuiSession) -> unit` 的处理函数，
⍝   构造控件时以函数值直接传入；不存在按导出名分派的字符串通道。
⍝ - 绑定状态：脚本 `let mut` 中承担交互状态的绑定（布尔、单选组）
⍝   以显示名登记到 `AsgardTuiBindings`，换取会话内类型化槽句柄；
⍝   显示名只作登记身份，值类型由句柄类型固定。纯展示文本在重挂载时
⍝   由生成代码从产品 store 直接求值写入 `Text` 控件，不占用会话槽位。
⍝ - 生命周期：`asgard_terminal_run` 显式创建并持有会话，登记表随
⍝   每次运行开始/结束重置；会话以参数传给生成处理函数，无进程级隐式单例。

# 显示名 → 类型化槽句柄登记表。句柄身份跨重挂载稳定；本表只在一次
# `asgard_terminal_run` 期间有效，运行结束即重置。
singleton AsgardTuiBindings {
    mut flag_names: ArrayList<utf8>;
    mut flag_handles: ArrayList<FlagBinding>;
    mut choice_names: ArrayList<utf8>;
    mut choice_handles: ArrayList<ChoiceBinding>;

    micro reset(mut self): unit {
        self.flag_names.clear()
        self.flag_handles.clear()
        self.choice_names.clear()
        self.choice_handles.clear()
    }

    # 按显示名取布尔槽句柄：已登记则复用，未登记则在会话上分配并登记。
    micro flag(mut self, session: mut TuiSession, name: utf8, initial: bool) -> FlagBinding {
        let mut i: usize = 0
        while i < self.flag_names.length() {
            if self.flag_names.get((i + 1) as isize).unwrap() == name {
                return self.flag_handles.get((i + 1) as isize).unwrap()
            }
            i = i + 1
        }
        let handle: FlagBinding = session.declare_flag(initial)
        self.flag_names.push(name)
        self.flag_handles.push(handle)
        return handle
    }

    # 按显示名取选项槽句柄：已登记则复用，未登记则在会话上分配并登记。
    micro choice(mut self, session: mut TuiSession, name: utf8, initial: utf8) -> ChoiceBinding {
        let mut i: usize = 0
        while i < self.choice_names.length() {
            if self.choice_names.get((i + 1) as isize).unwrap() == name {
                return self.choice_handles.get((i + 1) as isize).unwrap()
            }
            i = i + 1
        }
        let handle: ChoiceBinding = session.declare_choice(initial)
        self.choice_names.push(name)
        self.choice_handles.push(handle)
        return handle
    }

    # 按显示名写布尔槽并重渲染；未登记的显示名是生成流程错误。
    micro patch_flag(mut self, session: mut TuiSession, name: utf8, on: bool): unit {
        let mut i: usize = 0
        while i < self.flag_names.length() {
            if self.flag_names.get((i + 1) as isize).unwrap() == name {
                let handle: FlagBinding = self.flag_handles.get((i + 1) as isize).unwrap()
                session.patch_flag(handle, on)
                return
            }
            i = i + 1
        }
        std::types::panic("AsgardTuiBindings.patch_flag: 未登记的绑定显示名")
    }

    # 按显示名写选项槽并重渲染；未登记的显示名是生成流程错误。
    micro patch_choice(mut self, session: mut TuiSession, name: utf8, selected: utf8): unit {
        let mut i: usize = 0
        while i < self.choice_names.length() {
            if self.choice_names.get((i + 1) as isize).unwrap() == name {
                let handle: ChoiceBinding = self.choice_handles.get((i + 1) as isize).unwrap()
                session.patch_choice(handle, selected)
                return
            }
            i = i + 1
        }
        std::types::panic("AsgardTuiBindings.patch_choice: 未登记的绑定显示名")
    }
}

# ── 控件构造原语：AWSL lower 生成代码调用这些函数组装控件树 ──

micro awsl_column(children: ArrayList<Widget>) -> Widget {
    return Column { children: children }
}

micro awsl_row(children: ArrayList<Widget>) -> Widget {
    return Row { children: children }
}

micro awsl_box(children: ArrayList<Widget>) -> Widget {
    return Box { children: children }
}

micro awsl_text(content: utf8) -> Widget {
    return Text { content: content }
}

micro awsl_list(children: ArrayList<Widget>) -> Widget {
    return List { children: children }
}

# 按钮：`on_activate` 为 codegen 生成的处理函数值（形如 `awsl_call_on_add`），
# 签名固定为 `micro(mut TuiSession) -> unit`。
micro awsl_button(label: utf8, on_activate: micro(mut TuiSession) -> unit) -> Widget {
    return Button { label: label, on_activate: on_activate }
}

micro awsl_item(label: utf8, on_select: micro(mut TuiSession) -> unit) -> Widget {
    return Item { label: label, on_select: on_select }
}

# 复选框：`name` 是脚本绑定显示名，句柄经登记表换取，跨重挂载身份稳定。
micro awsl_checkbox(label: utf8, name: utf8, initial: bool, session: mut TuiSession) -> Widget {
    return Checkbox { label: label, state: AsgardTuiBindings.flag(session, name, initial) }
}

micro awsl_radio(label: utf8, name: utf8, option: utf8, session: mut TuiSession) -> Widget {
    return Radio { label: label, group: AsgardTuiBindings.choice(session, name, option), option: option }
}

# ── 生成流程入口 ──

# 主入口：`build` 为 codegen 生成的控件树构造函数，接收会话以分配状态槽。
# 会话由本函数显式创建、挂载、运行；登记表随运行边界重置。
micro asgard_terminal_run(build: micro(mut TuiSession) -> ArrayList<Widget>) -> i32 {
    AsgardTuiBindings.reset()
    let mut session: TuiSession = TuiSession::new()
    session.mount(build(session))
    let code: i32 = session.run()
    AsgardTuiBindings.reset()
    return code
}

# 重挂载入口：生成处理函数改完产品 store 后调用，重建控件树并刷新帧。
micro asgard_terminal_remount(session: mut TuiSession, build: micro(mut TuiSession) -> ArrayList<Widget>) -> unit {
    session.mount(build(session))
}

# 补丁入口：按显示名更新类型化槽并重渲染（值类型由登记时固定）。
micro asgard_terminal_patch_flag(session: mut TuiSession, name: utf8, on: bool) -> unit {
    AsgardTuiBindings.patch_flag(session, name, on)
}

micro asgard_terminal_patch_choice(session: mut TuiSession, name: utf8, selected: utf8) -> unit {
    AsgardTuiBindings.patch_choice(session, name, selected)
}
