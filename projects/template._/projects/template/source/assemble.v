namespace template;

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};
using std.data::{DataOutcome, data_outcome_diagnostics, data_outcome_failed, data_outcome_has_errors, data_outcome_of, data_outcome_partial, data_outcome_value_or};
using std.data.text::{Binary, BlockNode, BreakNode, Call, CallNode, CommentNode, ContinueNode, ExpressionMissing, ExpressionPoison, ExtendsNode, Identifier, IfNode, ImportNode, IncludeNode, Index, InterpolationNode, LiteralFalse, LiteralNull, LiteralNumber, LiteralString, LiteralTrue, LoopNode, MacroNode, Member, MissingNode, ObjectLiteral, PartialNode, Pipe, PoisonNode, SuperNode, TemplateDocument, TemplateExpression, TemplateIfBranch, TemplateImportName, TemplateNode, TemplateObjectEntry, TemplateParameter, Test, TextNode, Unary};

# 装配段：目录 + 入口 -> 单文档（继承链展开）+ 渲染运行时。
#
# 合并 arena：所有目录条目的表达式数组并入单一 arena，节点内的表达式句柄
# 按条目偏移逐一重映射；渲染段只面对这一个 arena，跨模板句柄始终有效。
#
# 继承链：入口文档的首个顶层 `extends` 决定父模板（路径必须是字符串字面量，
# 否则 `template.assemble.extends_not_literal`）；链上同名 block 逐版本覆盖，
# 最终 body 取最祖文档、block 替换为最新版本并展开 `super`（版本 0 的 super 产
# `template.assemble.super_without_parent`）。链循环产 `template.assemble.extends_cycle`。
# 子模板非 block 的顶层内容不进入最终 body（宏定义仍登记）。
#
# 宏表：整条链的顶层 `macro` 与 `from`/`import` 目标文档的顶层 `macro` 登记入表
# （同名后者优先；import 路径必须是字符串字面量，否则
# `template.assemble.import_not_literal`；目标无此宏产
# `template.assemble.unknown_import`）。顶层 ImportNode 处理后不进入最终 body。

# 装配产出：展开后的 body + 渲染运行时。
structure TemplateAssembly {
    body: [TemplateNode]
    runtime: TemplateRuntime
}

# 同名 block 的版本序列（最祖 -> 最新）。
structure TemplateBlockVersions {
    name: utf8
    bodies: [[TemplateNode]]
}

# super 展开产出。
structure TemplateExpansion {
    body: [TemplateNode]
    diagnostics: [Diagnostic]
}

# 继承链单步探测产出。
structure TemplateChainStep {
    found: bool
    stop: bool
    canonical: utf8
    diagnostics: [Diagnostic]
}

# 宏收集产出。
structure TemplateMacroCollection {
    macros: [TemplateMacroEntry]
    diagnostics: [Diagnostic]
}

# ── 源装配 ──

