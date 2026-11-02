# template

Valkyrie 模板渲染核心包。**只做渲染，不含解析**：输入是 `std.data.text` 的公共模板 AST
（由 `std.data.text.dejavu` 等方言包的三段管线产出），输出为纯内存求值文本。

## 渲染侧职责

- 上下文帧栈与作用域查找：内层帧 → 外层帧 → 根上下文；loop 每迭代压帧
  （循环变量 + `forloop` 隐式绑定 `index` / `index0` / `first` / `last` / `length` / `depth`）
- 表达式求值：truthiness 表、结构相等（不跨类型）、数字比较、`|>` 管道、`is` 测试、
  成员/下标访问、对象字面量
- 插值出口：默认 HTML 转义（`&` `<` `>` `"` `'`）；`safe` / `raw` / `escape` 产 `SafeTextValue` 跳过；
  safe-output 只看最外层过滤器（`x |> safe |> uppercase` 仍转义）
- 控制流：`break` / `continue` 以显式信号上传，绑定词法最近外层 loop
- undefined 模式：缺失标识符默认落 null；`strict_undefined` 产 `template.render.undefined_variable`
- 注册表：内置 filter（uppercase/upper/lowercase/lower/trim/default/length/join/replace/
  escape/e/safe/raw）、function（range/min/max）、test（null/none/truthy/empty/array/object/
  string/number/boolean/even/odd）；错误不穿透渲染栈（诊断 + 值落 null，继续渲染）

## 分层

| 文件 | 职责 |
|---|---|
| `source/value.v` | 值模型（JSON 同构 + `SafeTextValue`）、truthiness、结构相等、字符串化、数字解析/格式化 |
| `source/escape.v` | HTML 转义 |
| `source/filter.v` | 内置过滤器/函数/测试注册表与实现 |
| `source/render.v` | 渲染管线：帧栈、控制信号、插值出口、`template_render` 入口 |

## 边界

- 解析（lexer/parser/builder）归 `std.data.text.<dialect>`，本包及本包测试一律不经手源码文本
- loader / partial 装配（文件目录、canonical id）是宿主能力，尚未接入
- `date` 过滤器（时间源）与 `slug` 过滤器（Unicode NFKD 数据表）：当前未提供
- 非整数数字字符串化：JS 风格最短往返格式化未实现，插值命中非整数产
  `template.render.number_fraction`（Error），不输出近似值
- 渲染诊断码 `template.render.*`，随 `render.v`/`filter.v` 注释登记
