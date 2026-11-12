namespace std.net;

using std.io::{Reader, Writer, IoError, PartialWrite, write_all};
using std.types::{Result, Option, Some, None, Fine, Fail};
using std.text::{Utf8Text, Utf8Builder};

# std.net: HTTP/1.1 报文层——建立在字节流协议模型之上的完整 request/response。
#
# 分层合同：
# - 传输无关：报文序列化与解析只依赖 `std.io` 的 `Reader`/`Writer` 合同。
#   连接可以是 `TcpStream`、`TlsStream` 或任何双向字节流（含 `Buffered*`
#   包装）；本层不认识 fd、不认识 TLS、不认识 URL 解析。
# - 消息体是字节（`body: [u8]`）：文本/JSON 编解码是消费方在字节之上的
#   显式选择，报文层不预设任何内容类型，也不以空串兼作失败哨兵。
# - 失败结构化三分：报文畸形（`Malformed`）、流提前结束（`UnexpectedEof`）、
#   传输错误（`Transport`，携带 `IoError` 种类）。`Content-Length` 非法、
#   `Transfer-Encoding` 等未交付分帧各有专种，不折叠成笼统失败。
# - 分帧合同：报文体一律按 `Content-Length` 计数读取；`Transfer-Encoding`
#   （chunked 等）显式不可用（`UnsupportedTransferEncoding`），不静默误读。
# - 逐字节行读取经 `Reader` 合同合法（空块即流尽）；性能敏感的调用方
#   应先用 `BufferedReader` 包装连接再进入本层。

# 方法：常见安全/幂等/实体方法为标记；扩展方法 token 不在标记枚举内，
# 属未交付能力，本层不为其伪造变体。
enums HttpMethod {
    Get
    Post
    Put
    Delete
    Head
    Options
    Patch
}

enums HttpVersion {
    Http10
    Http11
}

# 头部字段：名按 ASCII 大小写不敏感比较，值保留原文。
structure HttpHeader {
    name: utf8
    value: utf8
}

# 请求：`host` 是 Host 头的显式字段（HTTP/1.1 必需），不混进 headers 列表；
# `target` 是 origin-form（`/path?query`），authority 归 `host`。
structure HttpRequest {
    method: HttpMethod
    host: utf8
    target: utf8
    version: HttpVersion
    headers: [HttpHeader]
    body: [u8]
}

structure HttpResponse {
    version: HttpVersion
    status: u16
    reason: utf8
    headers: [HttpHeader]
    body: [u8]
}

# 报文层失败：带 payload 的可区分联合，种类即恢复决策依据。
[tag(HttpErrorKind)]
unite HttpError {
    # 报文语法畸形；`detail` 指出畸形的段落。
    [tag(0)]
    [constructor]
    Malformed {
        detail: utf8,
    },
    # 流在报文完整之前结束。
    [tag(1)]
    UnexpectedEof,
    # `Content-Length` 缺失于需要实体分帧的报文，或值非法。
    [tag(2)]
    InvalidContentLength,
    # 使用了未交付的分帧方式（`Transfer-Encoding` 等）。
    [tag(3)]
    UnsupportedTransferEncoding,
    # 传输层失败，携带底层种类。
    [tag(4)]
    [constructor]
    Transport {
        error: IoError,
    },
}

# ── 构造入口 ──────────────────────────────────────────────────────────

micro request_new(method: HttpMethod, host: utf8, target: utf8) -> HttpRequest {
    return HttpRequest { method: method, host: host, target: target, version: Http11, headers: [], body: [] }
}

micro request_with_body(method: HttpMethod, host: utf8, target: utf8, body: [u8]) -> HttpRequest {
    return HttpRequest { method: method, host: host, target: target, version: Http11, headers: [], body: body }
}

# 函数式追加头部：返回新请求，不原地改动。
micro request_add_header(request: HttpRequest, name: utf8, value: utf8) -> HttpRequest {
    let mut headers: [HttpHeader] = request.headers
    headers = headers.push(HttpHeader { name: name, value: value })
    return HttpRequest {
        method: request.method,
        host: request.host,
        target: request.target,
        version: request.version,
        headers: headers,
        body: request.body,
    }
}

