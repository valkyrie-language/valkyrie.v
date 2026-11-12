namespace std.async;

using std.types::{Option, Some, None};

# std.async: 异步任务最小面
# 提供 Poll / Future / Promise / Task / CancellationToken / CancellationSource
# 与调度、计时、让出合同的定义，作为语言级异步并发语义的真实承载体。

⍝ 轮询终态：三值类型，完成、未决、取消互不混同。
⍝ `Ready` 直接携带产出值——不存在「先说可取、再取空槽」的两步协议；
⍝ `Cancelled` 是独立终态，取消后的任务永远不会产出 `Ready`。
[tag(PollKind)]
unite Poll<T> {
    ⍝ 尚未完成，可继续轮询。
    [tag(0)]
    [constructor]
    Pending,
    ⍝ 已完成，携带产出值。
    [tag(1)]
    [constructor]
    Ready {
        ⍝ 异步产出
        output: T,
    },
    ⍝ 已取消的终态，无产出。
    [tag(2)]
    [constructor]
    Cancelled,
}

⍝ 异步结果的抽象协议。
⍝ `poll` 是唯一的推进与观察入口：每次调用返回当前三值状态；
⍝ 就绪值随 `Ready` 一并给出，无独立的取值步骤。
trait Future {
    ⍝ Future 完成后产出的结果类型。
    type Output

    ⍝ 查询当前状态：`Pending` / `Ready(output)` / `Cancelled`。
    micro poll(mut self): Poll<Output>
}

⍝ 完成侧状态机：未决、已产出、已取消三态，终态不可逆。
enums PromiseState {
    Pending
    Resolved
    Cancelled
}

⍝ 单赋值的可完成异步值，是 `Future` 的具体拥有型实现。
⍝ 运行时交付终态只经 `resolve` / `cancel` 协议写入；执行器不得读写
⍝ `_state`、`_slot` 等内部字段——终态的唯一事实来源是本协议。
structure Promise<T> {
    ⍝ 当前状态机位置。
    _state: PromiseState

    ⍝ 已写入的结果值；`Resolved` 态下必为 `Some`（不变量由 `resolve` 维护）。
    _slot: Option<T>
}

imply Promise<T>: Future {
    ⍝ Promise 的结果类型即为所持有的值类型 T。
    type Output = T

    ⍝ 构造一个未决、未取消的空 Promise。
    micro new(): Self {
        return Promise {
            _state: Pending,
            _slot: None,
        }
    }

    ⍝ 写入结果值并进入 `Resolved` 终态。
    ⍝ 单赋值语义：首个终态生效，已处于终态时后续写入被忽略。
    micro resolve(mut self, value: T): unit {
        match self._state {
            case Pending: {
                self._slot = Some::<T>(value)
                self._state = Resolved
            }
            else: {
                return
            }
        }
    }

    ⍝ 请求取消：未决态直接进入 `Cancelled` 终态；已是终态则忽略。
    ⍝ 取消后 `poll` 恒产出 `Cancelled`，不存在取到空槽的路径。
    micro cancel(mut self): unit {
        match self._state {
            case Pending: {
                self._slot = None
                self._state = Cancelled
            }
            else: {
                return
            }
        }
    }

    ⍝ 三值终态查询；就绪值随 `Ready` 一并产出。
    micro poll(mut self): Poll<T> {
        match self._state {
            case Cancelled: {
                return Cancelled
            }
            case Resolved: {
                return Ready { output: self._slot.unwrap() }
            }
            case Pending: {
                return Pending
            }
        }
    }
}

⍝ 任务句柄：调度产出的 join 载体，本身即 `Future`。
⍝ 持有完成侧 `Promise` 与协作取消的 `CancellationToken`；
⍝ join 即轮询其 `Future`，取消传播即触发 token 并落终态。
structure Task<T> {
    _completion: Promise<T>
    _token: CancellationToken
}

imply Task<T>: Future {
    type Output = T

    micro poll(mut self): Poll<T> {
        return self._completion.poll()
    }
}

imply Task<T> {
    ⍝ 请求取消：先拉起 token（协作式取消传播给正在执行的任务体），
    ⍝ 完成侧随即进入 `Cancelled` 终态——首个终态生效，任务体之后的
    ⍝ `resolve` 被忽略，`poll` 不再产出 `Ready`。
    micro cancel(mut self): unit {
        self._token.cancel()
        self._completion.cancel()
    }

    ⍝ 暴露协作取消 token，供任务体在协作点观察。
    micro token(self): CancellationToken {
        return self._token
    }
}

⍝ 取消信号的载体，记录是否已收到取消请求。
⍝ 通常由 `CancellationSource` 创建并对外暴露，供异步任务观察取消状态。
class CancellationToken {
    ⍝ 是否已收到取消请求。
    _cancelled: bool
}

imply CancellationToken {
    ⍝ 构造一个未取消的 token。
    micro new(): Self {
        return CancellationToken {
            _cancelled: false,
        }
    }

    ⍝ 标记该 token 为已取消。
    micro cancel(mut self): unit {
        self._cancelled = true
    }

    ⍝ 查询是否已被取消。
    micro is_cancelled(self): bool {
        return self._cancelled
    }
}

⍝ 取消源，拥有一个 `CancellationToken` 并提供触发取消与暴露 token 的能力。
class CancellationSource {
    ⍝ 内部持有的取消 token。
    _token: CancellationToken
}

imply CancellationSource {
    ⍝ 构造一个尚未触发取消的取消源。
    micro new(): Self {
        return CancellationSource {
            _token: CancellationToken::new(),
        }
    }

    ⍝ 返回所持有的取消 token，供异步任务观察取消状态。
    micro token(self): CancellationToken {
        return self._token
    }

    ⍝ 触发取消，将内部 token 标记为已取消。
    micro cancel(mut self): unit {
        self._token.cancel()
    }
}

⍝ 异步能力失败种类（结构化）。
enums AsyncErrorKind {
    ⍝ 时长参数非法（负值）。
    InvalidDuration
    ⍝ 运行时底层失败，未细分。
    Failed
}

structure AsyncError {
    kind: AsyncErrorKind
}

micro async_error(kind: AsyncErrorKind) -> AsyncError {
    return AsyncError { kind: kind }
}

# ── 运行时合同 ────────────────────────────────────────────────────────
# 调度、计时、让出是宿主执行器的正式合同：无默认体、无同步兜底。
# 未绑定执行器的目标在计划阶段结构化失败——未交付能力显式不可用，
# 绝不以「就地同步执行任务体」或「立即返回的假睡眠」冒充并发语义。
# 执行器交付任务终态只经 `Promise::resolve` / `Promise::cancel` 协议。

⍝ 调度：任务体拿到协作取消 token 与完成侧 Promise，在其上交付终态；
⍝ 返回的 `Task` 是 join 与取消传播的句柄。
[host_contract]
micro spawn<T>(body: micro(CancellationToken, Promise<T>) -> unit): Task<T>

⍝ 计时：真实睡眠 `ms` 毫秒后恢复；非正时长结构化失败。
[host_contract]
micro sleep(ms: i64): Option<AsyncError>

⍝ 让出：交还执行控制权，允许运行时调度其他任务。
[host_contract]
micro yield_now(): Option<AsyncError>
