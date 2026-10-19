namespace legion;

using nyar;
using std.math.graph_theory;

structure LegionBuildContext {
    project_dir: utf8
    manifest_path: utf8
    project_name: utf8
    canonical_target: utf8
    output_dir: utf8
    dependency_names: [utf8]
    dependency_order: [utf8]
    arch_tag: utf8
    abi: utf8
    backend_family: utf8
    verbose: bool
    preferred_logical_entry: utf8
    include_test_sources: bool
    build_options: LegionBuildTargetOptions
}

# 将短目标名归一化为完整三元组前缀，供 legion_canonical_target 使用。
# 这里只做短名展开，不做结构化解析，结构化解析交给 nyar.parse_target。
micro legion_normalize_short_target(value: utf8) -> utf8 {
    if value == "clr" || value == "clr-microsoft-unknown-managed" {
        return "clr-microsoft-unknown-managed"
    }
    if value == "jvm" || value == "jvm-openjdk-unknown-managed" {
        return "jvm-openjdk-unknown-managed"
    }
    if value == "wasm" || value == "wasm32-unknown-browser-wasm" {
        return "wasm32-unknown-browser-wasm"
    }
    if value == "node" || value == "wasm32-node-unknown-wasm" {
        return "wasm32-node-unknown-wasm"
    }
    if value == "deno" || value == "wasm32-deno-unknown-wasm" {
        return "wasm32-deno-unknown-wasm"
    }
    if value == "bun" || value == "wasm32-bun-unknown-wasm" {
        return "wasm32-bun-unknown-wasm"
    }
    if value == "wasi" || value == "wasm32-unknown-wasi-wasi" {
        return "wasm32-unknown-wasi-wasi"
    }
    if value == "nyar" || value == "nyar-unknown-unknown" {
        return "nyar-unknown-unknown"
    }
    return ""
}

# 已删除 `legion_parse_canonical_target`：未知 target 不得回落到 `default_target()` 成功。
# 目标解析只有一条路径 `legion_canonical_target`（未支持返回空串，由调用方结构化失败）。

# 返回规范化的目标三元组字符串。
# 内部使用 nyar.parse_target 和 nyar.format_target 完成结构化解析与格式化。
micro legion_canonical_target(target: utf8) -> utf8 {
    let value: utf8 = target.trim().to_lower()
    let canonical: utf8 = legion_normalize_short_target(value)
    if canonical.length() == 0 {
        return ""
    }
    let parsed: CanonicalTarget = parse_target(canonical)
    return format_target(parsed)
}

# Explicit loops — CLR anon-micro→Delegate still InvalidProgram (uninit int32 locals).
micro legion_requested_targets(value: utf8) -> [utf8] {
    if value.trim().length() == 0 {
        return []
    }
    if value.trim().to_lower() == "all" {
        return ["clr", "jvm", "wasm", "nyar"]
    }

    let pieces: [utf8] = value.split(",")
    let mut result: [utf8] = []
    let mut i: usize = 0
    while i < pieces.length() {
        let target: utf8 = pieces⁅i⁆.trim()
        if target.length() > 0 {
            result = push(result, target)
        }
        i = i + 1
    }
    return result
}

micro legion_manifest_targets(manifest: LegionProjectManifest, requested_target: utf8) -> [utf8] {
    let explicit_targets: [utf8] = legion_requested_targets(requested_target)
    if explicit_targets.length() > 0 {
        return explicit_targets
    }

    let mut result: [utf8] = []
    let mut i: usize = 0
    while i < manifest.build_targets.length() {
        result = push(result, manifest.build_targets⁅i⁆.name)
        i = i + 1
    }
    return result
}

micro legion_last_path_segment(path: utf8) -> utf8 {
    let parts: [utf8] = normalize_path(path).split("/")
    let mut last: utf8 = ""
    let mut i: usize = 0
    while i < parts.length() {
        let part: utf8 = parts⁅i⁆
        if part.length() > 0 {
            last = part
        }
        i = i + 1
    }
    return last
}

micro legion_project_name(project_dir: utf8, manifest: LegionProjectManifest) -> utf8 {
    if manifest.name.trim().length() > 0 {
        return manifest.name.trim()
    }
    return legion_last_path_segment(project_dir)
}

micro legion_output_root(project_dir: utf8, output: utf8) -> utf8 {
    if output.trim().length() == 0 {
        return path_join(project_dir, "dist")
    }
    return resolve_project_dir(output)
}

# target → arch 标签只映射 nyar.CanonicalTarget.architecture，不再对 canonical 字符串
# 做 prefix/suffix/contains 反推；ABI 直接读 CanonicalTarget.abi，不再按后缀猜。
micro legion_target_arch_tag(architecture: utf8) -> utf8 {
    if architecture == "wasm32" || architecture == "wasm64" {
        return "wasm"
    }
    if architecture == "clr" {
        return "clr"
    }
    if architecture == "jvm" {
        return "jvm"
    }
    if architecture == "nyar" {
        return "nyar"
    }
    return ""
}