micro response_new(status: u16, reason: utf8) -> HttpResponse {
    return HttpResponse { version: Http11, status: status, reason: reason, headers: [], body: [] }
}

micro response_with_body(status: u16, reason: utf8, body: [u8]) -> HttpResponse {
    return HttpResponse { version: Http11, status: status, reason: reason, headers: [], body: body }
}

micro response_add_header(response: HttpResponse, name: utf8, value: utf8) -> HttpResponse {
    let mut headers: [HttpHeader] = response.headers
    headers = headers.push(HttpHeader { name: name, value: value })
    return HttpResponse {
        version: response.version,
        status: response.status,
        reason: response.reason,
        headers: headers,
        body: response.body,
    }
}

micro header_lookup(headers: [HttpHeader], name: utf8) -> Option<utf8> {
    let mut index: usize = 0
    while index < headers.length {
        if ascii_equal_ignore_case(headers⁅index⁆.name, name) {
            return Some(headers⁅index⁆.value)
        }
        index = index + 1
    }
    return None
}

# ── 字节工具（报文层的 ASCII 骨架）────────────────────────────────────

structure ByteParts {
    head: [u8]
    tail: [u8]
}

micro slice_bytes(source: [u8], from: usize, to: usize) -> [u8] {
    let mut out: ArrayList<u8> = ArrayList::new(to - from)
    let mut index: usize = from
    while index < to {
        out.push(source⁅index⁆)
        index = index + 1
    }
    return out.to_array()
}

micro split_first_byte(line: [u8], separator: u8) -> Option<ByteParts> {
    let mut index: usize = 0
    while index < line.length {
        if line⁅index⁆ == separator {
            return Some(ByteParts { head: slice_bytes(line, 0, index), tail: slice_bytes(line, index + 1, line.length) })
        }
        index = index + 1
    }
    return None
}

# 线上字节进入文本字段前必须经 `Utf8Text::from_bytes` 严格验证：解码失败
# 归报文畸形（`detail` 指出畸形段落）。本层不 unwrap、不以空串顶替非法字节。
micro decode_wire_text(bytes: [u8], detail: utf8) -> Result<utf8, HttpError> {
    match Utf8Text::from_bytes(bytes) {
        case Fine(text):
            return Fine { value: text }
        case Fail(error):
            return Fail { error: Malformed { detail: detail } }
    }
}

micro ascii_lower(byte: u8) -> u8 {
    if byte >= b'A' && byte <= b'Z' {
        return byte + (b'a' - b'A')
    }
    return byte
}

micro ascii_equal_ignore_case(left: utf8, right: utf8) -> bool {
    let a: [u8] = Utf8Text::bytes(left)
    let b: [u8] = Utf8Text::bytes(right)
    if a.length != b.length {
        return false
    }
    let mut index: usize = 0
    while index < a.length {
        if ascii_lower(a⁅index⁆) != ascii_lower(b⁅index⁆) {
            return false
        }
        index = index + 1
    }
    return true
}

micro parse_digits_u64(digits: [u8]) -> Option<u64> {
    if digits.length == 0 {
        return None
    }
    let mut value: u64 = 0
    let mut index: usize = 0
    while index < digits.length {
        let byte: u8 = digits⁅index⁆
        if byte < b'0' || byte > b'9' {
            return None
        }
        value = value * 10 + (byte as u64) - (b'0' as u64)
        index = index + 1
    }
    return Some(value)
}

micro push_text(out: ArrayList<u8>, text: utf8) -> unit {
    let bytes: [u8] = Utf8Text::bytes(text)
    let mut index: usize = 0
    while index < bytes.length {
        out.push(bytes⁅index⁆)
        index = index + 1
    }
}

micro push_crlf(out: ArrayList<u8>) -> unit {
    out.push(b'\r')
    out.push(b'\n')
}

micro method_token(method: HttpMethod) -> utf8 {
    match method {
        case Get: {
            return "GET"
        }
        case Post: {
            return "POST"
        }
        case Put: {
            return "PUT"
        }
        case Delete: {
            return "DELETE"
        }
        case Head: {
            return "HEAD"
        }
        case Options: {
            return "OPTIONS"
        }
        case Patch: {
            return "PATCH"
        }
    }
}

