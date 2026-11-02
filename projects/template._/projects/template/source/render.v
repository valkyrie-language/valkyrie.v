namespace template;

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};
using std.data::{DataOutcome, data_outcome_diagnostics, data_outcome_of, data_outcome_has_errors, data_outcome_partial, data_outcome_value_or};
using std.data.text::{Binary, BlockNode, BreakNode, Call, CallNode, ContinueNode, ExpressionMissing, ExpressionPoison, ExtendsNode, Identifier, IfNode, ImportNode, IncludeNode, Index, InterpolationNode, LiteralFalse, LiteralNull, LiteralNumber, LiteralString, LiteralTrue, LoopNode, MacroNode, Member, MissingNode, ObjectLiteral, OpAdd, OpAnd, OpDivide, OpEqual, OpGreater, OpGreaterEqual, OpIdentity, OpIn, OpLess, OpLessEqual, OpMultiply, OpNegate, OpNot, OpNotEqual, OpOr, OpRemainder, OpSubtract, PartialNode, Pipe, PoisonNode, SuperNode, TemplateBinaryOperator, TemplateDocument, TemplateExpression, TemplateIfBranch, TemplateImportName, TemplateNode, TemplateObjectEntry, TemplateParameter, TemplateUnaryOperator, TextNode, Unary};

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
#
# 装配协同：extends/block/super 由装配段展开；渲染段遇到未展开形态 fail-closed
# （`template.render.unassembled_extends` / `unassembled_super` / `unassembled_import`）。
# include 按目录解析（上下文三态：继承 / with 合并 / only 独占，`without context`
# 同 only 空 with；`invalid_include_path` / `include_cycle` / `unresolved_include`），
# partial 参数化绑定（`missing_parameter` / `unknown_parameter` / `context_not_object`）；
# 宏经 `call` 语句或表达式调用（`unknown_macro` / `invalid_macro_call` /
# `caller_unavailable` / `caller_arity`）。include/macro/partial 一律 fresh 帧栈
# （`forloop.depth` 重计）。

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
    diagnostics: [Diagnostic]
}

structure TemplateEvaluation {
    value: TemplateValue
    diagnostics: [Diagnostic]
}

structure TemplateFrame {
    fields: [TemplateField]
}

# ── 渲染运行时：装配段产出，沿渲染调用按值传递 ──
# `arena` 为全目录合并后的表达式数组；`documents` 为重映射后的目录镜像；
# `include_stack` 为规范 id 栈（循环检测 + 相对引用基准）；`caller` 为
# 调用方块体栈（嵌套宏调用，栈顶为词法最近一层）。

structure TemplateRuntime {
    arena: [TemplateExpression]
    catalog: TemplateCatalog
    documents: [TemplateRuntimeDocument]
    macros: [TemplateMacroEntry]
    caller: [TemplateCallerBlock]
    include_stack: [utf8]
}

structure TemplateRuntimeDocument {
    canonical: utf8
    body: [TemplateNode]
}

structure TemplateMacroEntry {
    name: utf8
    parameters: [TemplateParameter]
    body: [TemplateNode]
}

# 调用方块体快照：`available = false` 是表达式位宏调用的占位
# （其内 `caller(...)` 产 `template.render.caller_unavailable`）。
structure TemplateCallerBlock {
    available: bool
    parameters: [utf8]
    body: [TemplateNode]
    frames: [TemplateFrame]
    context: TemplateValue
}

micro template_empty_runtime() -> TemplateRuntime {
    return TemplateRuntime {
        arena: [],
        catalog: TemplateCatalog { roots: [], entries: [] },
        documents: [],
        macros: [],
        caller: [],
        include_stack: []
    }
}

# 运行时镜像查询：规范 id -> 重映射 body；缺席给空列表。
micro template_runtime_body(documents: [TemplateRuntimeDocument], canonical: utf8) -> [TemplateNode] {
    let mut index: usize = 0
    while index < documents.length() {
        let document: TemplateRuntimeDocument = documents⁅index⁆.unwrap()
        if document.canonical == canonical {
            return document.body
        }
        index = index + 1
    }
    let empty: [TemplateNode] = []
    return empty
}

micro template_runtime_has_document(documents: [TemplateRuntimeDocument], canonical: utf8) -> bool {
    let mut index: usize = 0
    while index < documents.length() {
        if documents⁅index⁆.unwrap().canonical == canonical {
            return true
        }
        index = index + 1
    }
    return false
}

micro template_include_stack_contains(stack: [utf8], canonical: utf8) -> bool {
    let mut index: usize = 0
    while index < stack.length() {
        if stack⁅index⁆.unwrap() == canonical {
            return true
        }
        index = index + 1
    }
    return false
}

