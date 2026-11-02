namespace std.data;

# 输入源身份：`label` 仅用于诊断展示，不参与缓存键；
# `content_digest` 是源内容的指纹，缓存键只认它。
structure DataSourceIdentity {
    label: utf8
    content_digest: usize
}

# 统一输入源：文本（字符流）与字节（二进制流）同构承载。
# 位置映射的单位由变体决定：Text 为字符偏移，Bytes 为字节偏移。
unite DataSource {
    [constructor]
    Text {
        text: utf8
        digest: usize
    }
    [constructor]
    Bytes {
        bytes: [u8]
        digest: usize
    }
}

# 内容指纹：djb2 同形的确定性折叠（usize 回绕），非加密、非安全边界。
# 仅用于缓存命中判定与变更检测，同一格式同一输入类型内自洽即可。
# 常数语义：5381 是 djb2 定义的种子，33 是 djb2 定义的乘数，均为算法自身常数。
micro data_text_digest(text: utf8) -> usize {
    let mut digest: usize = 5381
    let length: usize = text.length()
    let mut index: usize = 0
    while index < length {
        let code_point: usize = (text⁅index⁆ as u32) as usize
        digest = digest * 33 + code_point
        index = index + 1
    }
    return digest
}

micro data_bytes_digest(bytes: [u8]) -> usize {
    let mut digest: usize = 5381
    let length: usize = bytes.length()
    let mut index: usize = 0
    while index < length {
        let byte: usize = bytes⁅index⁆.unwrap() as usize
        digest = digest * 33 + byte
        index = index + 1
    }
    return digest
}

# 文本输入源构造，自动计算内容指纹。
micro data_source_from_text(text: utf8) -> DataSource {
    return Text {
        text: text,
        digest: data_text_digest(text)
    }
}

# 字节输入源构造，自动计算内容指纹。
micro data_source_from_bytes(bytes: [u8]) -> DataSource {
    return Bytes {
        bytes: bytes,
        digest: data_bytes_digest(bytes)
    }
}

# 源内容指纹（缓存键的源半部分）。
micro data_source_digest(source: DataSource) -> usize {
    match source {
        case Text(payload):
            payload.digest
        case Bytes(payload):
            payload.digest
    }
}

# 源长度（源单元计数：文本为字符数，字节为字节数）。
micro data_source_length(source: DataSource) -> usize {
    match source {
        case Text(payload):
            payload.text.length()
        case Bytes(payload):
            payload.bytes.length()
    }
}

# 源身份：`label` 仅展示用；缓存与命中判定不得使用 `label`。
micro data_source_identity(source: DataSource, label: utf8) -> DataSourceIdentity {
    return DataSourceIdentity {
        label: label,
        content_digest: data_source_digest(source)
    }
}
