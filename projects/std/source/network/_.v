# std.network — TCP 传输（字节流资源体系的网络端；平台细节归 adaptor）

namespace std.network;

using std.io::{Reader, Writer, IoError, io_closed};
using std.types::{Result, Option, Some, None, Fine, Fail};

# 分层合同：
# - `TcpStream` 是 `std.io` 字节流体系的成员：实现 `Reader` 与 `Writer`，
#   承载字节而非文本。文本协议（HTTP 等）在字节流之上另行编码。
# - 终态三分且互不混同：流尽（`read` 返回空块，连接被对端有序关闭）、
#   已关闭（本端释放后一切操作 `Closed`）、传输错误（`Failed` 等种类）。
#   不存在以空串或 `-1` 兼作失败哨兵的入口。
# - 资源所有权显式：`tcp_connect` / `accept` 是唯一取得 `TcpStream` 的入口；
#   `TcpStream` 移动持有句柄，`close` 释放并幂等；句柄移交（如 TLS 包装）
#   时原持有者显式失效，移交协议归 `std.network.tls`。
# - 平台数值（fd、地址族、套接字类型、协议号）全部留在 adaptor：
#   `NetHandle` 对 std 不透明，std 不读取、不比较、不以特定值作哨兵；
#   地址族与套接字语义由合同名（connect/listen/accept）表达，不出现
#   AF/SOCK 数值。
# - 建立类失败（名称解析、拒绝、不可达、超时）用 `NetError` 结构化表达；
#   流上读写失败用 `IoError`（与 `Reader`/`Writer` 合同一致）。

# 传输端点：主机名为文本（解析与地址族选择归 adaptor），端口 0..=65535。
structure SocketAddr {
    host: utf8
    port: u16
}

# 建立/传输层失败种类（结构化，不携带自由文本消息）。
enums NetErrorKind {
    # 主机名无法解析。
    NameUnresolved
    # 地址不合法（如端口越界）。
    AddressInvalid
    # 对端拒绝连接。
    Refused
    # 对端不可达。
    Unreachable
    # 建立或等待超时。
    TimedOut
    # 资源已关闭。
    Closed
    # 该目标不支持此操作。
    Unsupported
    # 底层失败，未细分。
    Failed
}

structure NetError {
    kind: NetErrorKind
}

micro net_error(kind: NetErrorKind) -> NetError {
    return NetError { kind: kind }
}

micro net_error_kind(error: NetError) -> NetErrorKind {
    return error.kind
}

# 不透明传输句柄：平台描述符的载体，std 只保存与移交。
structure NetHandle {
    _host: any
}

structure TcpStream {
    _handle: NetHandle
    _open: bool
}

structure TcpListener {
    _handle: NetHandle
    _open: bool
}

# ── 宿主合同（adaptor 绑定；缺绑定的目标计划阶段结构化失败，无内建兜底）──

# 建立：返回不透明句柄或结构化失败；无哨兵数值。
[host_contract]
micro net_connect(addr: SocketAddr) -> Result<NetHandle, NetError>

[host_contract]
micro net_listen(addr: SocketAddr, backlog: usize) -> Result<NetHandle, NetError>

[host_contract]
micro net_accept(listener: NetHandle) -> Result<NetHandle, NetError>

# 流操作：字节模型。`net_read` 空块即流尽；`net_write` 返回实际提交字节数；
# 失败一律经 `IoError` 种类表达。
[host_contract]
micro net_read(handle: NetHandle, max: usize) -> Result<[u8], IoError>

[host_contract]
micro net_write(handle: NetHandle, bytes: ArrayView<u8>) -> Result<usize, IoError>

[host_contract]
micro net_close(handle: NetHandle) -> Option<IoError>

# ── 资源入口 ──────────────────────────────────────────────────────────

micro socket_addr(host: utf8, port: u16) -> SocketAddr {
    return SocketAddr { host: host, port: port }
}

micro tcp_connect(addr: SocketAddr) -> Result<TcpStream, NetError> {
    let opened: Result<NetHandle, NetError> = net_connect(addr)
    match opened {
        case Fine(handle):
            return Fine { value: TcpStream { _handle: handle, _open: true } }
        case Fail(error):
            return Fail { error: error }
    }
}

micro tcp_listen(addr: SocketAddr, backlog: usize) -> Result<TcpListener, NetError> {
    let opened: Result<NetHandle, NetError> = net_listen(addr, backlog)
    match opened {
        case Fine(handle):
            return Fine { value: TcpListener { _handle: handle, _open: true } }
        case Fail(error):
            return Fail { error: error }
    }
}

imply TcpStream: Reader {
    micro read(mut self, max: usize) -> Result<[u8], IoError> {
        if !self._open {
            return Fail { error: io_closed() }
        }
        return net_read(self._handle, max)
    }
}

imply TcpStream: Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, IoError> {
        if !self._open {
            return Fail { error: io_closed() }
        }
        return net_write(self._handle, bytes)
    }

    # 本层无内部缓冲：写出即交底层，`flush` 恒为成功；
    # 需要聚合小块写出的调用方用 `BufferedWriter` 显式加缓冲。
    micro flush(mut self) -> Option<IoError> {
        if !self._open {
            return Some(io_closed())
        }
        return None
    }
}

imply TcpStream {
    # 释放连接。幂等：对已关闭的流是无可观察效果的成功（`None`）。
    micro close(mut self) -> Option<IoError> {
        if !self._open {
            return None
        }
        self._open = false
        return net_close(self._handle)
    }

    micro is_open(self) -> bool {
        return self._open
    }
}

imply TcpListener {
    # 接受一条连接：产出的 `TcpStream` 独立持有新句柄，监听套接字不受影响。
    micro accept(mut self) -> Result<TcpStream, NetError> {
        if !self._open {
            return Fail { error: net_error(Closed) }
        }
        let incoming: Result<NetHandle, NetError> = net_accept(self._handle)
        match incoming {
            case Fine(handle):
                return Fine { value: TcpStream { _handle: handle, _open: true } }
            case Fail(error):
                return Fail { error: error }
        }
    }

    # 停止监听并释放。幂等，同 `TcpStream::close`。
    micro close(mut self) -> Option<IoError> {
        if !self._open {
            return None
        }
        self._open = false
        return net_close(self._handle)
    }
}
