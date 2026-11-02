# std.data.text.tex

TeX 数学子集解析库（Valkyrie 实现）：三段式 `tex_lex` → `tex_parse` → `tex_build`。

## 定位

- 子集：`\frac{a}{b}`、`\sqrt{a}`、上下标（`^`/`_`，可换序、同槽重复即诊断）、
  小写希腊字母命令、字母/数字/常见运算符、编组 `{ }`
- 产物：`vutex::MathNode` 数学 AST（盒构造与 SVG 发射归 `vutex`，本包不做排版）
- 合同：std.data 三段——`DataSource` + `DataSettings`，`DataOutcome` 三态，
  不首错返回；token/CST 无损（`Space` trivia 保留），span 为码点偏移（半开区间）

## 失败模型

- 非法字符：`Illegal` token + `tex.lex.illegal_code_point`，继续扫描
- 未闭合编组/游离 `}`：`Missing`/`Poison` 占位 + `tex.parse.*`，继续
- 未知命令：如实映射为可见符号 + `tex.build.unknown_command`
- 二进制源：`tex.lex.binary_source`（Error）+ 空流

## 边界

- 不做全 TeX；未支持命令不做语义猜测
- 排版内核（盒树、度量）归 `document.layout` / `vutex`