# 宏查找：同名后者优先（子模板覆盖父模板，import 覆盖本模板上文）。
micro template_find_macro(runtime: TemplateRuntime, name: utf8) -> TemplateMacroEntry? {
    let mut index: usize = runtime.macros.length()
    while index > 0 {
        index = index - 1
        let entry: TemplateMacroEntry = runtime.macros⁅index⁆.unwrap()
        if entry.name == name {
            return entry
        }
    }
    return null
}

micro template_chunk(text: utf8) -> TemplateChunk {
    return TemplateChunk { text: text, signal: SignalNone, diagnostics: [] }
}

micro template_evaluation(value: TemplateValue) -> TemplateEvaluation {
    return TemplateEvaluation { value: value, diagnostics: [] }
}

micro template_evaluation_failed(code: utf8, message: utf8) -> TemplateEvaluation {
    let mut diagnostics: [Diagnostic] = []
    diagnostics = push(diagnostics, new_diagnostic(code, Error, message, new_span(0, 0)))
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

micro template_merge_diagnostics(into: [Diagnostic], from: [Diagnostic]) -> [Diagnostic] {
    let mut result: [Diagnostic] = into
    let mut index: usize = 0
    while index < from.length() {
        result = push(result, from⁅index⁆.unwrap())
        index = index + 1
    }
    return result
}

# ── 入口 ──

# 单文档入口：无目录装配（宏表取文档顶层；extends/include/import 由
# 装配段或渲染段 fail-closed 诊断）。
micro template_render(document: TemplateDocument, context: TemplateValue, settings: TemplateRenderSettings) -> DataOutcome<utf8> {
    let assembled: DataOutcome<TemplateAssembly> = template_assemble_single(document)
    let assembly: TemplateAssembly = data_outcome_value_or(assembled, template_empty_assembly())
    let frames: [TemplateFrame] = []
    let chunk: TemplateChunk = template_render_nodes(assembly.body, assembly.runtime, frames, context, settings, 1)
    let diagnostics: [Diagnostic] = template_merge_diagnostics(data_outcome_diagnostics(assembled), chunk.diagnostics)
    return data_outcome_partial(chunk.text, diagnostics)
}

# 目录入口：root + path 指定入口模板，继承链/include/import 经装配段展开。
micro template_render_catalog(root: utf8, path: utf8, catalog: TemplateCatalog, context: TemplateValue, settings: TemplateRenderSettings) -> DataOutcome<utf8> {
    let assembled: DataOutcome<TemplateAssembly> = template_assemble(root, path, catalog)
    let assembly: TemplateAssembly = data_outcome_value_or(assembled, template_empty_assembly())
    let frames: [TemplateFrame] = []
    let chunk: TemplateChunk = template_render_nodes(assembly.body, assembly.runtime, frames, context, settings, 1)
    let diagnostics: [Diagnostic] = template_merge_diagnostics(data_outcome_diagnostics(assembled), chunk.diagnostics)
    return data_outcome_partial(chunk.text, diagnostics)
}

micro template_empty_assembly() -> TemplateAssembly {
    return TemplateAssembly { body: [], runtime: template_empty_runtime() }
}

# 注：source -> render 的端到端链由消费方按方言组装（解析归 std.data.text.<dialect>），
# 本包提供 `template_render`（单文档）与 `template_render_catalog`（目录）。

# ── 语句渲染 ──

micro template_render_nodes(nodes: [TemplateNode], runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    if depth > settings.max_depth {
        let mut diagnostics: [Diagnostic] = []
        diagnostics = push(diagnostics, new_diagnostic("template.render.max_depth_exceeded", Error, "渲染嵌套深度超限", new_span(0, 0)))
        return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
    }
    let mut text: utf8 = ""
    let mut signal: TemplateSignal = SignalNone
    let mut diagnostics: [Diagnostic] = []
    let mut index: usize = 0
    while index < nodes.length() {
        let node: TemplateNode = nodes⁅index⁆.unwrap()
        match node {
            case TextNode(payload):
                text = text + payload.text
            case InterpolationNode(payload):
                let evaluated: TemplateEvaluation = template_evaluate(payload.expression, runtime, frames, context, settings, depth + 1)
                diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
                let output: TemplateChunk = template_interpolation_output(evaluated.value)
                text = text + output.text
                diagnostics = template_merge_diagnostics(diagnostics, output.diagnostics)
            case IfNode(payload):
                let branch: TemplateChunk = template_render_if(payload.branches, payload.alternate, runtime, frames, context, settings, depth)
                text = text + branch.text
                diagnostics = template_merge_diagnostics(diagnostics, branch.diagnostics)
            case LoopNode(payload):
                let looped: TemplateChunk = template_render_loop(payload.item, payload.iterable, payload.body, runtime, frames, context, settings, depth)
                text = text + looped.text
                diagnostics = template_merge_diagnostics(diagnostics, looped.diagnostics)
            case BreakNode:
                signal = SignalBreak
                index = nodes.length()
            case ContinueNode:
                signal = SignalContinue
                index = nodes.length()
            case ExtendsNode(payload):
                diagnostics = push(diagnostics, new_diagnostic("template.render.unassembled_extends", Error, "extends 未经装配展开", new_span(0, 0)))
            case BlockNode(payload):
                let blocked: TemplateChunk = template_render_nodes(payload.body, runtime, frames, context, settings, depth + 1)
                text = text + blocked.text
                diagnostics = template_merge_diagnostics(diagnostics, blocked.diagnostics)
            case SuperNode:
                diagnostics = push(diagnostics, new_diagnostic("template.render.unassembled_super", Error, "super 未经装配展开", new_span(0, 0)))
            case IncludeNode(payload):
                let included: TemplateChunk = template_render_include(payload.path, payload.with_expression, payload.only, runtime, frames, context, settings, depth)
                text = text + included.text
                diagnostics = template_merge_diagnostics(diagnostics, included.diagnostics)
            case PartialNode(payload):
                let partial: TemplateChunk = template_render_partial(payload.parameters, payload.body, context, runtime, settings, depth)
                text = text + partial.text
                diagnostics = template_merge_diagnostics(diagnostics, partial.diagnostics)
            case MacroNode(payload): {
                # 宏定义位：不产生输出（装配段已登记入宏表）。
            }
            case CallNode(payload):
                let called: TemplateChunk = template_render_call(payload.callee, payload.caller_parameters, payload.body, runtime, frames, context, settings, depth)
                text = text + called.text
                diagnostics = template_merge_diagnostics(diagnostics, called.diagnostics)
            case ImportNode(payload):
                diagnostics = push(diagnostics, new_diagnostic("template.render.unassembled_import", Error, "import 未经装配登记", new_span(0, 0)))
            case MissingNode(payload):
                diagnostics = push(diagnostics, new_diagnostic("template.render.broken_node", Error, "渲染遇到缺席占位节点", new_span(0, 0)))
            case PoisonNode(payload):
                diagnostics = push(diagnostics, new_diagnostic("template.render.broken_node", Error, "渲染遇到污染节点", new_span(0, 0)))
            else: {
                # CommentNode：注释不进入渲染输出。
            }
        }
        index = index + 1
    }
    return TemplateChunk { text: text, signal: signal, diagnostics: diagnostics }
}

# if：依序求值分支条件，首个 truthy 分支渲染；都不中渲染 alternate。
micro template_render_if(branches: [TemplateIfBranch], alternate: [TemplateNode], runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    let mut diagnostics: [Diagnostic] = []
    let mut index: usize = 0
    while index < branches.length() {
        let branch: TemplateIfBranch = branches⁅index⁆.unwrap()
        let tested: TemplateEvaluation = template_evaluate(branch.test, runtime, frames, context, settings, depth + 1)
        diagnostics = template_merge_diagnostics(diagnostics, tested.diagnostics)
        if template_truthy(tested.value) {
            let chunk: TemplateChunk = template_render_nodes(branch.body, runtime, frames, context, settings, depth + 1)
            return TemplateChunk { text: chunk.text, signal: chunk.signal, diagnostics: template_merge_diagnostics(diagnostics, chunk.diagnostics) }
        }
        index = index + 1
    }
    let fallback: TemplateChunk = template_render_nodes(alternate, runtime, frames, context, settings, depth + 1)
    return TemplateChunk { text: fallback.text, signal: fallback.signal, diagnostics: template_merge_diagnostics(diagnostics, fallback.diagnostics) }
}

# loop：iterable 必须是数组（否则 `template.render.invalid_iterable`）。
# 每次迭代压入一帧：循环变量 + `forloop`（index/index0/first/last/length/depth）。
# break 终止循环并继续后续内容；continue 跳过当前迭代剩余 body。
micro template_render_loop(item: utf8, iterable: usize, body: [TemplateNode], runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    let mut diagnostics: [Diagnostic] = []
    let evaluated: TemplateEvaluation = template_evaluate(iterable, runtime, frames, context, settings, depth + 1)
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
                let chunk: TemplateChunk = template_render_nodes(body, runtime, iteration_frames, context, settings, depth + 1)
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
            diagnostics = push(diagnostics, new_diagnostic("template.render.invalid_iterable", Error, "loop 的 iterable 必须是数组", new_span(0, 0)))
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

# ── include / partial / 宏 ──

# include：路径求值为文本后按目录解析；上下文三态（继承 / with 合并 / only 独占，
# `without context` 同 only 空 with）。目标为单顶层 PartialNode 时按 partial
# 规则绑定。循环经 `template.render.include_cycle` fail-closed。
micro template_render_include(path: usize, with_expression: usize?, only: bool, runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    let mut diagnostics: [Diagnostic] = []
    let evaluated: TemplateEvaluation = template_evaluate(path, runtime, frames, context, settings, depth + 1)
    diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
    let mut reference: utf8 = ""
    let mut reference_ok: bool = false
    match evaluated.value {
        case TextValue(payload): {
            reference = payload.value
            reference_ok = true
        }
        case SafeTextValue(payload): {
            reference = payload.value
            reference_ok = true
        }
        else: {
            diagnostics = push(diagnostics, new_diagnostic("template.render.invalid_include_path", Error, "include 路径必须求值为文本", new_span(0, 0)))
        }
    }
    if !reference_ok {
        return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
    }
    # with 求值与上下文合成。
    let mut has_with: bool = false
    let mut with_object: TemplateValue = NullValue
    if with_expression.is_some() {
        let with_eval: TemplateEvaluation = template_evaluate(with_expression.unwrap(), runtime, frames, context, settings, depth + 1)
        diagnostics = template_merge_diagnostics(diagnostics, with_eval.diagnostics)
        has_with = true
        with_object = with_eval.value
    }
    let mut include_context: TemplateValue = context
    if has_with {
        match with_object {
            case ObjectValue(payload): {
                if only {
                    include_context = with_object
                }
                else {
                    include_context = template_merge_context(context, with_object)
                }
            }
            case NullValue: {
                if only {
                    include_context = ObjectValue { fields: [] }
                }
            }
            else: {
                diagnostics = push(diagnostics, new_diagnostic("template.render.context_not_object", Error, "include 的 with 必须是对象或 null", new_span(0, 0)))
                if only {
                    include_context = ObjectValue { fields: [] }
                }
            }
        }
    }
    else {
        if only {
            include_context = ObjectValue { fields: [] }
        }
    }
    let mut from: utf8 = ""
    if runtime.include_stack.length() > 0 {
        from = runtime.include_stack⁅runtime.include_stack.length() - 1⁆.unwrap()
    }
    let resolved: DataOutcome<TemplateResolution> = template_resolve(reference, from, runtime.catalog)
    if data_outcome_has_errors(resolved) {
        diagnostics = template_merge_diagnostics(diagnostics, data_outcome_diagnostics(resolved))
        return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
    }
    let fallback_resolution: TemplateResolution = TemplateResolution { canonical: "", entry: 0 }
    let target: TemplateResolution = data_outcome_value_or(resolved, fallback_resolution)
    if template_include_stack_contains(runtime.include_stack, target.canonical) {
        diagnostics = push(diagnostics, new_diagnostic("template.render.include_cycle", Error, "include 存在循环", new_span(0, 0)))
        return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
    }
    if !template_runtime_has_document(runtime.documents, target.canonical) {
        diagnostics = push(diagnostics, new_diagnostic("template.render.unresolved_include", Error, "include 目标未经装配入运行时", new_span(0, 0)))
        return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
    }
    let inner_runtime: TemplateRuntime = TemplateRuntime {
        arena: runtime.arena,
        catalog: runtime.catalog,
        documents: runtime.documents,
        macros: runtime.macros,
        caller: runtime.caller,
        include_stack: push(runtime.include_stack, target.canonical)
    }
    let target_body: [TemplateNode] = template_runtime_body(runtime.documents, target.canonical)
    # partial 目标：单顶层 PartialNode 时按 partial 规则绑定（上下文不继承）。
    if target_body.length() == 1 {
        let only_node: TemplateNode = target_body⁅0⁆.unwrap()
        match only_node {
            case PartialNode(payload): {
                let mut source: TemplateValue = NullValue
                if has_with {
                    source = with_object
                }
                let bound: TemplateChunk = template_partial_chunk(payload.parameters, payload.body, source, true, inner_runtime, settings, depth + 1)
                return TemplateChunk { text: bound.text, signal: SignalNone, diagnostics: template_merge_diagnostics(diagnostics, bound.diagnostics) }
            }
            else: {
                # 非 partial 目标走常规范渲染。
            }
        }
    }
    let fresh_frames: [TemplateFrame] = []
    let chunk: TemplateChunk = template_render_nodes(target_body, inner_runtime, fresh_frames, include_context, settings, depth + 1)
    return TemplateChunk { text: chunk.text, signal: SignalNone, diagnostics: template_merge_diagnostics(diagnostics, chunk.diagnostics) }
}

# with 合并：基底对象字段（未被覆盖者）在前，with 字段在后。
micro template_merge_context(base: TemplateValue, overlay: TemplateValue) -> TemplateValue {
    match overlay {
        case ObjectValue(overlay_payload): {
            let mut fields: [TemplateField] = []
            match base {
                case ObjectValue(base_payload): {
                    let mut index: usize = 0
                    while index < base_payload.fields.length() {
                        let field: TemplateField = base_payload.fields⁅index⁆.unwrap()
                        if !template_object_has(overlay_payload.fields, field.name) {
                            fields = push(fields, field)
                        }
                        index = index + 1
                    }
                }
                else: {
                    # 非对象基底不参与合并。
                }
            }
            let mut overlay_index: usize = 0
            while overlay_index < overlay_payload.fields.length() {
                fields = push(fields, overlay_payload.fields⁅overlay_index⁆.unwrap())
                overlay_index = overlay_index + 1
            }
            return ObjectValue { fields: fields }
        }
        else:
            return overlay
    }
}

micro template_object_has(fields: [TemplateField], name: utf8) -> bool {
    let mut index: usize = 0
    while index < fields.length() {
        if fields⁅index⁆.unwrap().name == name {
            return true
        }
        index = index + 1
    }
    return false
}

# 直接渲染的 partial：根上下文即绑定源（必须对象或 null）；直接渲染不做
# 未知键检查（根上下文键远多于参数是常态）。
micro template_render_partial(parameters: [TemplateParameter], body: [TemplateNode], context: TemplateValue, runtime: TemplateRuntime, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    return template_partial_chunk(parameters, body, context, false, runtime, settings, depth)
}

# partial 绑定：源对象按键绑定参数（缺席用默认值字面量，再缺席产
# `template.render.missing_parameter`；strict_keys 时未知键产
# `template.render.unknown_parameter`；源非对象/null 产
# `template.render.context_not_object`）。fresh 帧 + 空上下文。
micro template_partial_chunk(parameters: [TemplateParameter], body: [TemplateNode], source: TemplateValue, strict_keys: bool, runtime: TemplateRuntime, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    let mut diagnostics: [Diagnostic] = []
    match source {
        case ObjectValue(payload): {
            let mut fields: [TemplateField] = []
            let mut index: usize = 0
            while index < parameters.length() {
                let parameter: TemplateParameter = parameters⁅index⁆.unwrap()
                let found: TemplateValue? = template_object_get(source, parameter.name)
                if found.is_some() {
                    fields = push(fields, template_field(parameter.name, found.unwrap()))
                }
                else {
                    if parameter.default.is_some() {
                        let empty_frames: [TemplateFrame] = []
                        let defaulted: TemplateEvaluation = template_evaluate(parameter.default.unwrap(), runtime, empty_frames, NullValue, settings, depth + 1)
                        diagnostics = template_merge_diagnostics(diagnostics, defaulted.diagnostics)
                        fields = push(fields, template_field(parameter.name, defaulted.value))
                    }
                    else {
                        diagnostics = push(diagnostics, new_diagnostic("template.render.missing_parameter", Error, "partial 缺少参数: " + parameter.name, new_span(0, 0)))
                        fields = push(fields, template_field(parameter.name, NullValue))
                    }
                }
                index = index + 1
            }
            if strict_keys {
                let mut field_index: usize = 0
                while field_index < payload.fields.length() {
                    let field: TemplateField = payload.fields⁅field_index⁆.unwrap()
                    if !template_parameters_have(parameters, field.name) {
                        diagnostics = push(diagnostics, new_diagnostic("template.render.unknown_parameter", Error, "partial 不接受参数: " + field.name, new_span(0, 0)))
                    }
                    field_index = field_index + 1
                }
            }
            let frame: TemplateFrame = TemplateFrame { fields: fields }
            let fresh_frames: [TemplateFrame] = [frame]
            let chunk: TemplateChunk = template_render_nodes(body, runtime, fresh_frames, ObjectValue { fields: [] }, settings, depth + 1)
            return TemplateChunk { text: chunk.text, signal: chunk.signal, diagnostics: template_merge_diagnostics(diagnostics, chunk.diagnostics) }
        }
        case NullValue: {
            return template_partial_chunk(parameters, body, ObjectValue { fields: [] }, strict_keys, runtime, settings, depth)
        }
        else:
            diagnostics = push(diagnostics, new_diagnostic("template.render.context_not_object", Error, "partial 绑定源必须是对象或 null", new_span(0, 0)))
            return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
    }
}

micro template_parameters_have(parameters: [TemplateParameter], name: utf8) -> bool {
    let mut index: usize = 0
    while index < parameters.length() {
        if parameters⁅index⁆.unwrap().name == name {
            return true
        }
        index = index + 1
    }
    return false
}

# call：callee 必须是 `name(args)` 形（否则 `template.render.invalid_macro_call`）；
# 宏查找失败产 `template.render.unknown_macro`；caller 块快照入栈后渲染宏体。
micro template_render_call(callee: usize, caller_parameters: [utf8], body: [TemplateNode], runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    let mut diagnostics: [Diagnostic] = []
    if callee >= runtime.arena.length() {
        diagnostics = push(diagnostics, new_diagnostic("template.render.broken_expression", Error, "调用目标句柄越界", new_span(0, 0)))
        return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
    }
    let callee_expression: TemplateExpression = runtime.arena⁅callee⁆.unwrap()
    match callee_expression {
        case Call(call): {
            if call.callee >= runtime.arena.length() {
                diagnostics = push(diagnostics, new_diagnostic("template.render.broken_expression", Error, "调用目标句柄越界", new_span(0, 0)))
                return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
            }
            let name_expression: TemplateExpression = runtime.arena⁅call.callee⁆.unwrap()
            match name_expression {
                case Identifier(identifier): {
                    let mut arguments: [TemplateValue] = []
                    let mut index: usize = 0
                    while index < call.arguments.length() {
                        let evaluated: TemplateEvaluation = template_evaluate(call.arguments⁅index⁆.unwrap(), runtime, frames, context, settings, depth + 1)
                        diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
                        arguments = push(arguments, evaluated.value)
                        index = index + 1
                    }
                    let macro_entry: TemplateMacroEntry? = template_find_macro(runtime, identifier.name)
                    if macro_entry.is_none() {
                        diagnostics = push(diagnostics, new_diagnostic("template.render.unknown_macro", Error, "未定义的宏: " + identifier.name, new_span(0, 0)))
                        return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
                    }
                    let caller_block: TemplateCallerBlock = TemplateCallerBlock { available: true, parameters: caller_parameters, body: body, frames: frames, context: context }
                    let invoked: TemplateChunk = template_invoke_macro(macro_entry.unwrap(), arguments, caller_block, runtime, context, settings, depth)
                    return TemplateChunk { text: invoked.text, signal: SignalNone, diagnostics: template_merge_diagnostics(diagnostics, invoked.diagnostics) }
                }
                else: {
                    diagnostics = push(diagnostics, new_diagnostic("template.render.invalid_macro_call", Error, "call 目标必须是 `name(args)` 形的宏调用", new_span(0, 0)))
                    return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
                }
            }
        }
        else: {
            diagnostics = push(diagnostics, new_diagnostic("template.render.invalid_macro_call", Error, "call 目标必须是 `name(args)` 形的宏调用", new_span(0, 0)))
            return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
        }
    }
}

# 宏调用：参数绑定（实参 -> 默认值 -> missing_parameter），caller 块入栈，
# fresh 帧栈渲染宏体（`forloop.depth` 随 fresh 帧重计）。
micro template_invoke_macro(macro_entry: TemplateMacroEntry, arguments: [TemplateValue], caller_block: TemplateCallerBlock, runtime: TemplateRuntime, context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateChunk {
    let mut diagnostics: [Diagnostic] = []
    let mut fields: [TemplateField] = []
    let mut index: usize = 0
    while index < macro_entry.parameters.length() {
        let parameter: TemplateParameter = macro_entry.parameters⁅index⁆.unwrap()
        if index < arguments.length() {
            fields = push(fields, template_field(parameter.name, arguments⁅index⁆.unwrap()))
        }
        else {
            if parameter.default.is_some() {
                let empty_frames: [TemplateFrame] = []
                let defaulted: TemplateEvaluation = template_evaluate(parameter.default.unwrap(), runtime, empty_frames, NullValue, settings, depth + 1)
                diagnostics = template_merge_diagnostics(diagnostics, defaulted.diagnostics)
                fields = push(fields, template_field(parameter.name, defaulted.value))
            }
            else {
                diagnostics = push(diagnostics, new_diagnostic("template.render.missing_parameter", Error, "宏缺少实参: " + parameter.name, new_span(0, 0)))
                fields = push(fields, template_field(parameter.name, NullValue))
            }
        }
        index = index + 1
    }
    if arguments.length() > macro_entry.parameters.length() {
        diagnostics = push(diagnostics, new_diagnostic("template.render.unknown_parameter", Error, "宏实参多于参数", new_span(0, 0)))
    }
    let frame: TemplateFrame = TemplateFrame { fields: fields }
    let inner_runtime: TemplateRuntime = TemplateRuntime {
        arena: runtime.arena,
        catalog: runtime.catalog,
        documents: runtime.documents,
        macros: runtime.macros,
        caller: push(runtime.caller, caller_block),
        include_stack: runtime.include_stack
    }
    let fresh_frames: [TemplateFrame] = [frame]
    let chunk: TemplateChunk = template_render_nodes(macro_entry.body, inner_runtime, fresh_frames, context, settings, depth + 1)
    return TemplateChunk { text: chunk.text, signal: chunk.signal, diagnostics: template_merge_diagnostics(diagnostics, chunk.diagnostics) }
}

# `caller(...)`：调用点块体在其词法作用域快照内渲染，caller 参数逐个绑定。
micro template_evaluate_caller(call_arguments: [usize], runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    if runtime.caller.length() == 0 {
        return template_evaluation_failed("template.render.caller_unavailable", "`caller` 只在带块宏调用内可用")
    }
    let block: TemplateCallerBlock = runtime.caller⁅runtime.caller.length() - 1⁆.unwrap()
    if !block.available {
        return template_evaluation_failed("template.render.caller_unavailable", "`caller` 只在带块宏调用内可用")
    }
    if call_arguments.length() != block.parameters.length() {
        return template_evaluation_failed("template.render.caller_arity", "`caller` 实参与 caller 参数数量不符")
    }
    let mut diagnostics: [Diagnostic] = []
    let mut fields: [TemplateField] = []
    let mut index: usize = 0
    while index < call_arguments.length() {
        let evaluated: TemplateEvaluation = template_evaluate(call_arguments⁅index⁆.unwrap(), runtime, frames, context, settings, depth + 1)
        diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
        fields = push(fields, template_field(block.parameters⁅index⁆.unwrap(), evaluated.value))
        index = index + 1
    }
    let frame: TemplateFrame = TemplateFrame { fields: fields }
    let chunk: TemplateChunk = template_render_nodes(block.body, runtime, push(block.frames, frame), block.context, settings, depth + 1)
    return TemplateEvaluation { value: SafeTextValue { value: chunk.text }, diagnostics: template_merge_diagnostics(diagnostics, chunk.diagnostics) }
}

# 插值出口：SafeTextValue 原文输出；其余字符串化后 HTML 转义。
# 非整数数字的字符串化当前未支持：产 `template.render.number_fraction`（Error）。
micro template_interpolation_output(value: TemplateValue) -> TemplateChunk {
    match value {
        case SafeTextValue(payload):
            return template_chunk(payload.value)
        case NumberValue(payload):
            let rendered: utf8? = template_number_to_text_option(payload.value)
            if rendered.is_none() {
                let mut diagnostics: [Diagnostic] = []
                diagnostics = push(diagnostics, new_diagnostic("template.render.number_fraction", Error, "非整数/非有限数字的字符串化当前未支持", new_span(0, 0)))
                return TemplateChunk { text: "", signal: SignalNone, diagnostics: diagnostics }
            }
            return template_chunk(template_escape_html(rendered.unwrap()))
        else:
            return template_chunk(template_escape_html(template_stringify(value)))
    }
}

# ── 表达式求值 ──

micro template_evaluate(index: usize, runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    if depth > settings.max_depth {
        return template_evaluation_failed("template.render.max_depth_exceeded", "表达式求值深度超限")
    }
    if index >= runtime.arena.length() {
        return template_evaluation_failed("template.render.broken_expression", "表达式句柄越界")
    }
    let expression: TemplateExpression = runtime.arena⁅index⁆.unwrap()
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
            let mut diagnostics: [Diagnostic] = []
            let mut entry_index: usize = 0
            while entry_index < payload.entries.length() {
                let entry: TemplateObjectEntry = payload.entries⁅entry_index⁆.unwrap()
                let evaluated: TemplateEvaluation = template_evaluate(entry.value, runtime, frames, context, settings, depth + 1)
                diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
                fields = push(fields, template_field(entry.key, evaluated.value))
                entry_index = entry_index + 1
            }
            return TemplateEvaluation { value: ObjectValue { fields: fields }, diagnostics: diagnostics }
        case Member(payload):
            let object: TemplateEvaluation = template_evaluate(payload.object, runtime, frames, context, settings, depth + 1)
            let found: TemplateValue? = template_object_get(object.value, payload.property)
            if found.is_none() {
                return TemplateEvaluation { value: NullValue, diagnostics: object.diagnostics }
            }
            return TemplateEvaluation { value: found.unwrap(), diagnostics: object.diagnostics }
        case Index(payload):
            return template_evaluate_index(payload.object, payload.index, runtime, frames, context, settings, depth)
        case Call(payload):
            return template_evaluate_call(payload.callee, payload.arguments, runtime, frames, context, settings, depth)
        case Binary(payload):
            return template_evaluate_binary(payload.operator, payload.left, payload.right, runtime, frames, context, settings, depth)
        case Unary(payload):
            return template_evaluate_unary(payload.operator, payload.operand, runtime, frames, context, settings, depth)
        case Pipe(payload):
            return template_evaluate_pipe(payload.expression, payload.filter, payload.arguments, runtime, frames, context, settings, depth)
        case Test(payload):
            return template_evaluate_test(payload.expression, payload.name, payload.arguments, payload.negated, runtime, frames, context, settings, depth)
        case ExpressionMissing(payload):
            return template_evaluation_failed("template.render.broken_expression", "求值遇到缺席占位表达式")
        case ExpressionPoison(payload):
            return template_evaluation_failed("template.render.broken_expression", "求值遇到污染表达式")
    }
}

# 下标：数组按整数下标（越界/非整数 -> 缺失）；对象按字符串化键；其余 -> 缺失。
micro template_evaluate_index(object_index: usize, index_index: usize, runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let object: TemplateEvaluation = template_evaluate(object_index, runtime, frames, context, settings, depth + 1)
    let index_value: TemplateEvaluation = template_evaluate(index_index, runtime, frames, context, settings, depth + 1)
    let mut diagnostics: [Diagnostic] = template_merge_diagnostics(object.diagnostics, index_value.diagnostics)
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
# 分派顺序：`caller` 块 -> 宏表 -> 内建函数表。表达式位宏调用压入不可用
# caller 占位（其内 `caller(...)` 产 caller_unavailable）；宏返回 SafeTextValue。
micro template_evaluate_call(callee: usize, call_arguments: [usize], runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    if callee >= runtime.arena.length() {
        return template_evaluation_failed("template.render.broken_expression", "调用目标句柄越界")
    }
    let callee_expression: TemplateExpression = runtime.arena⁅callee⁆.unwrap()
    match callee_expression {
        case Identifier(payload):
            if payload.name == "caller" {
                return template_evaluate_caller(call_arguments, runtime, frames, context, settings, depth)
            }
            let mut arguments: [TemplateValue] = []
            let mut diagnostics: [Diagnostic] = []
            let mut index: usize = 0
            while index < call_arguments.length() {
                let evaluated: TemplateEvaluation = template_evaluate(call_arguments⁅index⁆.unwrap(), runtime, frames, context, settings, depth + 1)
                diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
                arguments = push(arguments, evaluated.value)
                index = index + 1
            }
            let macro_entry: TemplateMacroEntry? = template_find_macro(runtime, payload.name)
            if macro_entry.is_some() {
                let empty_frames: [TemplateFrame] = []
                let caller_block: TemplateCallerBlock = TemplateCallerBlock { available: false, parameters: [], body: [], frames: empty_frames, context: NullValue }
                let invoked: TemplateChunk = template_invoke_macro(macro_entry.unwrap(), arguments, caller_block, runtime, context, settings, depth)
                return TemplateEvaluation { value: SafeTextValue { value: invoked.text }, diagnostics: template_merge_diagnostics(diagnostics, invoked.diagnostics) }
            }
            let result: TemplateFilterResult = template_call_function(payload.name, arguments)
            diagnostics = template_merge_diagnostics(diagnostics, result.diagnostics)
            return TemplateEvaluation { value: result.value, diagnostics: diagnostics }
        else:
            return template_evaluation_failed("template.render.member_call", "只接受裸标识符调用，成员调用一律拒绝")
    }
}

# 二元运算（合同表：无跨类型强制转换）。
micro template_evaluate_binary(operator: TemplateBinaryOperator, left: usize, right: usize, runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let left_value: TemplateEvaluation = template_evaluate(left, runtime, frames, context, settings, depth + 1)
    let right_value: TemplateEvaluation = template_evaluate(right, runtime, frames, context, settings, depth + 1)
    let diagnostics: [Diagnostic] = template_merge_diagnostics(left_value.diagnostics, right_value.diagnostics)
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
micro template_evaluate_unary(operator: TemplateUnaryOperator, operand: usize, runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let value: TemplateEvaluation = template_evaluate(operand, runtime, frames, context, settings, depth + 1)
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
micro template_evaluate_pipe(pipe_expression: usize, filter: utf8, pipe_arguments: [usize], runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let source: TemplateEvaluation = template_evaluate(pipe_expression, runtime, frames, context, settings, depth + 1)
    let mut diagnostics: [Diagnostic] = source.diagnostics
    let mut arguments: [TemplateValue] = []
    let mut index: usize = 0
    while index < pipe_arguments.length() {
        let evaluated: TemplateEvaluation = template_evaluate(pipe_arguments⁅index⁆.unwrap(), runtime, frames, context, settings, depth + 1)
        diagnostics = template_merge_diagnostics(diagnostics, evaluated.diagnostics)
        arguments = push(arguments, evaluated.value)
        index = index + 1
    }
    let result: TemplateFilterResult = template_apply_filter(filter, source.value, arguments)
    diagnostics = template_merge_diagnostics(diagnostics, result.diagnostics)
    return TemplateEvaluation { value: result.value, diagnostics: diagnostics }
}

# 测试：`is` / `is not` 谓词；`is not` 对最终布尔值取反。
micro template_evaluate_test(test_expression: usize, name: utf8, test_arguments: [usize], negated: bool, runtime: TemplateRuntime, frames: [TemplateFrame], context: TemplateValue, settings: TemplateRenderSettings, depth: usize) -> TemplateEvaluation {
    let source: TemplateEvaluation = template_evaluate(test_expression, runtime, frames, context, settings, depth + 1)
    let mut diagnostics: [Diagnostic] = source.diagnostics
    let mut arguments: [TemplateValue] = []
    let mut index: usize = 0
    while index < test_arguments.length() {
        let evaluated: TemplateEvaluation = template_evaluate(test_arguments⁅index⁆.unwrap(), runtime, frames, context, settings, depth + 1)
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
