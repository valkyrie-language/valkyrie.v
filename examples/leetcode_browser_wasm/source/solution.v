namespace std.math.random;

# 示例：题解只依赖 std 语义 + 自动注入的 std.adaptor.wasm（browser 下 `js.random` capability）。
[export]
micro solve(seed: i32, max_exclusive: i32) -> i32 {
    let generator: Random = Random::with_seed(seed)
    return generator.next_i32(max_exclusive)
}

[main]
micro main() -> i32 {
    return solve(42, 100)
}
