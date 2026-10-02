namespace nyar.language.valkyrie;

using std.io;

micro compile_project_from_plan(plan_path: utf8, dependency_count: i32) -> CompileResult {
    let plan: SmokeCompilePlan = parse_compile_plan_snapshot(plan_path)
    if plan.output_dir.length() == 0 {
        return CompileResult {
            ok: false,
            error: "无法读取 compile-plan.txt：" + plan_path,
            output: empty_compile_output()
        }
    }
    return CompileResult {
        ok: false,
        error: "V canonical compiler 尚未提供 Semantic MIR → RepresentationPlan → BackendPrivatePlan；拒绝 FragmentSubmission/body_source 旁路",
        output: empty_compile_output()
    }
}
