# nyar.vm.jvm — dependency direction

This package is a **runtime/host shell** for JVM artifacts.

Correct direction:

```
canonical Compiler → BackendPrivatePlan → classfile / JAR
                                      ↓
                                 nyar.vm.jvm
```

Rules:
- `nyar.vm.jvm` must **not** depend on `nyar.language` or AST packages.
- It may depend on `nyar` (runtime contracts) and JVM host adapters.
- JVM codegen consumes only the formal `BackendPrivatePlan` produced by the compiler boundary.
- Do **not** treat language body bypass or type-name special-case emit as the formal path.

Status: documentation shell only; V-side canonical Compiler is not connected and source builds fail explicitly.