micro template_assemble(root: utf8, path: utf8, catalog: TemplateCatalog) -> DataOutcome<TemplateAssembly> {
    let mut diagnostics: [Diagnostic] = []
    # 1. 源镜像：全条目并入单一 arena（逐条目偏移重映射；条目枚举经 source.v 窄接口）。
    let source_entries: [TemplateCatalogEntry] = template_source_entries(catalog)
    let mut arena: [TemplateExpression] = []
    let mut documents: [TemplateRuntimeDocument] = []
    let mut index: usize = 0
    while index < source_entries.length() {
        let entry: TemplateCatalogEntry = source_entries⁅index⁆.unwrap()
        let remapped: TemplateDocument = template_remap_document(entry.document, arena.length())
        let mut merge: usize = 0
        while merge < remapped.expressions.length() {
            arena = push(arena, remapped.expressions⁅merge⁆.unwrap())
            merge = merge + 1
        }
        documents = push(documents, TemplateRuntimeDocument { canonical: entry.root + ":" + entry.path, body: remapped.body })
        index = index + 1
    }
    # 2. 入口解析（scheme 形式精确命中）。
    let resolved: DataOutcome<TemplateResolution> = template_resolve(root + ":" + path, "", catalog)
    if data_outcome_has_errors(resolved) {
        return data_outcome_failed(data_outcome_diagnostics(resolved))
    }
    let fallback_resolution: TemplateResolution = TemplateResolution { canonical: "", entry: 0 }
    let entry_canonical: utf8 = data_outcome_value_or(resolved, fallback_resolution).canonical
    # 3. 继承链（entry -> 最祖）。
    let mut chain: [utf8] = [entry_canonical]
    let mut walking: bool = true
    while walking {
        let current: utf8 = chain⁅chain.length() - 1⁆.unwrap()
        let step: TemplateChainStep = template_extends_target(current, documents, arena, catalog)
        diagnostics = template_merge_diagnostics(diagnostics, step.diagnostics)
        if !step.found || step.stop {
            walking = false
        }
        else {
            if template_chain_contains(chain, step.canonical) {
                diagnostics = push(diagnostics, new_diagnostic("template.assemble.extends_cycle", Error, "模板继承链存在循环", new_span(0, 0)))
                walking = false
            }
            else {
                chain = push(chain, step.canonical)
            }
        }
    }
    # 4. 同名 block 版本序列（最祖 -> 最新）。
    let mut versions: [TemplateBlockVersions] = []
    let mut at: usize = chain.length()
    while at > 0 {
        at = at - 1
        let chain_body: [TemplateNode] = template_runtime_body(documents, chain⁅at⁆.unwrap())
        let mut scan: usize = 0
        while scan < chain_body.length() {
            let chain_node: TemplateNode = chain_body⁅scan⁆.unwrap()
            match chain_node {
                case BlockNode(payload): {
                    versions = template_block_versions_push(versions, payload.name, payload.body)
                }
                else: {
                    # 非 block 节点不进版本表。
                }
            }
            scan = scan + 1
        }
    }
    # 5. 宏表（最祖 -> 最新；同名后者优先）。
    let mut macros: [TemplateMacroEntry] = []
    at = chain.length()
    while at > 0 {
        at = at - 1
        let canonical: utf8 = chain⁅at⁆.unwrap()
        let macro_body: [TemplateNode] = template_runtime_body(documents, canonical)
        let collected: TemplateMacroCollection = template_collect_macros(canonical, macro_body, documents, arena, catalog)
        macros = template_concat_macros(macros, collected.macros)
        diagnostics = template_merge_diagnostics(diagnostics, collected.diagnostics)
    }
    # 6. 最终 body：最祖文档，block 替换为最新版本（super 已展开），
    # 顶层 ImportNode 已处理不进入。
    let oldest: utf8 = chain⁅chain.length() - 1⁆.unwrap()
    let base_body: [TemplateNode] = template_runtime_body(documents, oldest)
    let mut final_body: [TemplateNode] = []
    index = 0
    while index < base_body.length() {
        let base_node: TemplateNode = base_body⁅index⁆.unwrap()
        match base_node {
            case BlockNode(payload): {
                let found: TemplateBlockVersions? = template_find_block_versions(versions, payload.name)
                if found.is_some() {
                    let block_versions: TemplateBlockVersions = found.unwrap()
                    let expanded: TemplateExpansion = template_expand_super(block_versions.bodies, block_versions.bodies.length() - 1)
                    diagnostics = template_merge_diagnostics(diagnostics, expanded.diagnostics)
                    final_body = push(final_body, BlockNode { name: payload.name, body: expanded.body })
                }
                else {
                    final_body = push(final_body, base_node)
                }
            }
            case ImportNode(payload): {
                # 已登记进宏表，不产生渲染节点。
            }
            else: {
                final_body = push(final_body, base_node)
            }
        }
        index = index + 1
    }
    let runtime: TemplateRuntime = TemplateRuntime {
        arena: arena,
        catalog: catalog,
        documents: documents,
        macros: macros,
        caller: [],
        include_stack: [entry_canonical]
    }
    let assembly: TemplateAssembly = TemplateAssembly { body: final_body, runtime: runtime }
    return data_outcome_partial(assembly, diagnostics)
}

