# template._

`template._` 是 Valkyrie 模板渲染生态的顶层 workspace，与 `document._`、`database._` 平行。

## 定位

- **只做渲染**：上下文栈与作用域查找、表达式求值、过滤器/函数/测试注册表、
  转义策略、真值判定与严格模式、循环元数据
- 输入是 `std.data.text` 的公共模板 AST；解析（lexer/parser/builder）归
  `std.data.text.<dialect>` 方言包，不在本生态
- 渲染出口尚未接入 asgard/ssg；partial 装配与 loader（宿主文件能力）尚未接入

## 成员

- `template`：模板渲染核心包 —— 值模型、作用域、转义、内建注册表、渲染管线

## 边界

- 不进编译器特判：渲染语义全部由本生态的普通 V 代码承载
- 宿主依赖（文件、网络、时间源、Unicode 分解数据）未接入前一律结构化失败，不用 V 侧伪造
- 本生态及测试一律不经手模板源码文本；端到端链由消费方按方言组装
