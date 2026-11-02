# template

Valkyrie 模板语言核心包。解析走 `std.data` 三段合同（lexer → token 流、parser → 无损 CST、builder → 语义 AST），渲染为纯内存求值，不依赖宿主文件/网络能力。

## 模板表面（v0 首块）

- 文本：定界符外按源码原样输出
- 注释：`<# ... #>`，不进入渲染输出
- 代码：`<% ... %>`，插值与语句共享定界，由 parser 按内容区分
- 空白控制：开标左 marker `<%_` / `<%-` / `<%~` / `<%=`，闭标右 marker `_%>` / `-%>` / `~%>` / `=%>`；
  级别阶梯 `none` → `ws`（水平空白）→ `nl`（恰好一个换行）→ `ws_nl`（水平空白 + 一个换行 + 水平空白）→ `all`（连续全部 Unicode 空白）
- 转义形式：`<%!` 输出字面 `<%`，不参与空白控制
- 语句：`if` / `else if` / `else` / `end if`，`loop item in xs` / `end loop`（隐式 `forloop` 绑定
  `index` / `index0` / `first` / `last` / `length` / `depth`），`break` / `continue` 绑定词法最近外层 `loop`
- 表达式：字面量（null / 布尔 / 数字 / 字符串 / 对象）、标识符、成员 `.`、下标 `[]`、调用 `()`、
  二元 `== != < <= > >= && || in + - * / %`、一元 `! - +`、管道 `|>`、测试 `is` / `is not`
- 插值默认 HTML 转义（`&` `<` `>` `"` `'`）；`|> safe` / `|> raw` / `|> escape` 退出自动转义

## 分层

| 文件 | 段 | 职责 |
|---|---|---|
| `source/kind.v` | 公共 | token 类与 CST 节点类（同一 `unite`）、trim 级别 |
| `source/lexer.v` | lexer | 源文本 → token 流；定界、trim、非法单元恢复 |
| `source/parser.v` | parser | token 流 → 无损 CST；语句头分类、表达式优先级、闭合恢复 |
| `source/ast.v` | 公共 | 语义 AST（表达式以 arena 承载，见下）、值模型 |
| `source/builder.v` | builder | CST → AST；`Missing`/`Poison` 如实映射 |
| `source/value.v` | 渲染 | truthiness、结构相等、字符串化、数字解析/格式化 |
| `source/escape.v` | 渲染 | HTML 转义 |
| `source/filter.v` | 渲染 | 内置过滤器/函数/测试注册表与实现 |
| `source/render.v` | 渲染 | 作用域帧、控制流信号、插值转义出口 |

## 表达式 arena

AST 表达式树以 `TemplateDocument.expressions` 平坦数组 + `usize` 句柄承载，不做递归 payload。
原因：V 侧已证实可用的是经数组的递归（`DataCstNode` / `VonValue` 先例），直接递归 unite payload
在 CLR 自举侧被明确规避（`std.data.text.valkyrie` 的 flat term shell 注释）。arena 是确定、
可序列化的等价承载，不是语义裁剪。

## 合同缺口登记（首块明确不做）

- `extends` / `block` / `super` / `include` / `partial` / `macro` / `call` / `from`：依赖 loader
  （文件目录、canonical id、环检测），loader 是宿主能力，后续块接入；parser 对这些关键字
  产出 `template.parse.unsupported_statement` 结构化诊断并恢复，不误当表达式
- 自定义定界符：词法常量固定 `<%` `%>` `<#` `#>`，设置结构预留，后续块开放
- `date` 过滤器（时间源是宿主能力）与 `slug` 过滤器（NFKD 分解需要 Unicode 数据表）：后续块
- 非整数字符串化：`1.5` 这类小数的 JS 风格最短往返格式化首块未实现，插值命中非整数
  时按 `template.render.number_fraction` 结构化失败，不输出近似值
- 注释定界的 trim marker：首块只对代码定界实现空白控制
- 词素回切：`builder` 需要源文本按 span 切回词素，但三段 trait 的 `build` 签名不带 source；
  本包 `template_build` 显式多带一个 `source: DataSource` 参数，属 `std.data` 合同缺口的
  本地签名扩展，已在本文件登记

## 诊断码

词法 `template.lex.*`、语法 `template.parse.*`、构建 `template.build.*`、渲染 `template.render.*`，
码表随实现文件注释登记，均为稳定机器码，不随文案变化。
