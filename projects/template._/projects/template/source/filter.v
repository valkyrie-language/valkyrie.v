namespace template;

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};

# 内置过滤器 / 函数 / 测试注册表与实现（纯计算，不读上下文、不访问宿主）。
#
# 当前内置表（名称 → 参数区间）：
#   filter: uppercase/upper, lowercase/lower, trim, escape/e, safe/raw  (0..0)
#           default (1..1)，join (0..1)，replace (2..2)
#   function: range (2..3)，min/max (2..2)
#   test: null/none, truthy, empty, array, object, string, number, boolean, even, odd (0..0)
# date（时间源是宿主能力）与 slug（NFKD 需 Unicode 数据表）当前未提供，不在表内。
#
# 诊断码：template.render.unknown_filter / filter_arity / unknown_function /
# function_arity / unknown_test / test_arity。未知条目不穿透渲染栈，值落 Null。
#
# span 无从获知调用点（过滤器只拿到值），诊断用零宽哨兵 0..0；
# 调用点 span 由渲染段持有表达式节点位置后另行补充（尚未补充）。

structure TemplateFilterResult {
    value: TemplateValue
    diagnostics: [Diagnostic]
}

structure TemplateTestResult {
    passed: bool
    diagnostics: [Diagnostic]
}

micro template_filter_result(value: TemplateValue) -> TemplateFilterResult {
    return TemplateFilterResult { value: value, diagnostics: [] }
}

micro template_filter_failure(code: utf8, message: utf8) -> TemplateFilterResult {
    let mut diagnostics: [Diagnostic] = []
    diagnostics = push(diagnostics, new_diagnostic(code, Error, message, new_span(0, 0)))
    return TemplateFilterResult { value: NullValue, diagnostics: diagnostics }
}

micro template_function_failure(code: utf8, message: utf8) -> TemplateFilterResult {
    return template_filter_failure(code, message)
}

# ── 数字辅助 ──

micro template_number_is_integral(value: f64) -> bool {
    let self_difference: f64 = value - value
    if self_difference != 0.0 {
        return false
    }
    let bound: f64 = template_i64_safe_bound()
    if value >= bound || value <= 0.0 - bound {
        return false
    }
    let integral: i64 = value as i64
    return (integral as f64) == value
}

micro template_number_as_i64(value: f64) -> i64 {
    return value as i64
}

# ── 过滤器 ──

micro template_filter_min_arguments(name: utf8) -> usize {
    if name == "default" {
        return 1
    }
    if name == "replace" {
        return 2
    }
    return 0
}

micro template_filter_max_arguments(name: utf8) -> usize {
    if name == "default" {
        return 1
    }
    if name == "replace" {
        return 2
    }
    if name == "join" {
        return 1
    }
    return 0
}

micro template_is_known_filter(name: utf8) -> bool {
    return name == "uppercase" || name == "upper" || name == "lowercase" || name == "lower"
        || name == "trim" || name == "default" || name == "length" || name == "join"
        || name == "replace" || name == "escape" || name == "e" || name == "safe" || name == "raw"
}

