# nyar.vm.wasm — dependency direction

This package is a **runtime/host shell** for Wasm / WASI artifacts.

Correct direction:

```
canonical Compiler → TargetExecutionPlan → .wasm (+ JS glue | wasip2/wasip3 CM)
                                      ↓
                                 nyar.vm.wasm
```

Rules:
- `nyar.vm.wasm` must **not** depend on `nyar.language` or AST packages.
- The target backend owns only encoding of the compiler-provided private plan and host shells.
- VM runs/loads artifacts; it does not lower language AST.
- V-side canonical Compiler is not connected; source-to-artifact construction fails explicitly.

Status: documentation shell only (no V sources yet).
