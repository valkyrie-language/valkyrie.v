namespace template;

using std.data::{DataCstNode, DataDiagnostic, DataOutcome, DataSettings, DataToken, Error, data_outcome_diagnostics, data_outcome_value, data_outcome_with, data_source_from_text, DataSource, new_data_diagnostic, new_data_span};

# 渲染段：AST + 上下文 -> 输出文本。纯内存求值，不读文件/网络/时钟。
#
# 作用域模型：帧栈（数组，内层在后）。loop 每次迭代压入一帧（循环变量 + `forloop`
# 隐式绑定），迭代结束帧随调用返回自然消失；同名遮蔽与恢复由帧栈结构保证。
# `forloop.depth` 入口规则：当前可见 `forloop` 是对象且其 `depth` 为不小于 1 的整数时
# 新 depth = depth + 1，否则 1。
#
# 控制流：break/continue 以显式信号沿渲染调用栈上传，绑定词法最近外层 loop 消费；
# 信号不被任何中间层吞掉。
#
# 转义出口：插值默认 HTML 转义；`SafeTextValue`（safe/raw/escape 过滤器产出）跳过。
# 求值错误不穿透渲染栈：登记 Error 诊断、值落 NullValue、渲染继续（DataOutcome 错误容许）。

# 渲染设置。
structure TemplateRenderSettings {
    strict_undefined: bool
    max_depth: usize
}

micro template_default_render_settings() -> TemplateRenderSettings {
    return TemplateRenderSettings { strict_undefined: false, max_depth: 64 }
}

unite TemplateSignal {
    SignalNone
    SignalBreak
    SignalContinue
}

structure TemplateChunk {
    text: utf8
    signal: TemplateSignal
    diagnostics: [DataDiagnostic]
}

structure TemplateEvaluation {
    value: TemplateValue
    diagnostics: [DataDiagnostic]
}

structure TemplateFrame {
    fields: [TemplateField]
}

micro template_chunk(text: utf8) -> TemplateChunk {
    return TemplateChunk { text: text, signal: SignalNone, diagnostics: [] }
}

micro template_evaluation(value: TemplateValue) -> TemplateEvaluation {
    return TemplateEvaluation { value: value, diagnostics: [] }
}

micro template_evaluation_failed(code: utf8, message: utf8) -> TemplateEvaluation {
    let mut diagnostics: [DataDiagnostic] = []
    diagnostics = push(diagnostics, new_data_diagnostic(code, Error, message, new_data_span(0, 0)))
    return TemplateEvaluation { value: NullValue, diagnostics: diagnostics }
}

# ── 标识符查找：内层帧优先，最后落到根上下文 ──

micro template_lookup(name: utf8, frames: [TemplateFrame], context: TemplateValue) -> TemplateValue? {
    let mut index: usize = frames.length()
    while index > 0 {
        index = index - 1
        let frame: TemplateFrame = frames⁅index⁆.unwrap()
        let mut field_index: usize = 0
        while field_index < frame.fields.length() {
            let field: TemplateField = frame.fields⁅field_index⁆.unwrap()
            if field.name == name {
                return field.value
            }
            field_index = field_index + 1
        }
    }
    return template_object_get(context, name)
}

micro template_merge_diagnostics(into: [DataDiagnostic], from: [DataDiagnostic]) -> [DataDiagnostic] {
    let mut result: [DataDiagnostic] = into
    let mut index: usize = 0
    while index < from.length() {
        result = push(result, from⁅index⁆.unwrap())
        index = index + 1
    }
    return result
}

# ── 入口 ──

micro template_render(document: TemplateDocument, context: TemplateValue, settings: TemplateRenderSettings) -> DataOutcome<utf8> {
    let frames: [TemplateFrame] = []
    let chunk: TemplateChunk = template_render_nodes(document.body, document.expressions, frames, context, settings, 1)
    return data_outcome_with(chunk.text, chunk.diagnostics)
}