micro template_apply_filter(name: utf8, value: TemplateValue, arguments: [TemplateValue]) -> TemplateFilterResult {
    if !template_is_known_filter(name) {
        return template_filter_failure("template.render.unknown_filter", "未知过滤器")
    }
    let arity: usize = arguments.length()
    if arity < template_filter_min_arguments(name) || arity > template_filter_max_arguments(name) {
        return template_filter_failure("template.render.filter_arity", "过滤器参数个数越界")
    }

    if name == "uppercase" || name == "upper" {
        return template_filter_result(TextValue { value: template_stringify(value).to_upper() })
    }
    if name == "lowercase" || name == "lower" {
        return template_filter_result(TextValue { value: template_stringify(value).to_lower() })
    }
    if name == "trim" {
        return template_filter_result(TextValue { value: template_stringify(value).trim() })
    }
    if name == "default" {
        # 仅 null 与 "" 视为缺失；0、false、空数组、空对象不替换。
        match value {
            case NullValue:
                return template_filter_result(arguments⁅0⁆.unwrap())
            case TextValue(payload):
                if payload.value.length() == 0 {
                    return template_filter_result(arguments⁅0⁆.unwrap())
                }
                return template_filter_result(value)
            else:
                return template_filter_result(value)
        }
    }
    if name == "length" {
        # 字符串按码点计数（Utf8Text.length 即码点数），数组按元素，对象按 key，其他为 0。
        match value {
            case TextValue(payload):
                return template_filter_result(NumberValue { value: payload.value.length() as f64 })
            case SafeTextValue(payload):
                return template_filter_result(NumberValue { value: payload.value.length() as f64 })
            case ArrayValue(payload):
                return template_filter_result(NumberValue { value: payload.items.length() as f64 })
            case ObjectValue(payload):
                return template_filter_result(NumberValue { value: payload.fields.length() as f64 })
            else:
                return template_filter_result(NumberValue { value: 0.0 })
        }
    }
    if name == "join" {
        let mut separator: utf8 = ","
        if arity == 1 {
            separator = template_stringify(arguments⁅0⁆.unwrap())
        }
        match value {
            case ArrayValue(payload):
                let mut output: utf8 = ""
                let mut index: usize = 0
                while index < payload.items.length() {
                    if index > 0 {
                        output = output + separator
                    }
                    output = output + template_stringify(payload.items⁅index⁆.unwrap())
                    index = index + 1
                }
                return template_filter_result(TextValue { value: output })
            else:
                return template_filter_result(TextValue { value: template_stringify(value) })
        }
    }
    if name == "replace" {
        let from: utf8 = template_stringify(arguments⁅0⁆.unwrap())
        let to: utf8 = template_stringify(arguments⁅1⁆.unwrap())
        return template_filter_result(TextValue { value: template_replace_all(template_stringify(value), from, to) })
    }
    if name == "escape" || name == "e" {
        # 内部已 HTML 转义，渲染时不再二次转义。
        return template_filter_result(SafeTextValue { value: template_escape_html(template_stringify(value)) })
    }
    if name == "safe" || name == "raw" {
        # 原值文本化并跳过自动转义。
        match value {
            case SafeTextValue(payload):
                return template_filter_result(value)
            case TextValue(payload):
                return template_filter_result(SafeTextValue { value: payload.value })
            else:
                return template_filter_result(SafeTextValue { value: template_stringify(value) })
        }
    }
    return template_filter_failure("template.render.unknown_filter", "未知过滤器")
}

# 全部替换（不依赖 `Utf8Text.replace` 的首次/全部语义歧义）。
micro template_replace_all(text: utf8, from: utf8, to: utf8) -> utf8 {
    if from.length() == 0 {
        return text
    }
    let mut output: utf8 = ""
    let mut rest: utf8 = text
    let mut searching: bool = true
    while searching {
        let found: usize? = rest.index_of(from)
        if found.is_none() {
            searching = false
        }
        else {
            let at: usize = found.unwrap()
            output = output + rest.slice(0, at) + to
            rest = rest.slice(at + from.length(), rest.length() - at - from.length())
        }
    }
    return output + rest
}

# ── 函数（裸标识符调用；纯函数，不读上下文）──

micro template_function_min_arguments(name: utf8) -> usize {
    # range / min / max 当前均为至少 2 参。
    return 2
}

micro template_function_max_arguments(name: utf8) -> usize {
    if name == "range" {
        return 3
    }
    return 2
}

micro template_is_known_function(name: utf8) -> bool {
    return name == "range" || name == "min" || name == "max"
}

