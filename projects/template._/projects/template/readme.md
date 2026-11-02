# template

Valkyrie 模板渲染核心包。**只做渲染与装配，不含解析**：输入是 `std.data.text` 的公共模板 AST
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
- 继承与包含：`extends`/`block`/`super` 装配展开；`include` 三态上下文（继承 /
  `with` 合并 / `only` 独占）；`partial` 参数化绑定；`macro`/`call`/`from` 宏与 caller 块

## 装配侧职责

- loader：path-v1 引用策略（scheme / 相对 / 裸路径三分、规范 id `root:path`、
  扩展探测序 原文 → `.html` → `.dejavu`、root `priority` 降序、循环检测）；
  非内存 root 一律 fail-closed（`template.loader.host_capability`）
- 模板源窄接口：策略层与装配层对模板源的访问收敛于 `source.v` 的接口函数
  （root 枚举/查找、条目探测/枚举/取下）；当前实现为内存目录，
  待 `std.vfs` 落地后整体替换为 vfs provider 适配
- assemble：全源合并表达式 arena（跨模板句柄统一有效）、继承链展开
  （block 逐版本覆盖、`super` 拼接、循环 fail-closed）、宏表登记
  （链上顶层 `macro` + `from`/`import` 目标宏）

## 分层

| 文件 | 职责 |
|---|---|
| `source/value.v` | 值模型（JSON 同构 + `SafeTextValue`）、truthiness、结构相等、字符串化、数字解析/格式化 |
| `source/escape.v` | HTML 转义 |
| `source/filter.v` | 内置过滤器/函数/测试注册表与实现 |
| `source/source.v` | 模板源窄接口 + 当前内存目录实现（待 `std.vfs` 落地后整体替换） |
| `source/loader.v` | path-v1 引用策略（分类、规格化、扩展探测序、优先级排序） |
| `source/assemble.v` | 合并 arena、继承链展开、宏表登记 |
| `source/render.v` | 渲染管线：帧栈、控制信号、插值出口、include/partial/宏渲染、`template_render` / `template_render_catalog` 入口 |

## 边界

- 解析（lexer/parser/builder）归 `std.data.text.<dialect>`，本包及本包测试一律不经手源码文本
- 文件/网络等宿主模板源不接入：目录树/路径解析/条目枚举是 `std.vfs` 职责，
  本包只经 `source.v` 窄接口读模板源，其他 root 形态 fail-closed
- `date` 过滤器（时间源）与 `slug` 过滤器（Unicode NFKD 数据表）：当前未提供
- 非整数数字字符串化：JS 风格最短往返格式化未实现，插值命中非整数产
  `template.render.number_fraction`（Error），不输出近似值
- 渲染诊断码 `template.render.*` 随 `render.v`/`filter.v` 注释登记；
  加载/装配诊断码 `template.loader.*` / `template.assemble.*` 随 `loader.v`/`assemble.v` 注释登记