# 端到端便利入口：source -> lex -> parse -> build -> render，诊断全程聚合。
micro template_render_text(source: utf8, context: TemplateValue, settings: DataSettings, render_settings: TemplateRenderSettings) -> DataOutcome<utf8> {
    let data_source: DataSource = data_source_from_text(source)
    let lexed: DataOutcome<[DataToken<TemplateTokenKind>]> = template_lex(data_source, settings)
    let mut diagnostics: [DataDiagnostic] = []
    diagnostics = template_merge_diagnostics(diagnostics, data_outcome_diagnostics(lexed))
    let parsed: DataOutcome<DataCstNode<TemplateTokenKind>> = template_parse(data_outcome_value(lexed), settings)
    diagnostics = template_merge_diagnostics(diagnostics, data_outcome_diagnostics(parsed))
    let built: DataOutcome<TemplateDocument> = template_build(data_outcome_value(parsed), data_source, settings)
    diagnostics = template_merge_diagnostics(diagnostics, data_outcome_diagnostics(built))
    let rendered: DataOutcome<utf8> = template_render(data_outcome_value(built), context, render_settings)
    diagnostics = template_merge_diagnostics(diagnostics, data_outcome_diagnostics(rendered))
    return data_outcome_with(data_outcome_value(rendered), diagnostics)
}

# ── 语句渲染 ──

micro template_render_nodes(nodes: [TemplateNode], expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    if depth > settings.max_depth {
        let mut diagnostics: [DataDiagnostic] = []
        diagnostics = push(diagnostics, new_data_diagnostic("template.render.max_depth_exceeded", Error, "渲染嵌套深度超限", new_data_span(0, 0)))
        return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
    }
    let mut text: utf8 = ""
    let mut signal: TemplateSignal = SignalNone
    let mut diagnostics: [DataDiagnostic] = []
    let mut index: usize = 0
    while index < nodes.length() {
        let node: TemplateNode = nodes⁅index⁆.unwrap()
        match node {
            case TextNode(payload):
                text = text + payload.text
            case InterpolationNode(payload):
                let evaluated: TemplateEvaluation = template_evaluate(payload.expression, expressions, frames, context, settings, depth + 1)
                diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
                let output: TemplateChunk = template_interpolation_output(evaluated.value)
                text = text + output.text
                diagnostics = template_merge_diagnostics(diagnostics, output.diagnostics)
            case IfNode(payload):
                let branch: TemplateChunk = template_render_if(payload.branches, payload.alternate, expressions, frames, context, settings, depth)
                text = text + branch.text
                diagnostics = template_merge_diagnostics(diagnostics, branch.diagnostics)
            case LoopNode(payload):
                let looped: TemplateChunk = template_render_loop(payload.item, payload.iterable, payload.body, expressions, frames, context, settings, depth)
                text = text + looped.text
                diagnostics = template_merge_diagnostics(diagnostics, looped.diagnostics)
            case BreakNode:
                signal = SignalBreak
                index = nodes.length()
            case ContinueNode:
                signal = SignalContinue
                index = nodes.length()
            case MissingNode(payload):
                diagnostics = push(diagnostics, new_data_diagnostic("template.render.broken_node", Error, "渲染遇到缺席占位节点", new_data_span(0, 0)))
            case PoisonNode(payload):
                diagnostics = push(diagnostics, new_data_diagnostic("template.render.broken_node", Error, "渲染遇到污染节点", new_data_span(0, 0)))
            else: {
                # CommentNode：注释不进入渲染输出。
            }
        }
        index = index + 1
    }
    return TemplateChunk { text: text, signal: signal, diagnostics: diagnostics }
}

