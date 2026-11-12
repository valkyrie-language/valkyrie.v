namespace std.text;

⍝ ────────── 共享编码内核 ──────────
⍝ 码点与 UTF-8 字节序列、UTF-16 码元序列之间双向转换的唯一实现来源：
⍝ `Utf8Text`、`Utf16Text`、`Utf8Builder` 与各字符视图全部消费本模块，
⍝ 任何一侧不再写第二份解码/编码逻辑。
⍝ 严格 UTF-8 合同：只接受良构序列——意外续字节、截断序列、过长编码、
⍝ 代理区 D800–DFFF 与超过 U+10FFFF 的码位全部结构化失败。
⍝ `char` 的运行载体是 32 位无符号码位，值域不因编码边界收窄；
⍝ 非 Unicode 标量码位（代理项、> U+10FFFF）进入编码路径时显式失败。

# UTF-8 解码失败类别：每个变体携带出错字节位置（所在序列的起始字节）。
unite Utf8DecodeError {
    # 期望前导字节的位置出现续字节（0x80..0xBF）
    [constructor]
    UnexpectedContinuation { position: usize },
    # 不能开始任何良构序列的字节：0xC0、0xC1、0xF5..0xFF
    [constructor]
    InvalidLead { position: usize },
    # 前导字节合法，但应有的续字节缺失或非法（含输入提前结束）
    [constructor]
    Truncated { position: usize },
    # 该位置没有字节（`start` 不小于字节长度）
    [constructor]
    EndOfInput { position: usize },
    # 良构序列编码了小于该长度最小值的码位（E0 80..9F、F0 80..8F）
    [constructor]
    Overlong { position: usize },
    # 三字节序列编码了代理区码位（D800..DFFF）
    [constructor]
    Surrogate { position: usize },
    # 四字节序列编码了超过 U+10FFFF 的码位
    [constructor]
    TooLarge { position: usize },
}

# 码位进入编码路径时的失败类别：携带出错的码位本身。
unite Utf8EncodeError {
    # 代理区码位（D800..DFFF）不是 Unicode 标量，不可编码
    [constructor]
    SurrogateCodePoint { code_point: u32 },
    # 超过 U+10FFFF 的码位不在 Unicode 范围
    [constructor]
    BeyondUnicodeRange { code_point: u32 },
}

# UTF-16 码元序列解码的失败类别：落单代理项结构化失败，携带码元位置。
unite Utf16DecodeError {
    # 高代理项之后没有紧邻的低代理项
    [constructor]
    LoneHighSurrogate { position: usize },
    # 低代理项没有前置的高代理项
    [constructor]
    LoneLowSurrogate { position: usize },
    # 该位置没有码元（`start` 不小于码元长度）
    [constructor]
    EndOfInput { position: usize },
}

# Unicode 标量的 UTF-8 唯一点编码（0..0x10FFFF、排除代理区）：1 至 4 字节。
# 调用方负责先经 `check_unicode_scalar` 确认标量性；本函数不做二次判定。
private micro encode_scalar_utf8(code: u32) -> [u8] {
    if code <= 0x7F {
        return [code as u8]
    }

    if code <= 0x7FF {
        return [(0xC0 + (code >> 6)) as u8, (0x80 + (code & 0x3F)) as u8]
    }

    if code <= 0xFFFF {
        return [(0xE0 + (code >> 12)) as u8, (0x80 + ((code >> 6) & 0x3F)) as u8, (0x80 + (code & 0x3F)) as u8]
    }

    return [(0xF0 + (code >> 18)) as u8, (0x80 + ((code >> 12) & 0x3F)) as u8, (0x80 + ((code >> 6) & 0x3F)) as u8, (0x80 + (code & 0x3F)) as u8]
}

# 编码入口的标量检查：代理区与超范围码位结构化失败，其余给出码位值。
private micro check_unicode_scalar(value: char) -> Result<u32, Utf8EncodeError> {
    let code: u32 = value as u32
    if code >= 0xD800 && code <= 0xDFFF {
        return Fail { error: SurrogateCodePoint { code_point: code } }
    }

    if code > 0x10FFFF {
        return Fail { error: BeyondUnicodeRange { code_point: code } }
    }

    return Fine { value: code }
}

# 从 `start` 解码一个码点，返回（码点, 字节宽度）。
# 逐类别拒绝：意外续字节、非法前导、续字节不足、过长编码、代理区、超范围。
# `Utf8Text` 的解码与整串校验都只经由本函数，不另设第二份实现。
micro decode_char_at(bytes: [u8], start: usize) -> Result<(char, usize), Utf8DecodeError> {
    let size: usize = bytes.length()
    if start >= size {
        return Fail { error: EndOfInput { position: start } }
    }

    let first: u32 = bytes⁅start⁆ as u32
    if first <= 0x7F {
        return Fine { value: (first as char, 1) }
    }

    if (first & 0xC0) == 0x80 {
        return Fail { error: UnexpectedContinuation { position: start } }
    }

    if first <= 0xDF {
        if first < 0xC2 {
            return Fail { error: InvalidLead { position: start } }
        }

        if start + 1 >= size {
            return Fail { error: Truncated { position: start } }
        }

        let second: u32 = bytes⁅start + 1⁆ as u32
        if (second & 0xC0) != 0x80 {
            return Fail { error: Truncated { position: start } }
        }

        let code: u32 = ((first & 0x1F) << 6) | (second & 0x3F)
        return Fine { value: (code as char, 2) }
    }

    if first <= 0xEF {
        if start + 2 >= size {
            return Fail { error: Truncated { position: start } }
        }

        let second: u32 = bytes⁅start + 1⁆ as u32
        let third: u32 = bytes⁅start + 2⁆ as u32
        if (second & 0xC0) != 0x80 || (third & 0xC0) != 0x80 {
            return Fail { error: Truncated { position: start } }
        }

        let code: u32 = ((first & 0x0F) << 12) | ((second & 0x3F) << 6) | (third & 0x3F)
        if code < 0x800 {
            return Fail { error: Overlong { position: start } }
        }

        if code >= 0xD800 && code <= 0xDFFF {
            return Fail { error: Surrogate { position: start } }
        }

        return Fine { value: (code as char, 3) }
    }

    if first <= 0xF4 {
        if start + 3 >= size {
            return Fail { error: Truncated { position: start } }
        }

        let second: u32 = bytes⁅start + 1⁆ as u32
        let third: u32 = bytes⁅start + 2⁆ as u32
        let fourth: u32 = bytes⁅start + 3⁆ as u32
        if (second & 0xC0) != 0x80 || (third & 0xC0) != 0x80 || (fourth & 0xC0) != 0x80 {
            return Fail { error: Truncated { position: start } }
        }

        let code: u32 = ((first & 0x07) << 18) | ((second & 0x3F) << 12) | ((third & 0x3F) << 6) | (fourth & 0x3F)
        if code < 0x10000 {
            return Fail { error: Overlong { position: start } }
        }

        if code > 0x10FFFF {
            return Fail { error: TooLarge { position: start } }
        }

        return Fine { value: (code as char, 4) }
    }

    return Fail { error: InvalidLead { position: start } }
}

