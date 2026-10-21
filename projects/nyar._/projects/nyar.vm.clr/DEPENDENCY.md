# nyar.vm.clr — dependency direction

```
canonical Compiler → TargetExecutionPlan → typed MSIL / PE
    → nyar.vm.clr
```

- VM must **not** depend on `nyar.language` or AST packages; it only consumes artifacts.
- CLR lowering consumes only the formal `TargetExecutionPlan` produced by the compiler boundary.
- Formal isomorphic path only. Do **not** document `clr_body_lowering` / `body_source→MSIL` or type-name special-case emit as the architecture.

Status: documentation shell only (no V sources yet).