# if：依序求值分支条件，首个 truthy 分支渲染；都不中渲染 alternate。
micro template_render_if(branches: [TemplateIfBranch], alternate: [TemplateNode], expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    let mut diagnostics: [DataDiagnostic] = []
    let mut index: usize = 0
    while index < branches.length() {
        let branch: TemplateIfBranch = branches⁅index⁆.unwrap()
        let tested: TemplateEvaluation = template_evaluate(branch.test, expressions, frames, context, settings, depth + 1)
        diagnostics = template_merge_diagnostics(diagnostics, tested.diagnostics)
        if template_truthy(tested.value) {
            let chunk: TemplateChunk = template_render_nodes(branch.body, expressions, frames, context, settings, depth + 1)
            return TemplateChunk { text: chunk.text, signal: chunk.signal, diagnostics: template_merge_diagnostics(diagnostics, chunk.diagnostics) }
        }
        index = index + 1
    }
    let fallback: TemplateChunk = template_render_nodes(alternate, expressions, frames, context, settings, depth + 1)
    return TemplateChunk { text: fallback.text, signal: fallback.signal, diagnostics: template_merge_diagnostics(diagnostics, fallback.diagnostics) }
}

# loop：iterable 必须是数组（否则 `template.render.invalid_iterable`）。
# 每次迭代压入一帧：循环变量 + `forloop`（index/index0/first/last/length/depth）。
# break 终止循环并继续后续内容；continue 跳过当前迭代剩余 body。
micro template_render_loop(item: utf8, iterable: usize, body: [TemplateNode], expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    let mut diagnostics: [DataDiagnostic] = []
    let evaluated: TemplateEvaluation = template_evaluate(iterable, expressions, frames, context, settings, depth + 1)
    diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
    match evaluated.value {
        case ArrayValue(payload):
            let items: [TemplateValue] = payload.items
            let total: usize = items.length()
            let loop_depth_value: usize = template_forloop_depth(frames, context)
            let mut text: utf8 = ""
            let mut index: usize = 0
            while index < total {
                let forloop_fields: [TemplateField] = [
                    template_field("index", NumberValue { value: (index + 1) as f64 }),
                    template_field("index0", NumberValue { value: index as f64 }),
                    template_field("first", BooleanValue { value: index == 0 }),
                    template_field("last", BooleanValue { value: index + 1 == total }),
                    template_field("length", NumberValue { value: total as f64 }),
                    template_field("depth", NumberValue { value: loop_depth_value as f64 })
                ]
                let frame_fields: [TemplateField] = [
                    template_field(item, items⁅index⁆.unwrap()),
                    template_field("forloop", ObjectValue { fields: forloop_fields })
                ]
                let frame: TemplateFrame = TemplateFrame { fields: frame_fields }
                let iteration_frames: [TemplateFrame] = push(frames, frame)
                let chunk: TemplateChunk = template_render_nodes(body, expressions, iteration_frames, context, settings, depth + 1)
                text = text + chunk.text
                diagnostics = template_merge_diagnostics(diagnostics, chunk.diagnostics)
                match chunk.signal {
                    case SignalBreak:
                        index = total
                    else: {
                        # SignalNone / SignalContinue：进入下一次迭代。
                    }
                }
                index = index + 1
            }
            return TemplateChunk { text: text, signal: SignalNone, diagnostics: diagnostics }
        else:
            diagnostics = push(diagnostics, new_data_diagnostic("template.render.invalid_iterable", Error, "loop 的 iterable 必须是数组", new_data_span(0, 0)))
            return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
    }
}

# `forloop.depth` 入口规则。
micro template_forloop_depth(frames: [TemplateFrame], context: TemplateValue) -> usize {
    let visible: TemplateValue? = template_lookup("forloop", frames, context)
    if visible.is_none() {
        return 1
    }
    match visible.unwrap() {
        case ObjectValue(payload):
            let depth_value: TemplateValue? = template_object_get(ObjectValue { fields: payload.fields }, "depth")
            if depth_value.is_none() {
                return 1
            }
            match depth_value.unwrap() {
                case NumberValue(number):
                    if template_number_is_integral(number.value) && number.value >= 1.0 {
                        return template_number_as_i64(number.value) as usize + 1
                    }
                    return 1
                else:
                    return 1
            }
        else:
            return 1
    }
}

