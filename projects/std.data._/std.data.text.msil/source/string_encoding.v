namespace std.data.text.msil;

using std.text::{Utf8ByteIndicator, byte_indicates, Utf8Builder};

# Host string encoding contracts (do not conflate):
# - Language `utf8` / `Utf8Text`: UTF-8 storage in std; `length` / `slice` / `index_of`
#   are Unicode **scalar** indices (not UTF-8 byte offsets, not UTF-16 code units).
# - Language `utf16` / `Utf16Text`: UTF-16 **code units** (`System.String.get_Length` OK).
# - CLR `System.String` / JVM `java.lang.String` / JS `string`: UTF-16 **code units**.
# - Forbidden: lower `Utf8Text.length` / `slice` straight to `get_Length` / `Substring`
#   (or JS `.length` / `substring`) without scalar ↔ code-unit conversion
#   (`std.adaptor.clr.text.Utf8Text`, wasm `env.utf8_*` / JS `[...s]` scalars).
# - ILASM `ldstr "..."` payload is interpreted for the CLR string heap (UTF-16).
#   Raw multi-byte UTF-8 inside quotes breaks Framework ilasm for non-ASCII
#   (e.g. index quills U+2045/U+2046) — use `ldstr bytearray (UTF-16LE …)`.
# Indexing: never treat UTF-8 byte offsets as UTF-16 code-unit indices (or reverse)
# across an interop boundary without an explicit transcoder.

⍝ `ldstr` 渲染合同（码点是唯一扫描单位，不设语料白名单）：
⍝ - 源文本必须先经 `std::text::validate_utf8` 严格校验；非法序列结构化失败
⍝   （`Fail` 诊断），绝不降级为 `?` 占位。
⍝ - 全部码点落在 cooked 可表达集（可打印 ASCII + 反斜杠/双引号/制表/换行/回车
⍝   转义）时渲染带引号字符串；任一码点超出该集，整串改由
⍝   `bytearray (UTF-16LE hex)` 形式渲染——两种形态都是无损表示，不混排。
⍝ - bytearray 形态下每个码点经 `std::text::encode_utf16` 得到 UTF-16 码元
⍝   （astral 平面走代理对），按小端拆字节，逐字节经 `std::text::hex_encode`
⍝   编码、空格分隔。任何 Unicode 标量都可编码，无“不可编码后猜测输出”。
⍝ - 扫描游标与诊断 span 为码点口径；字节偏移只出现在 `byte_indicates` 内部。

micro msil_quote_char() -> utf8 {
    # Cooked strings reject `\"`; use Unicode escape for U+0022.
    return "\u{22}"
}

# Render CLR `ldstr` from language UTF-8 source text → UTF-16 string heap form.
# 不可编码输入（源文本非合法 UTF-8）以 `MsilParseResult::Fail` 结构化失败。
micro render_msil_ldstr_from_utf8_source(utf8_source: utf8) -> MsilParseResult<utf8> {
    match std::text::validate_utf8(utf8_source.bytes()) {
        case Fine(ok): {
        }
        case Fail(error):
            return Fail(new_msil_diagnostic("ldstr 源文本不是合法 UTF-8，无法编码为字符串堆内容", 0, utf8_source.length()))
    }

    let mut iter: Utf8ByteIndicator = byte_indicates(utf8_source)
    let mut escaped: Utf8Builder = Utf8Builder::new(utf8_source.byte_length())
    let mut le_bytes: ArrayList<u8> = ArrayList::new(utf8_source.length() * 2)
    let mut needs_utf16_bytearray: bool = false
    let mut pending: Option<(usize, char)> = iter.next()

    while pending.is_some() {
        let ch: char = pending.unwrap().1
        pending = iter.next()

        # 码点 → UTF-16 码元（经编码能力，astral 走代理对）→ 小端字节，供 bytearray 形态消费。
        let units: [u16] = std::text::encode_utf16(ch)
        let mut u: usize = 0
        while u < units.length {
            let unit: u32 = units[u] as u32
            le_bytes.push((unit % 256) as u8)
            le_bytes.push((unit / 256) as u8)
            u = u + 1
        }

        if ch == '\\' {
            escaped.append('\\')
            escaped.append('\\')
        } else if ch == '''"''' {
            escaped.append('\\')
            escaped.append('''"''')
        } else if ch == '\n' {
            escaped.append('\\')
            escaped.append('n')
        } else if ch == '\t' {
            escaped.append('\\')
            escaped.append('t')
        } else if ch == '\r' {
            escaped.append('\\')
            escaped.append('r')
        } else if ch >= ' ' && ch <= '~' {
            escaped.append(ch)
        } else {
            needs_utf16_bytearray = true
        }
    }

    if needs_utf16_bytearray {
        let mut line: Utf8Builder = Utf8Builder::new(le_bytes.length() * 3 + 16)
        line.append("bytearray (")
        let mut i: usize = 0
        while i < le_bytes.length() {
            if i > 0 {
                line.append(' ')
            }
            line.append(std::text::hex_encode([le_bytes⁅i⁆]))
            i = i + 1
        }
        line.append(")")
        return Fine(line.build())
    }

    let cooked: utf8 = escaped.build()
    let mut quoted: Utf8Builder = Utf8Builder::new(cooked.byte_length() + 2)
    quoted.append(msil_quote_char())
    quoted.append(cooked)
    quoted.append(msil_quote_char())
    return Fine(quoted.build())
}
