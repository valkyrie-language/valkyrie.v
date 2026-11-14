# jvm runtime dependency direction

A language owns its IR and semantics. A language-to-target adapter lowers verified language IR or a specialized residual into a target-private plan and LIR. The target validates and encodes classfile / JAR artifacts, then the runtime/host package loads them.

The runtime must not depend on language AST packages or call a compiler to repair missing facts. Ordinary functions and synthetic wrappers use the same target LIR encoder. Dynamic behavior requires an explicit language-runtime contract. Unsupported runtime requirements fail explicitly.

Nyar supplies reusable transformation, analysis, optimization and specialization tools. It does not require a universal language MIR. Only the OVM target emits `.odin` for OdinVM.

This package is a documentation/host shell. These responsibilities do not establish that the V-side source compiler or every target capability is implemented.