# 插值出口：SafeTextValue 原文输出；其余字符串化后 HTML 转义。
# 非整数数字的字符串化是已登记缺口：产 `template.render.number_fraction`（Error）。
micro template_interpolation_output(value: TemplateValue) -> TemplateChunk {
    match value {
        case SafeTextValue(payload):
            return template_chunk(payload.value)
        case NumberValue(payload):
            let rendered: utf8? = template_number_to_text_option(payload.value)
            if rendered.is_none() {
                let mut diagnostics: [DataDiagnostic] = []
                diagnostics = push(diagnostics, new_data_diagnostic("template.render.number_fraction", Error, "非整数/非有限数字的字符串化首块未支持", new_data_span(0, 0)))
                return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
            }
            return template_chunk(template_escape_html(rendered.unwrap()))
        else:
            return template_chunk(template_escape_html(template_stringify(value)))
    }
}

# ── 表达式求值 ──

micro template_evaluate(index: usize, expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    if depth > settings.max_depth {
        return template_evaluation_failed("template.render.max_depth_exceeded", "表达式求值深度超限")
    }
    if index >= expressions.length() {
        return template_evaluation_failed("template.render.broken_expression", "表达式句柄越界")
    }
    let expression: TemplateExpression = expressions⁅index⁆.unwrap()
    match expression {
        case LiteralNull:
            return template_evaluation(NullValue)
        case LiteralTrue:
            return template_evaluation(BooleanValue { value: true })
        case LiteralFalse:
            return template_evaluation(BooleanValue { value: false })
        case LiteralNumber(payload):
            return template_evaluation(NumberValue { value: payload.value })
        case LiteralString(payload):
            return template_evaluation(TextValue { value: payload.value })
        case Identifier(payload):
            let found: TemplateValue? = template_lookup(payload.name, frames, context)
            if found.is_none() {
                if settings.strict_undefined {
                    return template_evaluation_failed("template.render.undefined_variable", "未定义的标识符")
                }
                return template_evaluation(NullValue)
            }
            return template_evaluation(found.unwrap())
        case ObjectLiteral(payload):
            let mut fields: [TemplateField] = []
            let mut diagnostics: [DataDiagnostic] = []
            let mut entry_index: usize = 0
            while entry_index < payload.entries.length() {
                let entry: TemplateObjectEntry = payload.entries⁅entry_index⁆.unwrap()
                let evaluated: TemplateEvaluation = template_evaluate(entry.value, expressions, frames, context, settings, depth + 1)
                diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
                fields = push(fields, template_field(entry.key, evaluated.value))
                entry_index = entry_index + 1
            }
            return TemplateEvaluation { value: ObjectValue { fields: fields }, diagnostics: diagnostics }
        case Member(payload):
            let object: TemplateEvaluation = template_evaluate(payload.object, expressions, frames, context, settings, depth + 1)
            let found: TemplateValue? = template_object_get(object.value, payload.property)
            if found.is_none() {
                return TemplateEvaluation { value: NullValue, diagnostics: object.diagnostics }
            }
            return TemplateEvaluation { value: found.unwrap(), diagnostics: object.diagnostics }
        case Index(payload):
            return template_evaluate_index(payload.object, payload.index, expressions, frames, context, settings, depth)
        case Call(payload):
            return template_evaluate_call(payload.callee, payload.arguments, expressions, frames, context, settings, depth)
        case Binary(payload):
            return template_evaluate_binary(payload.operator, payload.left, payload.right, expressions, frames, context, settings, depth)
        case Unary(payload):
            return template_evaluate_unary(payload.operator, payload.operand, expressions, frames, context, settings, depth)
        case Pipe(payload):
            return template_evaluate_pipe(payload.expression, payload.filter, payload.arguments, expressions, frames, context, settings, depth)
        case Test(payload):
            return template_evaluate_test(payload.expression, payload.name, payload.arguments, payload.negated, expressions, frames, context, settings, depth)
        case ExpressionMissing(payload):
            return template_evaluation_failed("template.render.broken_expression", "求值遇到缺席占位表达式")
        case ExpressionPoison(payload):
            return template_evaluation_failed("template.render.broken_expression", "求值遇到污染表达式")
    }
}