# 无目录形态：单文档直接渲染的运行时装配。顶层宏登记；`from`/`import`
# 不可解析（fail-closed 登记，不进入 body）；extends/include 留待渲染段
# fail-closed 诊断。
micro template_assemble_single(document: TemplateDocument) -> DataOutcome<TemplateAssembly> {
    let mut diagnostics: [Diagnostic] = []
    let mut macros: [TemplateMacroEntry] = []
    let mut body: [TemplateNode] = []
    let mut index: usize = 0
    while index < document.body.length() {
        let node: TemplateNode = document.body⁅index⁆.unwrap()
        match node {
            case MacroNode(payload): {
                macros = push(macros, TemplateMacroEntry { name: payload.name, parameters: payload.parameters, body: payload.body })
                body = push(body, node)
            }
            case ImportNode(payload): {
                diagnostics = push(diagnostics, new_diagnostic("template.assemble.import_without_catalog", Error, "无模板目录，`from`/`import` 不可解析", new_span(0, 0)))
            }
            else: {
                body = push(body, node)
            }
        }
        index = index + 1
    }
    let runtime: TemplateRuntime = TemplateRuntime {
        arena: document.expressions,
        catalog: TemplateCatalog { roots: [], entries: [] },
        documents: [],
        macros: macros,
        caller: [],
        include_stack: []
    }
    let assembly: TemplateAssembly = TemplateAssembly { body: body, runtime: runtime }
    return data_outcome_partial(assembly, diagnostics)
}

# ── 继承链 ──

# 探测文档首个顶层 extends：路径必须是字符串字面量；解析失败/非字面量登记诊断并 stop。
micro template_extends_target(canonical: utf8, documents: [TemplateRuntimeDocument], arena: [TemplateExpression], catalog: TemplateCatalog) -> TemplateChainStep {
    let body: [TemplateNode] = template_runtime_body(documents, canonical)
    let mut index: usize = 0
    while index < body.length() {
        let node: TemplateNode = body⁅index⁆.unwrap()
        match node {
            case ExtendsNode(payload): {
                if payload.parent >= arena.length() {
                    let mut broken: [Diagnostic] = []
                    broken = push(broken, new_diagnostic("template.assemble.broken_extends", Error, "extends 表达式句柄越界", new_span(0, 0)))
                    return TemplateChainStep { found: true, stop: true, canonical: "", diagnostics: broken }
                }
                let expression: TemplateExpression = arena⁅payload.parent⁆.unwrap()
                match expression {
                    case LiteralString(text): {
                        let resolved: DataOutcome<TemplateResolution> = template_resolve(text.value, canonical, catalog)
                        if data_outcome_has_errors(resolved) {
                            return TemplateChainStep { found: true, stop: true, canonical: "", diagnostics: data_outcome_diagnostics(resolved) }
                        }
                        let fallback_resolution: TemplateResolution = TemplateResolution { canonical: "", entry: 0 }
                        let target: utf8 = data_outcome_value_or(resolved, fallback_resolution).canonical
                        return TemplateChainStep { found: true, stop: false, canonical: target, diagnostics: [] }
                    }
                    else: {
                        let mut not_literal: [Diagnostic] = []
                        not_literal = push(not_literal, new_diagnostic("template.assemble.extends_not_literal", Error, "extends 路径必须是字符串字面量", new_span(0, 0)))
                        return TemplateChainStep { found: true, stop: true, canonical: "", diagnostics: not_literal }
                    }
                }
            }
            else: {
                # 继续扫描。
            }
        }
        index = index + 1
    }
    return TemplateChainStep { found: false, stop: true, canonical: "", diagnostics: [] }
}

micro template_chain_contains(chain: [utf8], canonical: utf8) -> bool {
    let mut index: usize = 0
    while index < chain.length() {
        if chain⁅index⁆.unwrap() == canonical {
            return true
        }
        index = index + 1
    }
    return false
}

