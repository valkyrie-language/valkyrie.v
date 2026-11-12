# std.network.tls — TLS 会话（TCP 之上的字节流包装；原生实现由 adaptor 绑定）

namespace std.network.tls;

using std.io::{Reader, Writer, IoError, io_closed};
using std.network::{NetHandle, TcpStream};
using std.types::{Result, Option, Some, None, Fine, Fail};

# 分层合同：
# - `TlsStream` 与 `TcpStream` 同属 `std.io` 字节流体系：实现 `Reader` 与
#   `Writer`，承载字节；握手、记录层与平台句柄全部归 adaptor。
# - 所有权移交协议：`wrap_tls` 按值消费 `TcpStream`。成功后底层流的持有
#   权转入 `TlsStream`，原持有者显式失效（不再存在可用的 `TcpStream`）；
#   失败时底层流随错误原样归还（`TlsHandoverFailure.stream`），调用方
#   仍可 `close`——握手失败不泄漏资源。
# - 终态三分：流尽（`read` 空块）、已关闭（`Closed`）、会话错误
#   （握手/证书/协议版本按 `TlsError` 种类结构化表达）。
# - 客户端合同强制给出服务端名称（SNI 与身份校验对象）与认证策略入口；
#   跳过校验必须是显式选择的策略值，不存在隐式默认。

# 协议版本下限。
enums TlsVersion {
    Tls12
    Tls13
}

# 客户端认证策略。
enums TlsAuthPolicy {
    # 以系统信任根校验对端证书，且证书身份须匹配服务端名称。
    SystemTrust
    # 显式跳过校验：仅供诊断与内网自签场景，调用方自担风险。
    InsecureSkipVerify
}

structure TlsServerConfig {
    cert_path: utf8
    key_path: utf8
    min_version: TlsVersion
}

structure TlsClientConfig {
    # SNI 与身份校验对象：客户端会话必须声明它。
    server_name: utf8
    auth: TlsAuthPolicy
    min_version: TlsVersion
}

# 会话角色与参数：带 payload 的可区分联合，服务端/客户端配置不混在
# 同一组可空字段里。
[tag(TlsRole)]
unite TlsConfig {
    [tag(0)]
    [constructor]
    Server {
        server: TlsServerConfig,
    },
    [tag(1)]
    [constructor]
    Client {
        client: TlsClientConfig,
    },
}

micro tls_server_config(cert_path: utf8, key_path: utf8, min_version: TlsVersion) -> TlsConfig {
    return Server { server: TlsServerConfig { cert_path: cert_path, key_path: key_path, min_version: min_version } }
}

micro tls_client_config(server_name: utf8, auth: TlsAuthPolicy, min_version: TlsVersion) -> TlsConfig {
    return Client { client: TlsClientConfig { server_name: server_name, auth: auth, min_version: min_version } }
}

# TLS 失败种类（结构化，不携带自由文本消息）。
enums TlsErrorKind {
    # 握手失败（对端中断或参数不合）。
    HandshakeFailed
    # 证书被认证策略拒绝。
    CertificateRejected
    # 协议版本不满足下限。
    ProtocolVersion
    # 会话已关闭。
    Closed
    # 底层失败，未细分。
    Failed
}

structure TlsError {
    kind: TlsErrorKind
}

micro tls_error(kind: TlsErrorKind) -> TlsError {
    return TlsError { kind: kind }
}

micro tls_error_kind(error: TlsError) -> TlsErrorKind {
    return error.kind
}

# 移交失败：错误 + 原样归还的底层流。调用方拿到归还的流仍可 `close`。
structure TlsHandoverFailure {
    error: TlsError
    stream: TcpStream
}

structure TlsStream {
    _session: NetHandle
    _inner: TcpStream
    _open: bool
}

# ── 宿主合同（adaptor 绑定；缺绑定的目标计划阶段结构化失败，无内建兜底）──

# 在既有传输句柄上建立 TLS 会话，返回会话句柄；失败按种类结构化表达。
[host_contract]
micro tls_establish(stream: NetHandle, config: TlsConfig) -> Result<NetHandle, TlsError>

# 会话流操作：字节模型，空块即流尽。
[host_contract]
micro tls_read(session: NetHandle, max: usize) -> Result<[u8], IoError>

[host_contract]
micro tls_write(session: NetHandle, bytes: ArrayView<u8>) -> Result<usize, IoError>

[host_contract]
micro tls_close(session: NetHandle) -> Option<IoError>

# ── 移交入口 ──────────────────────────────────────────────────────────

# 把 TCP 流升级为 TLS 会话流。按值消费 `TcpStream`：成功即所有权移交
# `TlsStream`，失败即随错误原样归还（见文件头移交协议）。
micro wrap_tls(stream: TcpStream, config: TlsConfig) -> Result<TlsStream, TlsHandoverFailure> {
    if !stream.is_open() {
        return Fail { error: TlsHandoverFailure { error: tls_error(Closed), stream: stream } }
    }
    let established: Result<NetHandle, TlsError> = tls_establish(stream._handle, config)
    match established {
        case Fine(session):
            return Fine { value: TlsStream { _session: session, _inner: stream, _open: true } }
        case Fail(error):
            return Fail { error: TlsHandoverFailure { error: error, stream: stream } }
    }
}

imply TlsStream: Reader {
    micro read(mut self, max: usize) -> Result<[u8], IoError> {
        if !self._open {
            return Fail { error: io_closed() }
        }
        return tls_read(self._session, max)
    }
}

imply TlsStream: Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, IoError> {
        if !self._open {
            return Fail { error: io_closed() }
        }
        return tls_write(self._session, bytes)
    }

    # 本层无 std 侧缓冲：写出即交记录层，`flush` 恒为成功；
    # 需要聚合小块写出的调用方用 `BufferedWriter` 显式加缓冲。
    micro flush(mut self) -> Option<IoError> {
        if !self._open {
            return Some(io_closed())
        }
        return None
    }
}

imply TlsStream {
    # 关闭会话并释放移交进来的底层流。幂等：已关闭时是无可观察效果的成功。
    micro close(mut self) -> Option<IoError> {
        if !self._open {
            return None
        }
        self._open = false
        let session_release: Option<IoError> = tls_close(self._session)
        let inner_release: Option<IoError> = self._inner.close()
        if session_release.is_some() {
            return session_release
        }
        return inner_release
    }

    micro is_open(self) -> bool {
        return self._open
    }
}