# 下标：数组按整数下标（越界/非整数 -> 缺失）；对象按字符串化键；其余 -> 缺失。
micro template_evaluate_index(object_index: usize, index_index: usize, expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let object: TemplateEvaluation = template_evaluate(object_index, expressions, frames, context, settings, depth + 1)
    let index_value: TemplateEvaluation = template_evaluate(index_index, expressions, frames, context, settings, depth + 1)
    let mut diagnostics: [DataDiagnostic] = template_merge_diagnostics(object.diagnostics, index_value.diagnostics)
    match object.value {
        case ArrayValue(payload):
            match index_value.value {
                case NumberValue(number):
                    if !template_number_is_integral(number.value) {
                        return TemplateEvaluation { value: NullValue, diagnostics: diagnostics }
                    }
                    let at: i64 = template_number_as_i64(number.value)
                    if at < 0 || at as usize >= payload.items.length() {
                        return TemplateEvaluation { value: NullValue, diagnostics: diagnostics }
                    }
                    return TemplateEvaluation { value: payload.items⁅at as usize⁆.unwrap(), diagnostics: diagnostics }
                else:
                    return TemplateEvaluation { value: NullValue, diagnostics: diagnostics }
            }
        case ObjectValue(payload):
            let key: utf8 = template_stringify(index_value.value)
            let found: TemplateValue? = template_object_get(ObjectValue { fields: payload.fields }, key)
            if found.is_none() {
                return TemplateEvaluation { value: NullValue, diagnostics: diagnostics }
            }
            return TemplateEvaluation { value: found.unwrap(), diagnostics: diagnostics }
        else:
            return TemplateEvaluation { value: NullValue, diagnostics: diagnostics }
    }
}

# 调用：callee 必须是裸标识符（成员调用一律拒绝，不派发到宿主）。
micro template_evaluate_call(callee: usize, call_arguments: [usize], expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    if callee >= expressions.length() {
        return template_evaluation_failed("template.render.broken_expression", "调用目标句柄越界")
    }
    let callee_expression: TemplateExpression = expressions⁅callee⁆.unwrap()
    match callee_expression {
        case Identifier(payload):
            let mut arguments: [TemplateValue] = []
            let mut diagnostics: [DataDiagnostic] = []
            let mut index: usize = 0
            while index < call_arguments.length() {
                let evaluated: TemplateEvaluation = template_evaluate(call_arguments⁅index⁆.unwrap(), expressions, frames, context, settings, depth + 1)
                diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
                arguments = push(arguments, evaluated.value)
                index = index + 1
            }
            let result: TemplateFilterResult = template_call_function(payload.name, arguments)
            diagnostics = template_merge_diagnostics(diagnostics, result.diagnostics)
            return TemplateEvaluation { value: result.value, diagnostics: diagnostics }
        else:
            return template_evaluation_failed("template.render.member_call", "只接受裸标识符调用，成员调用一律拒绝")
    }
}

# 二元运算（合同表：无跨类型强制转换）。
micro template_evaluate_binary(operator: TemplateBinaryOperator, left: usize, right: usize, expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let left_value: TemplateEvaluation = template_evaluate(left, expressions, frames, context, settings, depth + 1)
    let right_value: TemplateEvaluation = template_evaluate(right, expressions, frames, context, settings, depth + 1)
    let diagnostics: [DataDiagnostic] = template_merge_diagnostics(left_value.diagnostics, right_value.diagnostics)
    let result: TemplateValue = template_binary_apply(operator, left_value.value, right_value.value)
    return TemplateEvaluation { value: result, diagnostics: diagnostics }
}