micro template_block_versions_push(versions: [TemplateBlockVersions], name: utf8, body: [TemplateNode]) -> [TemplateBlockVersions] {
    let mut result: [TemplateBlockVersions] = []
    let mut matched: bool = false
    let mut index: usize = 0
    while index < versions.length() {
        let entry: TemplateBlockVersions = versions⁅index⁆.unwrap()
        if entry.name == name {
            matched = true
            result = push(result, TemplateBlockVersions { name: entry.name, bodies: push(entry.bodies, body) })
        }
        else {
            result = push(result, entry)
        }
        index = index + 1
    }
    if !matched {
        result = push(result, TemplateBlockVersions { name: name, bodies: [body] })
    }
    return result
}

micro template_find_block_versions(versions: [TemplateBlockVersions], name: utf8) -> TemplateBlockVersions? {
    let mut index: usize = 0
    while index < versions.length() {
        let entry: TemplateBlockVersions = versions⁅index⁆.unwrap()
        if entry.name == name {
            return entry
        }
        index = index + 1
    }
    return null
}

# ── super 展开 ──

# 版本 version 的 body 中每个 SuperNode 拼接版本 version-1 的展开结果；
# 嵌套容器递归（嵌套 block 的 super 共享外层 block 的版本序列）。
micro template_expand_super(bodies: [[TemplateNode]], version: usize) -> TemplateExpansion {
    let source: [TemplateNode] = bodies⁅version⁆.unwrap()
    return template_expand_super_nodes(source, bodies, version)
}

micro template_expand_super_nodes(nodes: [TemplateNode], bodies: [[TemplateNode]], version: usize) -> TemplateExpansion {
    let mut result: [TemplateNode] = []
    let mut diagnostics: [Diagnostic] = []
    let mut index: usize = 0
    while index < nodes.length() {
        let node: TemplateNode = nodes⁅index⁆.unwrap()
        match node {
            case SuperNode: {
                if version == 0 {
                    diagnostics = push(diagnostics, new_diagnostic("template.assemble.super_without_parent", Error, "`super` 没有可引用的父版本块", new_span(0, 0)))
                }
                else {
                    let expanded: TemplateExpansion = template_expand_super(bodies, version - 1)
                    let mut splice: usize = 0
                    while splice < expanded.body.length() {
                        result = push(result, expanded.body⁅splice⁆.unwrap())
                        splice = splice + 1
                    }
                    diagnostics = template_merge_diagnostics(diagnostics, expanded.diagnostics)
                }
            }
            case IfNode(payload): {
                let mut branches: [TemplateIfBranch] = []
                let mut branch_index: usize = 0
                while branch_index < payload.branches.length() {
                    let branch: TemplateIfBranch = payload.branches⁅branch_index⁆.unwrap()
                    let expanded_branch: TemplateExpansion = template_expand_super_nodes(branch.body, bodies, version)
                    diagnostics = template_merge_diagnostics(diagnostics, expanded_branch.diagnostics)
                    branches = push(branches, TemplateIfBranch { test: branch.test, body: expanded_branch.body })
                    branch_index = branch_index + 1
                }
                let expanded_alternate: TemplateExpansion = template_expand_super_nodes(payload.alternate, bodies, version)
                diagnostics = template_merge_diagnostics(diagnostics, expanded_alternate.diagnostics)
                result = push(result, IfNode { branches: branches, alternate: expanded_alternate.body })
            }
            case LoopNode(payload): {
                let expanded_body: TemplateExpansion = template_expand_super_nodes(payload.body, bodies, version)
                diagnostics = template_merge_diagnostics(diagnostics, expanded_body.diagnostics)
                result = push(result, LoopNode { item: payload.item, iterable: payload.iterable, body: expanded_body.body })
            }
            case BlockNode(payload): {
                let expanded_body: TemplateExpansion = template_expand_super_nodes(payload.body, bodies, version)
                diagnostics = template_merge_diagnostics(diagnostics, expanded_body.diagnostics)
                result = push(result, BlockNode { name: payload.name, body: expanded_body.body })
            }
            case PartialNode(payload): {
                let expanded_body: TemplateExpansion = template_expand_super_nodes(payload.body, bodies, version)
                diagnostics = template_merge_diagnostics(diagnostics, expanded_body.diagnostics)
                result = push(result, PartialNode { parameters: payload.parameters, body: expanded_body.body })
            }
            case MacroNode(payload): {
                let expanded_body: TemplateExpansion = template_expand_super_nodes(payload.body, bodies, version)
                diagnostics = template_merge_diagnostics(diagnostics, expanded_body.diagnostics)
                result = push(result, MacroNode { name: payload.name, parameters: payload.parameters, body: expanded_body.body })
            }
            case CallNode(payload): {
                let expanded_body: TemplateExpansion = template_expand_super_nodes(payload.body, bodies, version)
                diagnostics = template_merge_diagnostics(diagnostics, expanded_body.diagnostics)
                result = push(result, CallNode { callee: payload.callee, caller_parameters: payload.caller_parameters, body: expanded_body.body })
            }
            else: {
                result = push(result, node)
            }
        }
        index = index + 1
    }
    return TemplateExpansion { body: result, diagnostics: diagnostics }
}

