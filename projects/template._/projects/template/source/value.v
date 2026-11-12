namespace template;

# 值模型与值运算：宿主无关合同。
#
# 值为 JSON 同构树（null/布尔/数字/字符串/数组/对象）加 `SafeTextValue` 安全文本标记
# （safe/raw/escape 过滤器的产出，插值不再二次转义）。对象键有序、字符串键，
# 以字段列表承载（插入序即语义序），不依赖哈希表。
# 变体名统一带 `Value` 后缀，避免与同命名空间的 token kind 变体冲突。

[tag(TemplateValueTag)]
unite TemplateValue {
    NullValue
    [constructor]
    BooleanValue { value: bool }
    [constructor]
    NumberValue { value: f64 }
    [constructor]
    TextValue { value: utf8 }
    [constructor]
    SafeTextValue { value: utf8 }
    [constructor]
    ArrayValue { items: [TemplateValue] }
    [constructor]
    ObjectValue { fields: [TemplateField] }
}

structure TemplateField {
    name: utf8
    value: TemplateValue
}

micro template_field(name: utf8, value: TemplateValue) -> TemplateField {
    return TemplateField { name: name, value: value }
}

micro template_null() -> TemplateValue {
    return NullValue
}

micro template_boolean(value: bool) -> TemplateValue {
    return BooleanValue { value: value }
}

micro template_number(value: f64) -> TemplateValue {
    return NumberValue { value: value }
}

micro template_text(value: utf8) -> TemplateValue {
    return TextValue { value: value }
}

micro template_safe_text(value: utf8) -> TemplateValue {
    return SafeTextValue { value: value }
}

micro template_array(items: [TemplateValue]) -> TemplateValue {
    return ArrayValue { items: items }
}

micro template_object(fields: [TemplateField]) -> TemplateValue {
    return ObjectValue { fields: fields }
}

# 缺失与 null 在值层面等价；但 strict 模式需要区分"缺失"与"显式 null"，
# 故查找返回 `TemplateValue?`：null 为缺失，Some(NullValue) 为显式 null。
micro template_object_get(value: TemplateValue, name: utf8) -> TemplateValue? {
    match value {
        case ObjectValue(payload):
            let mut index: usize = 0
            while index < payload.fields.length() {
                let field: TemplateField = payload.fields⁅index⁆.unwrap()
                if field.name == name {
                    return field.value
                }
                index = index + 1
            }
            return null
        else:
            return null
    }
}

# ── truthiness（合同表，不做宿主类型强制转换）──

micro template_truthy(value: TemplateValue) -> bool {
    match value {
        case NullValue:
            return false
        case BooleanValue(payload):
            return payload.value
        case NumberValue(payload):
            return payload.value != 0.0
        case TextValue(payload):
            return payload.value.length() > 0
        case SafeTextValue(payload):
            return payload.value.length() > 0
        case ArrayValue(payload):
            return payload.items.length() > 0
        case ObjectValue(payload):
            return payload.fields.length() > 0
    }
}

# ── 结构相等：不做跨类型转换（1 == "1" 为 false）──

micro template_values_equal(left: TemplateValue, right: TemplateValue) -> bool {
    match left {
        case NullValue:
            match right {
                case NullValue:
                    return true
                else:
                    return false
            }
        case BooleanValue(payload):
            match right {
                case BooleanValue(other):
                    return payload.value == other.value
                else:
                    return false
            }
        case NumberValue(payload):
            match right {
                case NumberValue(other):
                    return payload.value == other.value
                else:
                    return false
            }
        case TextValue(payload):
            match right {
                case TextValue(other):
                    return payload.value == other.value
                else:
                    return false
            }
        case SafeTextValue(payload):
            match right {
                case SafeTextValue(other):
                    return payload.value == other.value
                else:
                    return false
            }
        case ArrayValue(payload):
            match right {
                case ArrayValue(other):
                    if payload.items.length() != other.items.length() {
                        return false
                    }
                    let mut index: usize = 0
                    while index < payload.items.length() {
                        if !template_values_equal(payload.items⁅index⁆.unwrap(), other.items⁅index⁆.unwrap()) {
                            return false
                        }
                        index = index + 1
                    }
                    return true
                else:
                    return false
            }
        case ObjectValue(payload):
            match right {
                case ObjectValue(other):
                    if payload.fields.length() != other.fields.length() {
                        return false
                    }
                    let mut index: usize = 0
                    while index < payload.fields.length() {
                        let field: TemplateField = payload.fields⁅index⁆.unwrap()
                        let other_field: TemplateField = other.fields⁅index⁆.unwrap()
                        if field.name != other_field.name {
                            return false
                        }
                        if !template_values_equal(field.value, other_field.value) {
                            return false
                        }
                        index = index + 1
                    }
                    return true
                else:
                    return false
            }
    }
}

# ── 字符串化：null → ""，true/false → "true"/"false"，
# 数字按最短形态（整数值不带 .0），数组/对象为紧凑 JSON ──