micro method_from_token(token: utf8) -> Option<HttpMethod> {
    if token == "GET" {
        return Some(Get)
    }
    if token == "POST" {
        return Some(Post)
    }
    if token == "PUT" {
        return Some(Put)
    }
    if token == "DELETE" {
        return Some(Delete)
    }
    if token == "HEAD" {
        return Some(Head)
    }
    if token == "OPTIONS" {
        return Some(Options)
    }
    if token == "PATCH" {
        return Some(Patch)
    }
    return None
}

micro version_token(version: HttpVersion) -> utf8 {
    match version {
        case Http10: {
            return "HTTP/1.0"
        }
        case Http11: {
            return "HTTP/1.1"
        }
    }
}

micro version_from_token(token: utf8) -> Option<HttpVersion> {
    if token == "HTTP/1.1" {
        return Some(Http11)
    }
    if token == "HTTP/1.0" {
        return Some(Http10)
    }
    return None
}

# ── 写出（序列化）─────────────────────────────────────────────────────

# 请求线 + Host + 附加头 + Content-Length + 空行 + 实体字节。
# `Content-Length` 恒显式给出（零实体时为 0），分帧不依赖连接关闭。
micro write_request<W>(mut writer: W, request: HttpRequest) -> Option<HttpError>
    where W: Writer
{
    let mut out: ArrayList<u8> = ArrayList::new(256)
    push_text(out, method_token(request.method))
    push_text(out, " ")
    push_text(out, request.target)
    push_text(out, " ")
    push_text(out, version_token(request.version))
    push_crlf(out)
    push_text(out, "Host: ")
    push_text(out, request.host)
    push_crlf(out)
    let mut index: usize = 0
    while index < request.headers.length {
        push_text(out, request.headers⁅index⁆.name)
        push_text(out, ": ")
        push_text(out, request.headers⁅index⁆.value)
        push_crlf(out)
        index = index + 1
    }
    push_text(out, "Content-Length: ")
    push_text(out, digits_text(request.body.length as u64))
    push_crlf(out)
    push_crlf(out)
    let mut body_index: usize = 0
    while body_index < request.body.length {
        out.push(request.body⁅body_index⁆)
        body_index = body_index + 1
    }
    let commit: Result<usize, PartialWrite> = write_all(writer, out.view())
    match commit {
        case Fine(written):
            return None
        case Fail(partial):
            return Some(Transport { error: partial.error })
    }
}

micro write_response<W>(mut writer: W, response: HttpResponse) -> Option<HttpError>
    where W: Writer
{
    let mut out: ArrayList<u8> = ArrayList::new(256)
    push_text(out, version_token(response.version))
    push_text(out, " ")
    push_text(out, digits_text(response.status as u64))
    push_text(out, " ")
    push_text(out, response.reason)
    push_crlf(out)
    let mut index: usize = 0
    while index < response.headers.length {
        push_text(out, response.headers⁅index⁆.name)
        push_text(out, ": ")
        push_text(out, response.headers⁅index⁆.value)
        push_crlf(out)
        index = index + 1
    }
    push_text(out, "Content-Length: ")
    push_text(out, digits_text(response.body.length as u64))
    push_crlf(out)
    push_crlf(out)
    let mut body_index: usize = 0
    while body_index < response.body.length {
        out.push(response.body⁅body_index⁆)
        body_index = body_index + 1
    }
    let commit: Result<usize, PartialWrite> = write_all(writer, out.view())
    match commit {
        case Fine(written):
            return None
        case Fail(partial):
            return Some(Transport { error: partial.error })
    }
}

# 数值 → 十进制 ASCII 文本：委托 `Utf8Builder.append_u64` 的唯一整数内核，
# 本层不复制第二份十进制实现。
micro digits_text(value: u64) -> utf8 {
    let mut builder: Utf8Builder = Utf8Builder::new(20)
    builder.append_u64(value)
    return builder.build()
}

# ── 读取（解析）───────────────────────────────────────────────────────