# ── 宏收集 ──

micro template_collect_macros(canonical: utf8, body: [TemplateNode], documents: [TemplateRuntimeDocument], arena: [TemplateExpression], catalog: TemplateCatalog) -> TemplateMacroCollection {
    let mut macros: [TemplateMacroEntry] = []
    let mut diagnostics: [Diagnostic] = []
    let mut index: usize = 0
    while index < body.length() {
        let node: TemplateNode = body⁅index⁆.unwrap()
        match node {
            case MacroNode(payload): {
                macros = push(macros, TemplateMacroEntry { name: payload.name, parameters: payload.parameters, body: payload.body })
            }
            case ImportNode(payload): {
                let imported: TemplateMacroCollection = template_import_macros(canonical, payload.path, payload.names, documents, arena, catalog)
                macros = template_concat_macros(macros, imported.macros)
                diagnostics = template_merge_diagnostics(diagnostics, imported.diagnostics)
            }
            else: {
                # 非宏节点不登记。
            }
        }
        index = index + 1
    }
    return TemplateMacroCollection { macros: macros, diagnostics: diagnostics }
}

micro template_import_macros(canonical: utf8, path: usize, names: [TemplateImportName], documents: [TemplateRuntimeDocument], arena: [TemplateExpression], catalog: TemplateCatalog) -> TemplateMacroCollection {
    let mut macros: [TemplateMacroEntry] = []
    let mut diagnostics: [Diagnostic] = []
    if path >= arena.length() {
        diagnostics = push(diagnostics, new_diagnostic("template.assemble.broken_import", Error, "import 路径句柄越界", new_span(0, 0)))
        return TemplateMacroCollection { macros: macros, diagnostics: diagnostics }
    }
    let expression: TemplateExpression = arena⁅path⁆.unwrap()
    match expression {
        case LiteralString(text): {
            let resolved: DataOutcome<TemplateResolution> = template_resolve(text.value, canonical, catalog)
            if data_outcome_has_errors(resolved) {
                diagnostics = template_merge_diagnostics(diagnostics, data_outcome_diagnostics(resolved))
                return TemplateMacroCollection { macros: macros, diagnostics: diagnostics }
            }
            let fallback_resolution: TemplateResolution = TemplateResolution { canonical: "", entry: 0 }
            let target: utf8 = data_outcome_value_or(resolved, fallback_resolution).canonical
            let target_body: [TemplateNode] = template_runtime_body(documents, target)
            let mut index: usize = 0
            while index < names.length() {
                let import_name: TemplateImportName = names⁅index⁆.unwrap()
                let target_macro: TemplateMacroEntry? = template_find_macro_in_body(target_body, import_name.name)
                if target_macro.is_none() {
                    diagnostics = push(diagnostics, new_diagnostic("template.assemble.unknown_import", Error, "导入目标没有该宏: " + import_name.name, new_span(0, 0)))
                }
                else {
                    let entry: TemplateMacroEntry = target_macro.unwrap()
                    if import_name.alias.is_some() {
                        macros = push(macros, TemplateMacroEntry { name: import_name.alias.unwrap(), parameters: entry.parameters, body: entry.body })
                    }
                    else {
                        macros = push(macros, entry)
                    }
                }
                index = index + 1
            }
        }
        else: {
            diagnostics = push(diagnostics, new_diagnostic("template.assemble.import_not_literal", Error, "import 路径必须是字符串字面量", new_span(0, 0)))
        }
    }
    return TemplateMacroCollection { macros: macros, diagnostics: diagnostics }
}