micro template_call_function(name: utf8, arguments: [TemplateValue]) -> TemplateFilterResult {
    if !template_is_known_function(name) {
        return template_function_failure("template.render.unknown_function", "未知函数")
    }
    let arity: usize = arguments.length()
    if arity < template_function_min_arguments(name) || arity > template_function_max_arguments(name) {
        return template_function_failure("template.render.function_arity", "函数参数个数越界")
    }
    if name == "min" || name == "max" {
        let left: TemplateValue = arguments⁅0⁆.unwrap()
        let right: TemplateValue = arguments⁅1⁆.unwrap()
        match left {
            case NumberValue(first):
                match right {
                    case NumberValue(second):
                        # 有限即可比较；min/max 不限整数，仅拒绝非数字与非有限值。
                        let first_difference: f64 = first.value - first.value
                        let second_difference: f64 = second.value - second.value
                        if first_difference != 0.0 || second_difference != 0.0 {
                            return template_filter_result(NullValue)
                        }
                        if name == "min" {
                            if first.value <= second.value {
                                return template_filter_result(left)
                            }
                            return template_filter_result(right)
                        }
                        if first.value >= second.value {
                            return template_filter_result(left)
                        }
                        return template_filter_result(right)
                    else:
                        return template_filter_result(NullValue)
                }
            else:
                return template_filter_result(NullValue)
        }
    }
    if name == "range" {
        # range(start, stop, step=1)：仅整数；step 为 0、非整数参数、结果超过 10000 项 → null。
        let start_value: TemplateValue = arguments⁅0⁆.unwrap()
        let stop_value: TemplateValue = arguments⁅1⁆.unwrap()
        let mut step_value: TemplateValue = NumberValue { value: 1.0 }
        if arity == 3 {
            step_value = arguments⁅2⁆.unwrap()
        }
        match start_value {
            case NumberValue(start_payload):
                match stop_value {
                    case NumberValue(stop_payload):
                        match step_value {
                            case NumberValue(step_payload):
                                if !template_number_is_integral(start_payload.value)
                                    || !template_number_is_integral(stop_payload.value)
                                    || !template_number_is_integral(step_payload.value) {
                                    return template_filter_result(NullValue)
                                }
                                let start: i64 = template_number_as_i64(start_payload.value)
                                let stop: i64 = template_number_as_i64(stop_payload.value)
                                let step: i64 = template_number_as_i64(step_payload.value)
                                if step == 0 {
                                    return template_filter_result(NullValue)
                                }
                                let mut items: [TemplateValue] = []
                                let mut current: i64 = start
                                let mut count: i64 = 0
                                if step > 0 {
                                    while current < stop {
                                        count = count + 1
                                        if count > 10000 {
                                            return template_filter_result(NullValue)
                                        }
                                        items = push(items, NumberValue { value: current as f64 })
                                        current = current + step
                                    }
                                }
                                else {
                                    while current > stop {
                                        count = count + 1
                                        if count > 10000 {
                                            return template_filter_result(NullValue)
                                        }
                                        items = push(items, NumberValue { value: current as f64 })
                                        current = current + step
                                    }
                                }
                                return template_filter_result(ArrayValue { items: items })
                            else:
                                return template_filter_result(NullValue)
                        }
                    else:
                        return template_filter_result(NullValue)
                }
            else:
                return template_filter_result(NullValue)
        }
    }
    return template_function_failure("template.render.unknown_function", "未知函数")
}

# ── 测试（谓词命名空间，is / is not；不读上下文、不渲染输出）──

micro template_is_known_test(name: utf8) -> bool {
    return name == "null" || name == "none" || name == "truthy" || name == "empty"
        || name == "array" || name == "object" || name == "string" || name == "number"
        || name == "boolean" || name == "even" || name == "odd"
}

micro template_call_test(name: utf8, value: TemplateValue, arguments: [TemplateValue]) -> TemplateTestResult {
    if !template_is_known_test(name) {
        let mut diagnostics: [Diagnostic] = []
        diagnostics = push(diagnostics, new_diagnostic("template.render.unknown_test", Error, "未知测试", new_span(0, 0)))
        return TemplateTestResult { passed: false, diagnostics: diagnostics }
    }
    if arguments.length() != 0 {
        let mut diagnostics: [Diagnostic] = []
        diagnostics = push(diagnostics, new_diagnostic("template.render.test_arity", Error, "内置测试不接受参数", new_span(0, 0)))
        return TemplateTestResult { passed: false, diagnostics: diagnostics }
    }
    return TemplateTestResult { passed: template_run_test(name, value), diagnostics: [] }
}

micro template_run_test(name: utf8, value: TemplateValue) -> bool {
    if name == "null" || name == "none" {
        match value {
            case NullValue:
                return true
            else:
                return false
        }
    }
    if name == "truthy" {
        return template_truthy(value)
    }
    if name == "empty" {
        # ""、[]、{}；null 不算 empty。
        match value {
            case TextValue(payload):
                return payload.value.length() == 0
            case SafeTextValue(payload):
                return payload.value.length() == 0
            case ArrayValue(payload):
                return payload.items.length() == 0
            case ObjectValue(payload):
                return payload.fields.length() == 0
            else:
                return false
        }
    }
    if name == "array" {
        match value {
            case ArrayValue(payload):
                return true
            else:
                return false
        }
    }
    if name == "object" {
        match value {
            case ObjectValue(payload):
                return true
            else:
                return false
        }
    }
    if name == "string" {
        match value {
            case TextValue(payload):
                return true
            case SafeTextValue(payload):
                return true
            else:
                return false
        }
    }
    if name == "number" {
        match value {
            case NumberValue(payload):
                return true
            else:
                return false
        }
    }
    if name == "boolean" {
        match value {
            case BooleanValue(payload):
                return true
            else:
                return false
        }
    }
    if name == "even" || name == "odd" {
        # 仅整数参与奇偶；非整数数字两者都为 false。
        match value {
            case NumberValue(payload):
                if !template_number_is_integral(payload.value) {
                    return false
                }
                let integral: i64 = template_number_as_i64(payload.value)
                let remainder: i64 = integral % 2
                if name == "even" {
                    return remainder == 0
                }
                return remainder != 0
            else:
                return false
        }
    }
    return false
}