# 读一行（至 LF，剥离可选 CR）。空块即流尽：行中途流尽按 `UnexpectedEof`
# 失败，不产出半行伪值。
micro read_ascii_line<R>(mut reader: R) -> Result<[u8], HttpError>
    where R: Reader
{
    let mut line: ArrayList<u8> = ArrayList::new(64)
    let mut reading: bool = true
    while reading {
        let next: Result<[u8], IoError> = reader.read(1)
        match next {
            case Fine(chunk): {
                if chunk.length == 0 {
                    return Fail { error: UnexpectedEof }
                }
                let byte: u8 = chunk⁅0⁆
                if byte == b'\n' {
                    if line.length > 0 && line⁅line.length - 1⁆ == b'\r' {
                        line.pop()
                    }
                    return Fine { value: line.to_array() }
                }
                line.push(byte)
            }
            case Fail(error):
                return Fail { error: Transport { error: error } }
        }
    }
    return Fail { error: UnexpectedEof }
}

# 按 `Content-Length` 计数读满实体；流中途结束按 `UnexpectedEof` 失败。
# 借用推进读取器（经 `mut` 参数），不复制带状态的读端。
micro read_body_bytes<R>(mut reader: R, count: usize) -> Result<[u8], HttpError>
    where R: Reader
{
    let mut collected: ArrayList<u8> = ArrayList::new(count)
    while collected.length < count {
        let remaining: usize = count - collected.length
        let chunk_result: Result<[u8], IoError> = reader.read(remaining)
        match chunk_result {
            case Fine(chunk): {
                if chunk.length == 0 {
                    return Fail { error: UnexpectedEof }
                }
                let mut index: usize = 0
                while index < chunk.length {
                    collected.push(chunk⁅index⁆)
                    index = index + 1
                }
            }
            case Fail(error):
                return Fail { error: Transport { error: error } }
        }
    }
    return Fine { value: collected.to_array() }
}

# 读头部序列（至空行）：返回头列表；`Transfer-Encoding` 出现即按未交付
# 分帧失败，不继续误读实体。
micro read_headers<R>(mut reader: R) -> Result<[HttpHeader], HttpError>
    where R: Reader
{
    let mut headers: [HttpHeader] = []
    let mut done: bool = false
    while !done {
        let line_result: Result<[u8], HttpError> = read_ascii_line(reader)
        match line_result {
            case Fine(line): {
                if line.length == 0 {
                    done = true
                }
                else {
                    let colon: Option<ByteParts> = split_first_byte(line, b':')
                    match colon {
                        case Some(parts): {
                            let value_bytes: [u8] = trim_leading_spaces(parts.tail)
                            let name: utf8 = match decode_wire_text(parts.head, "头部名段非 UTF-8") {
                                case Fine(text):
                                    text
                                case Fail(error):
                                    return Fail { error: error }
                            }
                            let value: utf8 = match decode_wire_text(value_bytes, "头部值段非 UTF-8") {
                                case Fine(text):
                                    text
                                case Fail(error):
                                    return Fail { error: error }
                            }
                            headers = headers.push(HttpHeader { name: name, value: value })
                        }
                        case None:
                            return Fail { error: Malformed { detail: "头部行缺少冒号分隔" } }
                    }
                }
            }
            case Fail(error):
                return Fail { error: error }
        }
    }
    return Fine { value: headers }
}

micro trim_leading_spaces(line: [u8]) -> [u8] {
    let mut start: usize = 0
    while start < line.length && line⁅start⁆ == b' ' {
        start = start + 1
    }
    return slice_bytes(line, start, line.length)
}

# 读响应。`want_body` 对应请求语义：HEAD/204 等无实体响应传 `false`，
# 此时忽略 `Content-Length`、不读实体字节。
micro read_response<R>(mut reader: R) -> Result<HttpResponse, HttpError>
    where R: Reader
{
    return read_response_framed(reader, true)
}

micro read_response_head_only<R>(mut reader: R) -> Result<HttpResponse, HttpError>
    where R: Reader
{
    return read_response_framed(reader, false)
}