micro template_find_macro_in_body(body: [TemplateNode], name: utf8) -> TemplateMacroEntry? {
    let mut index: usize = 0
    while index < body.length() {
        let node: TemplateNode = body⁅index⁆.unwrap()
        match node {
            case MacroNode(payload): {
                if payload.name == name {
                    return TemplateMacroEntry { name: payload.name, parameters: payload.parameters, body: payload.body }
                }
            }
            else: {
                # 继续扫描。
            }
        }
        index = index + 1
    }
    return null
}

micro template_concat_macros(first: [TemplateMacroEntry], second: [TemplateMacroEntry]) -> [TemplateMacroEntry] {
    let mut result: [TemplateMacroEntry] = first
    let mut index: usize = 0
    while index < second.length() {
        result = push(result, second⁅index⁆.unwrap())
        index = index + 1
    }
    return result
}

# ── 合并 arena：表达式句柄偏移重映射 ──

micro template_remap_document(document: TemplateDocument, offset: usize) -> TemplateDocument {
    if offset == 0 {
        return document
    }
    return TemplateDocument { body: template_remap_nodes(document.body, offset), expressions: template_remap_expressions(document.expressions, offset) }
}

micro template_remap_nodes(nodes: [TemplateNode], offset: usize) -> [TemplateNode] {
    let mut result: [TemplateNode] = []
    let mut index: usize = 0
    while index < nodes.length() {
        result = push(result, template_remap_node(nodes⁅index⁆.unwrap(), offset))
        index = index + 1
    }
    return result
}

micro template_remap_node(node: TemplateNode, offset: usize) -> TemplateNode {
    match node {
        case TextNode(payload):
            return TextNode { text: payload.text }
        case CommentNode(payload):
            return CommentNode { text: payload.text }
        case InterpolationNode(payload):
            return InterpolationNode { expression: payload.expression + offset }
        case IfNode(payload):
            return IfNode { branches: template_remap_branches(payload.branches, offset), alternate: template_remap_nodes(payload.alternate, offset) }
        case LoopNode(payload):
            return LoopNode { item: payload.item, iterable: payload.iterable + offset, body: template_remap_nodes(payload.body, offset) }
        case BreakNode:
            return BreakNode
        case ContinueNode:
            return ContinueNode
        case ExtendsNode(payload):
            return ExtendsNode { parent: payload.parent + offset }
        case BlockNode(payload):
            return BlockNode { name: payload.name, body: template_remap_nodes(payload.body, offset) }
        case SuperNode:
            return SuperNode
        case IncludeNode(payload):
            if payload.with_expression.is_some() {
                return IncludeNode { path: payload.path + offset, with_expression: payload.with_expression.unwrap() + offset, only: payload.only }
            }
            return IncludeNode { path: payload.path + offset, with_expression: null, only: payload.only }
        case PartialNode(payload):
            return PartialNode { parameters: template_remap_parameters(payload.parameters, offset), body: template_remap_nodes(payload.body, offset) }
        case MacroNode(payload):
            return MacroNode { name: payload.name, parameters: template_remap_parameters(payload.parameters, offset), body: template_remap_nodes(payload.body, offset) }
        case CallNode(payload):
            return CallNode { callee: payload.callee + offset, caller_parameters: payload.caller_parameters, body: template_remap_nodes(payload.body, offset) }
        case ImportNode(payload):
            return ImportNode { path: payload.path + offset, names: payload.names }
        case MissingNode(payload):
            return MissingNode { reason: payload.reason }
        case PoisonNode(payload):
            return PoisonNode { reason: payload.reason }
    }
}

