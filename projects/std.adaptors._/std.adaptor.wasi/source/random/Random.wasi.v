# WASI Preview 2（`wasi` / wasip2 规格别名）

[when(target.specification == "wasi")]
namespace std.adaptor.wasi.random;

[host_provider(std::random::entropy)]
micro host_entropy() -> u64
