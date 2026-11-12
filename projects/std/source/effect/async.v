namespace std.effect;

using std.async;

# 异步等待效应
# 用于标记一个异步操作，等待 Future 完成
# 约束 F 必须实现 Future trait
structure Await<F: Future> {
    future: F
}

# 异步唤醒效应
# 用于标记一个 Future 已完成，需要恢复执行
# 约束 F 必须实现 Future trait
structure Awake<F: Future> {
    future: F
}

# 为 Await<F> 实现 Effectful trait。
# 恢复类型是 `Poll<F::Output>` 的终态事实（02 §4.3）：
# - 恢复：执行器只在被等待 Future 落终态时恢复 `Await`，恢复值为
#   `Ready(output)` 或 `Cancelled`；`Pending` 不是合法恢复值。
# - 传播：`Task::cancel` 先拉起协作 token、再把共享完成资源置
#   `Cancelled` 终态；执行器唤醒等待中的任务体，恢复值即 `Cancelled`。
# - 终止：等待方收到 `Cancelled` 后必须把它映射为自己的终态——`cancel`
#   或 `resolve` 自身完成资源；首个终态生效，执行器不得在 `Cancelled`
#   之后再交付 `Ready`。后续控制流由任务体决定，std 不隐式续传。
imply Await<F>: Effectful {
    type Resume = std.async::Poll<F::Output>;
}

# 为 Awake<F> 实现 Effectful trait
# 唤醒后恢复为 ()
imply Awake<F>: Effectful {
    type Resume = ();
}