micro template_binary_apply(operator: TemplateBinaryOperator, left: TemplateValue, right: TemplateValue) -> TemplateValue {
    match operator {
        case OpEqual:
            return BooleanValue { value: template_values_equal(left, right) }
        case OpNotEqual:
            return BooleanValue { value: !template_values_equal(left, right) }
        case OpAnd:
            return BooleanValue { value: template_truthy(left) && template_truthy(right) }
        case OpOr:
            return BooleanValue { value: template_truthy(left) || template_truthy(right) }
        case OpIn:
            return BooleanValue { value: template_in_apply(left, right) }
        case OpAdd:
            return template_add_apply(left, right)
        case OpSubtract:
            return template_numeric_apply(left, right, 2)
        case OpMultiply:
            return template_numeric_apply(left, right, 3)
        case OpDivide:
            return template_numeric_apply(left, right, 4)
        case OpRemainder:
            return template_numeric_apply(left, right, 5)
        case OpLess:
            return template_compare_apply(left, right, 1)
        case OpLessEqual:
            return template_compare_apply(left, right, 2)
        case OpGreater:
            return template_compare_apply(left, right, 3)
        case OpGreaterEqual:
            return template_compare_apply(left, right, 4)
    }
}

# `+`：两侧都是数字才相加，否则两侧字符串化后拼接。
micro template_add_apply(left: TemplateValue, right: TemplateValue) -> TemplateValue {
    match left {
        case NumberValue(first):
            match right {
                case NumberValue(second):
                    let sum: f64 = first.value + second.value
                    let check: f64 = sum - sum
                    if check != 0.0 {
                        return NullValue
                    }
                    return NumberValue { value: sum }
                else:
                    return TextValue { value: template_stringify(left) + template_stringify(right) }
            }
        else:
            return TextValue { value: template_stringify(left) + template_stringify(right) }
    }
}

# `- * / %`：仅两侧都是数字，否则 null；结果非有限 -> null。kind: 2=减 3=乘 4=除 5=余。
micro template_numeric_apply(left: TemplateValue, right: TemplateValue, kind: usize) -> TemplateValue {
    match left {
        case NumberValue(first):
            match right {
                case NumberValue(second):
                    if kind == 2 {
                        let result: f64 = first.value - second.value
                        return template_finite_number(result)
                    }
                    if kind == 3 {
                        let result: f64 = first.value * second.value
                        return template_finite_number(result)
                    }
                    if kind == 4 {
                        if second.value == 0.0 {
                            return NullValue
                        }
                        let result: f64 = first.value / second.value
                        return template_finite_number(result)
                    }
                    # 余数：截断式（商向零取整）；除数为零或商溢出 i64 范围 -> null。
                    if second.value == 0.0 {
                        return NullValue
                    }
                    let quotient: f64 = first.value / second.value
                    let quotient_check: f64 = quotient - quotient
                    if quotient_check != 0.0 {
                        return NullValue
                    }
                    let bound: f64 = template_i64_safe_bound()
                    if quotient >= bound || quotient <= 0.0 - bound {
                        return NullValue
                    }
                    let truncated: i64 = quotient as i64
                    let remainder: f64 = first.value - second.value * (truncated as f64)
                    return template_finite_number(remainder)
                else:
                    return NullValue
            }
        else:
            return NullValue
    }
}

micro template_finite_number(value: f64) -> TemplateValue {
    let check: f64 = value - value
    if check != 0.0 {
        return NullValue
    }
    return NumberValue { value: value }
}

# 比较：仅两侧都是数字时比较，否则 false。kind: 1=< 2=<= 3=> 4=>=。
micro template_compare_apply(left: TemplateValue, right: TemplateValue, kind: usize) -> TemplateValue {
    match left {
        case NumberValue(first):
            match right {
                case NumberValue(second):
                    if kind == 1 {
                        return BooleanValue { value: first.value < second.value }
                    }
                    if kind == 2 {
                        return BooleanValue { value: first.value <= second.value }
                    }
                    if kind == 3 {
                        return BooleanValue { value: first.value > second.value }
                    }
                    return BooleanValue { value: first.value >= second.value }
                else:
                    return BooleanValue { value: false }
            }
        else:
            return BooleanValue { value: false }
    }
}