# backend family 只由 arch 标签派生，唯一所有者，不再维护第二套别名表。
micro legion_target_backend_family(arch_tag: utf8) -> utf8 {
    if arch_tag == "nyar" {
        return "nyar_vm"
    }
    return arch_tag
}

# 已删除 `legion_find_build_target` 的「未声明即合成空 options」回落：
# manifest 未声明 requested target 时不得伪造一个成功用的 LegionBuildTarget。
# 调用方 `legion_build_contexts` 在扫描后按声明与否结构化失败。

# 构建依赖图：使用图论模块的有向图存储依赖关系
# 边方向为 A → B 表示 A 依赖 B
micro legion_build_dependency_graph(manifest: LegionProjectManifest, project_name: utf8) -> DirectedGraph {
    let mut graph: DirectedGraph = directed_graph_new()

    # 添加项目自身节点
    directed_graph_add_node(graph, project_name)

    # 根据 auto_link 添加隐式 core/std 依赖
    if manifest.auto_link_core {
        directed_graph_add_edge(graph, project_name, "core")
    }
    if manifest.auto_link_std {
        directed_graph_add_edge(graph, project_name, "std")
    }

    # 添加显式声明的依赖
    let mut di: usize = 0
    while di < manifest.dependencies.length() {
        directed_graph_add_edge(graph, project_name, manifest.dependencies⁅di⁆.name)
        di = di + 1
    }

    return graph
}

# 获取项目的依赖包名称列表（不含自身）
micro legion_dependency_names(manifest: LegionProjectManifest, project_name: utf8) -> [utf8] {
    let mut result: [utf8] = []

    if manifest.auto_link_core {
        result = push(result, "core")
    }
    if manifest.auto_link_std {
        result = push(result, "std")
    }

    let mut di: usize = 0
    while di < manifest.dependencies.length() {
        result = push(result, manifest.dependencies⁅di⁆.name)
        di = di + 1
    }

    return result
}

micro legion_build_contexts(
    project_dir: utf8,
    manifest_path: utf8,
    manifest: LegionProjectManifest,
    request: BuildRequest)
    -> VonParseResult<[LegionBuildContext]> {
    let targets: [utf8] = legion_manifest_targets(manifest, request.target)
    if targets.length() == 0 {
        return Fail(new_von_diagnostic("未指定构建目标，且 legion.von 中无 build 列表", 0, 0))
    }

    let mut contexts: [LegionBuildContext] = []
    let output_root: utf8 = legion_output_root(project_dir, request.output)
    let project_name: utf8 = legion_project_name(project_dir, manifest)

    # 构建依赖图
    let dep_graph: DirectedGraph = legion_build_dependency_graph(manifest, project_name)

    # 循环依赖检测
    if has_cycle(dep_graph) {
        let cycle_path: [utf8] = find_cycle(dep_graph)
        return Fail(new_von_diagnostic("检测到循环依赖", 0, 0))
    }

    # 拓扑排序确定编译顺序
    let build_order: [utf8] = topological_sort(dep_graph)
    let dep_names: [utf8] = legion_dependency_names(manifest, project_name)

    let mut i: usize = 0
    while i < targets.length() {
        let requested: utf8 = targets⁅i⁆
        let canonical: utf8 = legion_canonical_target(requested)
        if canonical.length() == 0 {
            return Fail(new_von_diagnostic("存在不支持的构建目标", 0, 0))
        }

        # declared options 只在 manifest 声明确实存在该 target 时赋值；
        # 未声明即失败，不得使用合成的空 options 继续构建。
        let parsed: CanonicalTarget = parse_target(canonical)
        let mut declared: bool = false
        let mut declared_options: LegionBuildTargetOptions = legion_empty_build_target_options()
        let mut ti: usize = 0
        while ti < manifest.build_targets.length() {
            let candidate: LegionBuildTarget = manifest.build_targets⁅ti⁆
            if candidate.name == requested || legion_canonical_target(candidate.name) == canonical {
                declared_options = candidate.options
                declared = true
            }
            ti = ti + 1
        }
        if !declared {
            return Fail(new_von_diagnostic("manifest 未声明请求的构建目标", 0, 0))
        }
        let arch_tag: utf8 = legion_target_arch_tag(parsed.architecture)

        push(contexts, LegionBuildContext {
            project_dir: project_dir,
            manifest_path: manifest_path,
            project_name: project_name,
            canonical_target: canonical,
            output_dir: path_join(output_root, canonical),
            dependency_names: dep_names,
            dependency_order: build_order,
            arch_tag: arch_tag,
            abi: parsed.abi,
            backend_family: legion_target_backend_family(arch_tag),
            verbose: request.verbose,
            preferred_logical_entry: "",
            include_test_sources: false,
            build_options: declared_options
        })
        i = i + 1
    }

    return Fine(contexts)
}
