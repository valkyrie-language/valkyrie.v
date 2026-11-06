# std.adaptor.wasm: 时间 contract

namespace std.adaptor.wasm.io;

using std.adaptor.wasm.performance::{perf_now};
using std.adaptor.wasm.timer::{set_timeout};

[host_provider(std::io::now)]
micro time_ms(): i64 {
    return i64(perf_now())
}

[host_provider(std::io::monotonic)]
micro monotonic_ms(): i64 {
    return i64(perf_now())
}

[host_provider(std::io::sleep)]
micro sleep_ms(ms: i32): unit {
    set_timeout(0, ms)
}
