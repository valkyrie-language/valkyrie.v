namespace test.module_system;

using nyar;

micro module_system_smoke() -> i32 {
    let parsed: CanonicalTarget = parse_target("clr-microsoft-unknown-managed")
    let formatted: utf8 = format_target(parsed)
    # `default_target()` 已删除；nyar target 须显式解析 canonical 三元组。
    let nyar_target: CanonicalTarget = parse_target("nyar-unknown-unknown")

    if formatted != "clr-microsoft-unknown-managed" {
        return 1
    }
    if nyar_target.architecture != "nyar" {
        return 2
    }
    return 0
}

[main]
micro main(): i32 {
    return module_system_smoke()
}