micro template_remap_branches(branches: [TemplateIfBranch], offset: usize) -> [TemplateIfBranch] {
    let mut result: [TemplateIfBranch] = []
    let mut index: usize = 0
    while index < branches.length() {
        let branch: TemplateIfBranch = branches⁅index⁆.unwrap()
        result = push(result, TemplateIfBranch { test: branch.test + offset, body: template_remap_nodes(branch.body, offset) })
        index = index + 1
    }
    return result
}

micro template_remap_parameters(parameters: [TemplateParameter], offset: usize) -> [TemplateParameter] {
    let mut result: [TemplateParameter] = []
    let mut index: usize = 0
    while index < parameters.length() {
        let parameter: TemplateParameter = parameters⁅index⁆.unwrap()
        if parameter.default.is_some() {
            result = push(result, TemplateParameter { name: parameter.name, default: parameter.default.unwrap() + offset })
        }
        else {
            result = push(result, TemplateParameter { name: parameter.name, default: null })
        }
        index = index + 1
    }
    return result
}

micro template_remap_handles(handles: [usize], offset: usize) -> [usize] {
    let mut result: [usize] = []
    let mut index: usize = 0
    while index < handles.length() {
        result = push(result, handles⁅index⁆.unwrap() + offset)
        index = index + 1
    }
    return result
}

micro template_remap_expressions(expressions: [TemplateExpression], offset: usize) -> [TemplateExpression] {
    let mut result: [TemplateExpression] = []
    let mut index: usize = 0
    while index < expressions.length() {
        result = push(result, template_remap_expression(expressions⁅index⁆.unwrap(), offset))
        index = index + 1
    }
    return result
}

micro template_remap_expression(expression: TemplateExpression, offset: usize) -> TemplateExpression {
    match expression {
        case LiteralNull:
            return LiteralNull
        case LiteralTrue:
            return LiteralTrue
        case LiteralFalse:
            return LiteralFalse
        case LiteralNumber(payload):
            return LiteralNumber { value: payload.value }
        case LiteralString(payload):
            return LiteralString { value: payload.value }
        case Identifier(payload):
            return Identifier { name: payload.name }
        case ObjectLiteral(payload):
            let mut entries: [TemplateObjectEntry] = []
            let mut entry_index: usize = 0
            while entry_index < payload.entries.length() {
                let entry: TemplateObjectEntry = payload.entries⁅entry_index⁆.unwrap()
                entries = push(entries, TemplateObjectEntry { key: entry.key, value: entry.value + offset })
                entry_index = entry_index + 1
            }
            return ObjectLiteral { entries: entries }
        case Member(payload):
            return Member { object: payload.object + offset, property: payload.property }
        case Index(payload):
            return Index { object: payload.object + offset, index: payload.index + offset }
        case Call(payload):
            return Call { callee: payload.callee + offset, arguments: template_remap_handles(payload.arguments, offset) }
        case Binary(payload):
            return Binary { operator: payload.operator, left: payload.left + offset, right: payload.right + offset }
        case Unary(payload):
            return Unary { operator: payload.operator, operand: payload.operand + offset }
        case Pipe(payload):
            return Pipe { expression: payload.expression + offset, filter: payload.filter, arguments: template_remap_handles(payload.arguments, offset) }
        case Test(payload):
            return Test { expression: payload.expression + offset, name: payload.name, arguments: template_remap_handles(payload.arguments, offset), negated: payload.negated }
        case ExpressionMissing(payload):
            return ExpressionMissing { reason: payload.reason }
        case ExpressionPoison(payload):
            return ExpressionPoison { reason: payload.reason }
    }
}
