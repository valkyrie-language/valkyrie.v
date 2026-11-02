# std.data.text.dejavu

dejavu 模板方言的三段实现：lexer → token 流、parser → 无损 CST、builder → `std.data.text`
公共模板 AST。本包只做解析，不做渲染；渲染归 `template.*` 生态（表达式求值、作用域、
转义策略、循环元数据、严格模式、注册表）。

## 模板表面（v0）

- 文本：定界符外按源码原样输出
- 注释：`<# ... #>`，不进入渲染输出
- 代码：`<% ... %>`，插值与语句共享定界，由 parser 按内容区分
- 空白控制：开标左 marker `<%_` / `<%-` / `<%~` / `<%=`，闭标右 marker `_%>` / `-%>` / `~%>` / `=%>`；
  级别阶梯 `none` → `ws`（水平空白）→ `nl`（恰好一个换行）→ `ws_nl`（水平空白 + 一个换行 + 水平空白）→ `all`（连续全部 Unicode 空白）
- 转义形式：`<%!` 输出字面 `<%`，不参与空白控制
- 语句：`if` / `else if` / `else` / `end if`，`loop item in xs` / `end loop`，`break` / `continue`
  绑定词法最近外层 `loop`（当前词法单元 = 模板顶层与 loop body）
- 表达式：字面量（null / 布尔 / 数字 / 字符串 / 对象）、标识符、成员 `.`、下标 `[]`、调用 `()`、
  二元 `== != < <= > >= && || in + - * / %`、一元 `! - +`、管道 `|>`、测试 `is` / `is not`

## 分层

| 文件 | 段 | 职责 |
|---|---|---|
| `source/kind.v` | 公共 | token 类与 CST 节点类（同一 `unite`）、trim 级别 |
| `source/lexer.v` | lexer | 源文本 → token 流；定界、trim、非法单元恢复 |
| `source/parser.v` | parser | token 流 → 无损 CST；语句头分类、表达式优先级、闭合恢复 |
| `source/builder.v` | builder | CST → `std.data.text` 公共模板 AST；`Missing`/`Poison` 如实映射 |

## 当前能力边界

- `extends` / `block` / `super` / `include` / `partial` / `macro` / `call` / `from`：依赖 loader
  （文件目录、canonical id、环检测），loader 是宿主能力，尚未接入；parser 对这些关键字
  产出 `template.parse.unsupported_statement` 结构化诊断并恢复，不误当表达式
- 自定义定界符：词法常量固定 `<%` `%>` `<#` `#>`，尚未开放为设置
- 注释定界的 trim marker：当前只对代码定界实现空白控制
- 词素回切：`builder` 需要源文本按 span 切回词素，但三段 trait 的 `build` 签名不带 source；
  本包 `template_build` 显式多带一个 `source: DataSource` 参数，是对三段 trait 的本地签名扩展

## 诊断码

词法 `template.lex.*`、语法 `template.parse.*`、构建 `template.build.*`，随实现文件注释登记，
均为稳定机器码。渲染侧诊断（`template.render.*`）归 `template` 包。