# 严格 UTF-8 全串校验：逐码点走 `decode_char_at`，首个非法序列即结构化失败。
micro validate_utf8(bytes: [u8]) -> Result<unit, Utf8DecodeError> {
    let size: usize = bytes.length()
    let mut position: usize = 0
    while position < size {
        let decoded: Result<(char, usize), Utf8DecodeError> = decode_char_at(bytes, position)
        match decoded {
            case Fine(pair):
                position = position + pair.1
            case Fail(error):
                return Fail { error: error }
        }
    }

    return Fine { value: () }
}

# char → UTF-8（可恢复形态）：非 Unicode 标量码位显式失败，不产出编码。
micro try_encode_char(value: char) -> Result<[u8], Utf8EncodeError> {
    match check_unicode_scalar(value) {
        case Fine(code):
            Fine { value: encode_scalar_utf8(code) }
        case Fail(error):
            Fail { error: error }
    }
}

# char → UTF-8（裸形态）：与 `try_encode_char` 同源；非 Unicode 标量码位在
# 编码边界显式失败（panic），不以畸形字节序列冒充成功。
micro encode_char(value: char) -> [u8] {
    return try_encode_char(value).unwrap()
}

# 从码元 `start` 解码一个码点，返回（码点, 消耗码元数 1 或 2）。
# 代理对合成唯一点：高代理项须紧邻低代理项；落单代理项结构化失败。
micro decode_utf16_at(units: [u16], start: usize) -> Result<(char, usize), Utf16DecodeError> {
    let size: usize = units.length()
    if start >= size {
        return Fail { error: EndOfInput { position: start } }
    }

    let first: u32 = units⁅start⁆ as u32
    if first < 0xD800 || first > 0xDBFF {
        if first >= 0xDC00 && first <= 0xDFFF {
            return Fail { error: LoneLowSurrogate { position: start } }
        }

        return Fine { value: (first as char, 1) }
    }

    if start + 1 >= size {
        return Fail { error: LoneHighSurrogate { position: start } }
    }

    let second: u32 = units⁅start + 1⁆ as u32
    if second < 0xDC00 || second > 0xDFFF {
        return Fail { error: LoneHighSurrogate { position: start } }
    }

    let code: u32 = 0x10000 + ((first - 0xD800) << 10) + (second - 0xDC00)
    return Fine { value: (code as char, 2) }
}

# Unicode 标量的 UTF-16 唯一点编码：不超 U+FFFF 落为单码元（先经标量检查
# 再收窄，无静默截断）；astral 标量分解为代理对。
private micro encode_scalar_utf16(code: u32) -> [u16] {
    if code <= 0xFFFF {
        return [code as u16]
    }

    let shifted: u32 = code - 0x10000
    return [(0xD800 + (shifted >> 10)) as u16, (0xDC00 + (shifted & 0x3FF)) as u16]
}

# char → UTF-16 码元（可恢复形态）：代理对分解见 `encode_scalar_utf16`；
# 非 Unicode 标量码位显式失败。
micro try_encode_utf16(value: char) -> Result<[u16], Utf8EncodeError> {
    match check_unicode_scalar(value) {
        case Fine(code):
            Fine { value: encode_scalar_utf16(code) }
        case Fail(error):
            Fail { error: error }
    }
}

# char → UTF-16 码元（裸形态）：与 `try_encode_utf16` 同源；非 Unicode 标量
# 码位在编码边界显式失败（panic）。
micro encode_utf16(value: char) -> [u16] {
    return try_encode_utf16(value).unwrap()
}

# 小写十六进制文本：每字节两位、ASCII 输出，构造即合法 UTF-8。
micro hex_encode(bytes: [u8]) -> utf8 {
    let mut digits: ArrayList<u8> = ArrayList::new(bytes.length() * 2)
    let mut index: usize = 0
    while index < bytes.length() {
        let byte: u32 = bytes⁅index⁆ as u32
        digits.push(hex_digit(byte >> 4))
        digits.push(hex_digit(byte & 0x0F))
        index = index + 1
    }

    return Utf8Text::from_bytes_unchecked(digits.to_array())
}

# 半字节 → 小写十六进制字符（'0'..'9'、'a'..'f'）。
private micro hex_digit(nibble: u32) -> u8 {
    if nibble < 10 {
        return (48 + nibble) as u8
    }

    return (87 + nibble) as u8
}
