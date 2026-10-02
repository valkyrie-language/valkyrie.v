namespace nyar.language.valkyrie;

using nyar.analyzer;
using nyar.emitter;
using nyar.emitter.executable;
using std.data.text.valkyrie;
using nyar.language.valkyrie.hir;
using nyar.language.valkyrie.mir;

# Language pipeline: AST → HIR → MIR → ExecutableModule → nyar.emitter (any lane).

micro program_facts_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> ProgramFacts {
    let hir: HirModule = hir_from_valkyrie_root(root, module_name)
    let mut facts: ProgramFacts = empty_program_facts()
    facts.module_name = hir.name
    let mut i: usize = 0
    while i < hir.functions.length() {
        let f: HirFunction = hir.functions⁅i⁆
        facts.functions = push(facts.functions, FunctionAnalysis {
            symbol: f.name,
            is_external: f.is_abstract,
            can_suspend: false,
            is_async: false,
            uses_host_interop: false,
            external_import_link: "",
            host_provider_for: "",
            reference_management_hint: ""
        })
        i = i + 1
    }
    return facts
}
micro mir_module_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> MirModule {
    let hir: HirModule = hir_from_valkyrie_root(root, module_name)
    return mir_from_hir_module(hir)
}

micro executable_module_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> ExecutableModule {
    let mir: MirModule = mir_module_from_valkyrie_root(root, module_name)
    return adapt_mir_module_to_executable(mir)
}

# CLR emit consumes the ExecutableModule contract through nyar.emitter.clr.
micro emit_msil_text_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> EmitterResult {
    let executable_module: ExecutableModule = executable_module_from_valkyrie_root(root, module_name)
    return emit_clr_from_mir(executable_module)
}

micro emit_jvm_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8) -> EmitterResult {
    let executable_module: ExecutableModule = executable_module_from_valkyrie_root(root, module_name)
    return emit_jvm_lane(executable_module)
}

micro emit_for_target_from_valkyrie_root(root: ValkyrieRoot, module_name: utf8, target: utf8) -> EmitterResult {
    let executable_module: ExecutableModule = executable_module_from_valkyrie_root(root, module_name)
    return emit_for_target(executable_module, target)
}
