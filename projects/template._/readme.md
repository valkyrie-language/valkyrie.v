# template._

`template._` 是 Valkyrie 模板语言生态的顶层 workspace，与 `document._`、`database._` 平行。

## 定位

- 模板表面：文本 / `<% %>` 代码定界 / `<# #>` 注释定界，插值与语句共享代码定界
- 解析走 `std.data` 三段合同：lexer → token 流、parser → 无损 CST、builder → 语义 AST
- 求值/渲染在 V 侧内存完成：值模型、truthiness、HTML 转义、作用域帧、过滤器/函数/测试注册表
- loader（模板目录、文件探测、canonical id）依赖宿主文件能力，属后续块；渲染出口接 asgard/ssg，不在这里另造

## 成员

- `template`：模板语言核心包 —— 词法、语法、CST、AST、值模型与内存渲染器

## 边界

- 不进编译器特判：模板语义全部由本生态的普通 V 代码承载
- `std.data` 只拥有解析产物；渲染/求值归本生态，不回流 `std.data`
- 宿主依赖（文件、网络、时间源、Unicode 分解数据）显式登记为缺口，不用 V 侧伪造
