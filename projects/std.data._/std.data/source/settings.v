namespace std.data;

# 解析设置：只承载所有格式都成立的公共字段。
#
# - `max_depth`：嵌套深度预算。parser/builder 消耗，超限必须结构化失败，不得崩溃。
# - `extension_fingerprint`：格式扩展设置的指纹。折叠规则由各格式包自己定义并写在
#   包内文档；公共层不知道、也不许知道任何格式扩展字段的名字。
#
# 新增公共字段的纪律：只允许加在所有格式都成立的类别（如"错误预算"），
# 不得为单个格式开洞。
structure DataSettings {
    max_depth: usize
    extension_fingerprint: usize
}

micro new_data_settings(max_depth: usize, extension_fingerprint: usize) -> DataSettings {
    return DataSettings {
        max_depth: max_depth,
        extension_fingerprint: extension_fingerprint
    }
}

# 设置指纹（缓存键的设置半部分）。
# 常数语义：31 是线性同余式混合乘数（与 djb2 的 33 同类的算法自选常数）。
micro data_settings_fingerprint(settings: DataSettings) -> usize {
    return settings.max_depth * 31 + settings.extension_fingerprint
}