micro template_stringify(value: TemplateValue) -> utf8 {
    match value {
        case NullValue:
            return ""
        case BooleanValue(payload):
            if payload.value {
                return "true"
            }
            return "false"
        case NumberValue(payload):
            return template_number_to_text(payload.value)
        case TextValue(payload):
            return payload.value
        case SafeTextValue(payload):
            return payload.value
        case ArrayValue(payload):
            let mut output: utf8 = "["
            let mut index: usize = 0
            while index < payload.items.length() {
                if index > 0 {
                    output = output + ","
                }
                output = output + template_stringify_json(payload.items⁅index⁆.unwrap())
                index = index + 1
            }
            return output + "]"
        case ObjectValue(payload):
            let mut output: utf8 = "{"
            let mut index: usize = 0
            while index < payload.fields.length() {
                if index > 0 {
                    output = output + ","
                }
                let field: TemplateField = payload.fields⁅index⁆.unwrap()
                output = output + template_stringify_json(TextValue { value: field.name })
                output = output + ":"
                output = output + template_stringify_json(field.value)
                index = index + 1
            }
            return output + "}"
    }
}

# 紧凑 JSON 形态（数组/对象成员用）：字符串带引号，其余同模板字符串化。
micro template_stringify_json(value: TemplateValue) -> utf8 {
    match value {
        case TextValue(payload):
            return template_double_quote() + payload.value + template_double_quote()
        case SafeTextValue(payload):
            return template_double_quote() + payload.value + template_double_quote()
        else:
            return template_stringify(value)
    }
}

# 双引号字符文本：经 `std.text` 编码内核把 `'"'` 字符直接编码为 UTF-8 文本，
# 构造点收口在唯一内核，不再按码值字节表手工构造。
micro template_double_quote() -> utf8 {
    return std::text::encode_char_as_utf8('"')
}

# ── 数字文本化 ──
# 整数路径精确（i64 数字发射）；非整数路径当前未支持，返回 `utf8?` 的 null，
# 由调用点产生 `template.render.number_fraction` 结构化诊断，不输出近似值。

micro template_number_to_text_option(value: f64) -> utf8? {
    # 有限性检查：有限值自减为零；inf/NaN 自减为 NaN，NaN 不等于自身。
    let self_difference: f64 = value - value
    if self_difference != 0.0 {
        return null
    }
    # 整数值判定需在 i64 可表示范围内（留余量，9e18 < 2^63；字面量超长被拒，
    # 用乘法常量）。
    let bound: f64 = template_i64_safe_bound()
    if value >= bound || value <= 0.0 - bound {
        return null
    }
    let integral: i64 = value as i64
    if (integral as f64) != value {
        return null
    }
    return template_i64_to_text(integral)
}

micro template_number_to_text(value: f64) -> utf8 {
    let rendered: utf8? = template_number_to_text_option(value)
    if rendered.is_none() {
        # 非整数/非有限值的字符串化当前未支持；此处返回空串只是占位形态，
        # 语义上调用点必须先查 `template_number_to_text_option` 并产诊断。
        return ""
    }
    return rendered.unwrap()
}

# i64 安全整数界（约 9e18 < 2^63）：字面量超长被 Oak 拒绝，用乘法表达。
micro template_i64_safe_bound() -> f64 {
    return 9000000000.0 * 1000000000.0
}

# i64 数字发射：逐位取模，倒序拼接。
micro template_i64_to_text(value: i64) -> utf8 {
    if value == 0 {
        return "0"
    }
    let mut negative: bool = false
    let mut magnitude: i64 = value
    if value < 0 {
        negative = true
        magnitude = 0 - value
    }
    let mut digits: utf8 = ""
    while magnitude > 0 {
        let digit: i64 = magnitude % 10
        digits = template_digit_text(digit) + digits
        magnitude = magnitude / 10
    }
    if negative {
        return "-" + digits
    }
    return digits
}

micro template_digit_text(digit: i64) -> utf8 {
    if digit == 0 {
        return "0"
    }
    if digit == 1 {
        return "1"
    }
    if digit == 2 {
        return "2"
    }
    if digit == 3 {
        return "3"
    }
    if digit == 4 {
        return "4"
    }
    if digit == 5 {
        return "5"
    }
    if digit == 6 {
        return "6"
    }
    if digit == 7 {
        return "7"
    }
    if digit == 8 {
        return "8"
    }
    return "9"
}

# ── 数字解析：十进制整数 + 可选小数（与词法 Number token 同形）。
# 词法已保证形态合法；解析为纯数字折叠，无宿主依赖。

micro template_parse_number(text: utf8) -> f64 {
    let length: usize = text.length()
    let mut value: f64 = 0.0
    let mut index: usize = 0
    let mut dot: usize = length
    # 整数部分：逐位十倍累加，遇小数点停止。
    while index < length {
        let c: char = text⁅index⁆
        if c == '.' {
            dot = index
            break
        }
        if c >= '0' && c <= '9' {
            value = value * 10.0 + ((c as u32) - 48) as f64
        }
        index = index + 1
    }
    # 小数部分：逐位以权重 0.1、0.01、… 累加。
    let mut fraction: f64 = 0.0
    let mut weight: f64 = 0.1
    index = dot + 1
    while index < length {
        let c: char = text⁅index⁆
        if c >= '0' && c <= '9' {
            fraction = fraction + ((c as u32) - 48) as f64 * weight
            weight = weight / 10.0
        }
        index = index + 1
    }
    return value + fraction
}
