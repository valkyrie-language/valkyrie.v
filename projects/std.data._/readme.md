# std.data._ — V 端格式模型工作区盘点（V0 第一步）

依据设计文档《16-V端格式分析与Asgard定义合同》§3 与 §7 V0：每个已声明格式必须有 V 侧
模型、解析/编码、结构化 diagnostic 与 conformance fixtures；空壳与平行重复 owner 清退。
本表是盘点结论（2026-10-31，基于仓内源码逐文件核对，未运行真实编译验证）。

## 逐格式状态表

| 包 | 状态 | 有什么 | 缺什么 | 建议处置 |
| --- | --- | --- | --- | --- |
| `std.data.text.von` | real | lexer(185)/parser(155)、`VonValue` AST、`TextSpan`/`VonDiagnostic`/`VonParseResult`；已被 `legion`、`nyar.package_registry`、`nyar.package_manager` 作消费者引用 | encoder（canonical 输出/round-trip）、conformance fixtures、尾部/重复字段消费合同测试 | 保留，补 encoder 与 fixtures |
| `std.data.text.valkyrie` | partial | `ast.v`/`ast_body.v`/`cst.v`/`token.v`/`span.v` 声明模型（isomorphic to Rust `std-data::text::valkyrie`） | lexer、parser（源文本 → AST/CST 的完整入口）、diagnostic 消费面、fixtures | 保留为 `.v` 文本模型唯一 owner，补 lexer/parser；`_.v` 已声明禁止再立平行 `std.data.text.v` 包 |
| `std.data.text.json` | shell | 仅 `documentation/pages/**/index.md`（正文为空文件）；无 `legion.von`、无 `source/`，不在 `legions.von` members | 全部：模型、lexer/parser、encoder、diagnostic | 二选一：作为待建格式保留占位并在表内挂工作包，或删除目录；当前不删（非重复 owner） |
| `std.data.text.xml` | shell | 同上（仅空 documentation 页） | 全部 | 同上 |
| `std.data.text.html` | shell | 同上（仅空 documentation 页） | 全部 | 同上；注意设计 16 §3.1：HTML 格式事实归本包，W/AWSL 组件语义不归它 |
| `std.data.text.svg` | shell | 同上（仅空 documentation 页） | 全部 | 同上 |
| `std.data.text.wat` | real | lexer(273)/parser(911)/`ast.v`/`token.v`、`WatDiagnostic`/`WatParseResult` | WAT→Wasm 二进制 encode、fixtures | 保留，补 encode 与 fixtures |
| `std.data.text.wit` | real | lexer(185)/parser(585)/`ast.v`/`token.v`、diagnostic/result 面 | canonical format/round-trip、fixtures | 保留 |
| `std.data.text.msil` | real | lexer(359)/parser(1064)/render(268)/`ast.v`/`typed.v`/`string_encoding.v`、`MsilDiagnostic`/`MsilParseResult` | round-trip 规则（parse↔render canonical 化）、fixtures | 保留 |
| `std.data.binary.wasm` | real | `decode.v`(830)/`encode.v`(414)/`_.v`(238)/`data.v`/`opcode.v`（`WasmOpcode` 与值/外部种类）/`opcodes.v`（magic/section 常量与 push 助手）；`opcode.v` 与 `opcodes.v` 是互补分工（枚举 vs 常量助手），非重复 owner | fixtures、与 `std.data.text.wat` 的跨包 round-trip 合同 | 保留 |
| `std.data.binary.clr` | real(partial) | `decode.v`(778) PE/CLI 元数据读取、`data.v`、`ClrBinaryResult`/diagnostic 基础面 | encode（CLR/PE 写出）、fixtures | 保留，encode 归 CLR lane（当前交付线冻结 CLR，非门禁） |
| `std.data.binary.class` | shell(stub) | `_.v`(53)：类型面 + `jvm_encode_classfile_with_methods` 显式 stub（返回空字节，注释自证「encode not ready」） | decode、真实 encode | 保留为 JVM lane 占位（注释已声明其存在理由：workspace 符号解析）；不得被当作可用 encoder |
| `std.data.binary.jar` | shell | `_.v`(22)：diagnostic/result 类型 + `jar_encode_empty` 占位 | zip/jar encode 全部 | 同上，JVM lane 占位；JVM 线冻结，不入当前门禁 |

## 平行重复 owner 检索结论（机械验证）

- 全仓检索 `ValkyrieRoot`/`RootStatement`/`IdentifierNode`：唯一模型 owner 是
  `std.data.text.valkyrie`；`nyar._/projects/nyar.language/source/valkyrie/hir/module.v`
  通过 `using std.data.text.valkyrie;` 消费该模型做 AST→HIR，是下游消费者，不是重复 owner。
- 全仓检索 `VonValue`/`von_parse`：唯一 VON 模型 owner 是 `std.data.text.von`；
  `legion.tools`、`nyar.package_registry`、`nyar.package_manager` 均 `using std.data.text.von`，
  是消费者。
- `asgard` 包 `source/json.v` 是 `[js_builtin("JSON.parse")]` 宿主绑定，不是 V 侧 JSON 格式
  模型 owner，与 `std.data.text.json`（待建）不构成重复。
- 结论：本工作区未发现明确平行重复的格式 owner，本次无删除动作；四个 documentation-only
  空壳包（json/xml/html/svg）的处置（补建或清退）待 V0 后续工作包按格式优先级定案。

## 全局缺口

- 所有包均无 `test/` 目录与 conformance fixtures；设计 16 §3.1 要求的「V 实现与 Rust
  加速实现同 fixture 一致 canonical 结果」目前无处执行。
- `legions.von` members 与实际目录一致（9 个已声明包全部在册）；4 个空壳目录不在册，
  即当前没有任何构建入口会消费它们。