# `in`：数组成员相等；字符串为左值字符串化后的子串；对象为字符串化后的 key；其他 false。
micro template_in_apply(left: TemplateValue, right: TemplateValue) -> bool {
    match right {
        case ArrayValue(payload):
            let mut index: usize = 0
            while index < payload.items.length() {
                if template_values_equal(left, payload.items⁅index⁆.unwrap()) {
                    return true
                }
                index = index + 1
            }
            return false
        case TextValue(payload):
            return template_text_contains(payload.value, template_stringify(left))
        case SafeTextValue(payload):
            return template_text_contains(payload.value, template_stringify(left))
        case ObjectValue(payload):
            let key: utf8 = template_stringify(left)
            let mut index: usize = 0
            while index < payload.fields.length() {
                if payload.fields⁅index⁆.unwrap().name == key {
                    return true
                }
                index = index + 1
            }
            return false
        else:
            return false
    }
}

# 一元：`!` 按 truthiness 取反；`-` 仅数字；`+` 恒等。
micro template_evaluate_unary(operator: TemplateUnaryOperator, operand: usize, expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let value: TemplateEvaluation = template_evaluate(operand, expressions, frames, context, settings, depth + 1)
    match operator {
        case OpNot:
            return TemplateEvaluation { value: BooleanValue { value: !template_truthy(value.value) }, diagnostics: value.diagnostics }
        case OpIdentity:
            return value
        case OpNegate:
            match value.value {
                case NumberValue(payload):
                    return TemplateEvaluation { value: NumberValue { value: 0.0 - payload.value }, diagnostics: value.diagnostics }
                else:
                    return TemplateEvaluation { value: NullValue, diagnostics: value.diagnostics }
            }
    }
}

# 管道：依次应用过滤器；参数在每个过滤器段求值。
micro template_evaluate_pipe(pipe_expression: usize, filter: utf8, pipe_arguments: [usize], expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let source: TemplateEvaluation = template_evaluate(pipe_expression, expressions, frames, context, settings, depth + 1)
    let mut diagnostics: [DataDiagnostic] = source.diagnostics
    let mut arguments: [TemplateValue] = []
    let mut index: usize = 0
    while index < pipe_arguments.length() {
        let evaluated: TemplateEvaluation = template_evaluate(pipe_arguments⁅index⁆.unwrap(), expressions, frames, context, settings, depth + 1)
        diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
        arguments = push(arguments, evaluated.value)
        index = index + 1
    }
    let result: TemplateFilterResult = template_apply_filter(filter, source.value, arguments)
    diagnostics = template_merge_diagnostics(diagnostics, result.diagnostics)
    return TemplateEvaluation { value: result.value, diagnostics: diagnostics }
}

# 测试：`is` / `is not` 谓词；`is not` 对最终布尔值取反。
micro template_evaluate_test(test_expression: usize, name: utf8, test_arguments: [usize], negated: bool, expressions: [TemplateExpression], frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let source: TemplateEvaluation = template_evaluate(test_expression, expressions, frames, context, settings, depth + 1)
    let mut diagnostics: [DataDiagnostic] = source.diagnostics
    let mut arguments: [TemplateValue] = []
    let mut index: usize = 0
    while index < test_arguments.length() {
        let evaluated: TemplateEvaluation = template_evaluate(test_arguments⁅index⁆.unwrap(), expressions, frames, context, settings, depth + 1)
        diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
        arguments = push(arguments, evaluated.value)
        index = index + 1
    }
    let result: TemplateTestResult = template_call_test(name, source.value, arguments)
    diagnostics = template_merge_diagnostics(diagnostics, result.diagnostics)
    if negated {
        return TemplateEvaluation { value: BooleanValue { value: !result.passed }, diagnostics: diagnostics }
    }
    return TemplateEvaluation { value: BooleanValue { value: result.passed }, diagnostics: diagnostics }
}