micro read_response_framed<R>(mut reader: R, want_body: bool) -> Result<HttpResponse, HttpError>
    where R: Reader
{
    let status_line_result: Result<[u8], HttpError> = read_ascii_line(reader)
    let first: Option<ByteParts> = match status_line_result {
        case Fine(line):
            split_first_byte(line, b' ')
        case Fail(error):
            return Fail { error: error }
    }
    match first {
        case Some(version_parts): {
            let version_token: utf8 = match decode_wire_text(version_parts.head, "状态行版本段非 UTF-8") {
                case Fine(text):
                    text
                case Fail(error):
                    return Fail { error: error }
            }
            let version: Option<HttpVersion> = version_from_token(version_token)
            match version {
                case None:
                    return Fail { error: Malformed { detail: "状态行版本段非法" } }
                case Some(parsed_version): {
                    let second: Option<ByteParts> = split_first_byte(version_parts.tail, b' ')
                    match second {
                        case Some(status_parts): {
                            let status_value: Option<u64> = parse_digits_u64(status_parts.head)
                            match status_value {
                                case None:
                                    return Fail { error: Malformed { detail: "状态码非十进制数字" } }
                                case Some(raw_status): {
                                    if raw_status > 65535 {
                                        return Fail { error: Malformed { detail: "状态码越出 u16" } }
                                    }
                                    let headers_result: Result<[HttpHeader], HttpError> = read_headers(reader)
                                    match headers_result {
                                        case Fail(error):
                                            return Fail { error: error }
                                        case Fine(headers): {
                                            let body_result: Result<[u8], HttpError> = frame_body(reader, headers, want_body)
                                            match body_result {
                                                case Fail(error):
                                                    return Fail { error: error }
                                                case Fine(body): {
                                                    let reason: utf8 = match decode_wire_text(status_parts.tail, "原因短语段非 UTF-8") {
                                                        case Fine(text):
                                                            text
                                                        case Fail(error):
                                                            return Fail { error: error }
                                                    }
                                                    return Fine { value: HttpResponse {
                                                        version: parsed_version,
                                                        status: raw_status as u16,
                                                        reason: reason,
                                                        headers: headers,
                                                        body: body,
                                                    } }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        case None: {
                            # 「HTTP/1.1 204」允许无原因短语：整段即状态码。
                            let status_value: Option<u64> = parse_digits_u64(version_parts.tail)
                            match status_value {
                                case None:
                                    return Fail { error: Malformed { detail: "状态行结构非法" } }
                                case Some(raw_status): {
                                    let headers_result: Result<[HttpHeader], HttpError> = read_headers(reader)
                                    match headers_result {
                                        case Fail(error):
                                            return Fail { error: error }
                                        case Fine(headers): {
                                            let body_result: Result<[u8], HttpError> = frame_body(reader, headers, want_body)
                                            match body_result {
                                                case Fail(error):
                                                    return Fail { error: error }
                                                case Fine(body):
                                                    return Fine { value: HttpResponse {
                                                        version: parsed_version,
                                                        status: raw_status as u16,
                                                        reason: "",
                                                        headers: headers,
                                                        body: body,
                                                    } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        case None:
            return Fail { error: Malformed { detail: "状态行缺少空格分隔" } }
    }
}

# 实体分帧：chunked 等一律显式不可用；`want_body` 时按 `Content-Length`
# 计数读取，缺失即零实体。
micro frame_body<R>(mut reader: R, headers: [HttpHeader], want_body: bool) -> Result<[u8], HttpError>
    where R: Reader
{
    let encoding: Option<utf8> = header_lookup(headers, "Transfer-Encoding")
    if encoding.is_some() {
        return Fail { error: UnsupportedTransferEncoding }
    }
    if !want_body {
        return Fine { value: [] }
    }
    let length_text: Option<utf8> = header_lookup(headers, "Content-Length")
    match length_text {
        case None:
            return Fine { value: [] }
        case Some(text): {
            let length_value: Option<u64> = parse_digits_u64(Utf8Text::bytes(text))
            match length_value {
                case None:
                    return Fail { error: InvalidContentLength }
                case Some(count): {
                    return read_body_bytes(reader, count as usize)
                }
            }
        }
    }
}

# 读请求（服务端入口）：请求线 + 头部 + 按 `Content-Length` 的实体。
micro read_request<R>(mut reader: R) -> Result<HttpRequest, HttpError>
    where R: Reader
{
    let request_line_result: Result<[u8], HttpError> = read_ascii_line(reader)
    match request_line_result {
        case Fail(error):
            return Fail { error: error }
        case Fine(line): {
            let first: Option<ByteParts> = split_first_byte(line, b' ')
            match first {
                case None:
                    return Fail { error: Malformed { detail: "请求行缺少空格分隔" } }
                case Some(method_parts): {
                    let method_token: utf8 = match decode_wire_text(method_parts.head, "方法段非 UTF-8") {
                        case Fine(text):
                            text
                        case Fail(error):
                            return Fail { error: error }
                    }
                    let method: Option<HttpMethod> = method_from_token(method_token)
                    match method {
                        case None:
                            return Fail { error: Malformed { detail: "方法不在已交付集合内" } }
                        case Some(parsed_method): {
                            let second: Option<ByteParts> = split_first_byte(method_parts.tail, b' ')
                            match second {
                                case None:
                                    return Fail { error: Malformed { detail: "请求行缺少版本段" } }
                                case Some(target_parts): {
                                    let version_token: utf8 = match decode_wire_text(target_parts.tail, "版本段非 UTF-8") {
                                        case Fine(text):
                                            text
                                        case Fail(error):
                                            return Fail { error: error }
                                    }
                                    let version: Option<HttpVersion> = version_from_token(version_token)
                                    match version {
                                        case None:
                                            return Fail { error: Malformed { detail: "版本段非法" } }
                                        case Some(parsed_version): {
                                            let headers_result: Result<[HttpHeader], HttpError> = read_headers(reader)
                                            match headers_result {
                                                case Fail(error):
                                                    return Fail { error: error }
                                                case Fine(headers): {
                                                    let host_value: Option<utf8> = header_lookup(headers, "Host")
                                                    let body_result: Result<[u8], HttpError> = frame_body(reader, headers, true)
                                                    match body_result {
                                                        case Fail(error):
                                                            return Fail { error: error }
                                                        case Fine(body): {
                                                            let target: utf8 = match decode_wire_text(target_parts.head, "请求目标段非 UTF-8") {
                                                                case Fine(text):
                                                                    text
                                                                case Fail(error):
                                                                    return Fail { error: error }
                                                            }
                                                            return Fine { value: HttpRequest {
                                                                method: parsed_method,
                                                                host: host_value.unwrap_or(""),
                                                                target: target,
                                                                version: parsed_version,
                                                                headers: headers,
                                                                body: body,
                                                            } }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

# ── 客户端组合（一次请求-响应往返）────────────────────────────────────

# 在双向字节流上完成一次请求-响应交换。连接由调用方持有并负责生命周期
# （`close` 归资源所有者，本层不接管）；需要读无实体响应时用
# `write_request` + `read_response_head_only` 自行组合。
micro exchange<C>(mut connection: C, request: HttpRequest) -> Result<HttpResponse, HttpError>
    where C: Reader + Writer
{
    let send: Option<HttpError> = write_request(connection, request)
    if send.is_some() {
        return Fail { error: send.unwrap() }
    }
    return read_response(connection)
}

micro get<C>(mut connection: C, host: utf8, target: utf8) -> Result<HttpResponse, HttpError>
    where C: Reader + Writer
{
    return exchange(connection, request_new(Get, host, target))
}

micro post<C>(mut connection: C, host: utf8, target: utf8, body: [u8]) -> Result<HttpResponse, HttpError>
    where C: Reader + Writer
{
    return exchange(connection, request_with_body(Post, host, target, body))
}

micro put<C>(mut connection: C, host: utf8, target: utf8, body: [u8]) -> Result<HttpResponse, HttpError>
    where C: Reader + Writer
{
    return exchange(connection, request_with_body(Put, host, target, body))
}

micro delete<C>(mut connection: C, host: utf8, target: utf8) -> Result<HttpResponse, HttpError>
    where C: Reader + Writer
{
    return exchange(connection, request_new(Delete, host, target))
}
