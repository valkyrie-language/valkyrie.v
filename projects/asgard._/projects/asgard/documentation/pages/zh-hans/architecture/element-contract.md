# 跨平台元素体系与后端绑定合同

本文定义 Asgard 的抽象元素层、元素到后端的绑定机制、宿主能力合同与迁移路径。配套数据表见 [元素能力矩阵](element-capability-matrix.md)。流水线与制品形态归 [GUI 统一编译架构](gui-compilation.md)，渲染策略取舍归 [UI 渲染策略](ui-rendering.md)，本文不重复其内容，只定义元素语义与绑定。

## 0. 分层总览

两条独立的轴，加一个架在轴上的抽象层：

- **轴一：宿主**：浏览器（纯 web）/ native 应用。
- **轴二：渲染策略**：引擎托管 / 系统控件 / 自绘。

**DOM 不是环境，而是引擎托管策略的文档模型。** 浏览器宿主与 native webview 宿主承载同一套 DOM 语义；`<div>` 这类 HTML 元素是引擎托管策略的逃生口，不是「web + native」的并集。

| 宿主 \ 策略 | 引擎托管 | 系统控件 | 自绘 |
|:---|:---|:---|:---|
| 浏览器 | **主形态**：DOM 直出 | 不可用（编译期拒绝） | 仅限 `Canvas` 元素内 |
| native | webview 宿主承载同一 DOM 语义 | **主形态**：抽象元素映射平台控件 | GPU/画布表面（`asgard.bifrost`） |

**抽象元素层**：作者写的同一棵抽象树（`Column`/`Text`/`Button`…），按目标的（宿主 × 策略）组合分别发成 DOM、映射系统控件或自绘。抽象层不携带任何策略私有事实；策略差异全部经绑定层进入。

**宿主层（webview 路径）与控件绑定层（真原生路径）分开**：webview 路径只需要窗口、事件循环、embed webview、本地资源装载、IPC 桥、生命周期——渲染全在 web 侧，**不需要** widget→原生控件映射；控件绑定层后补，不阻塞 webview 路径。两层都是「合同 + 每平台 provider」形态，见 §4、§5。

## 1. 现状清单

以下为本设计的输入事实（`rusty-valkyrie` 包内路径，行号为撰稿时快照）。已存在的硬编码点即后续迁移项，本轮不改。

### 1.1 元素识别与分类

| 站点 | 现状 |
|:---|:---|
| `src/asgard/awsl/render_ir/surface.rs:10-17` | `TemplateNodeKind` 三分：`Component` / `Intrinsic` / `HostView` |
| `src/asgard/awsl/render_ir/surface.rs:124-153` | **硬编码**：`is_intrinsic_tag` 名称表，识别 `Column/Box/Row/Text/Button/Input/Flex/Slot/List/Item/Checkbox/Radio/RadioGroup`（含小写变体） |
| `src/asgard/awsl/lower.rs:467-476` | **硬编码**：`classify_tag`——先查名称表，再按 PascalCase 启发式判用户组件，否则 HostView |
| `src/asgard/awsl/render_ir/canonical.rs:56-67,214-217` | canonical RenderIR 的 `RenderElement` 携带 `tag: String` + `kind`；`is_intrinsic_tag` 转发到 surface 层 |
| `src/asgard/codegen/mobile_ui_binary.rs:198-201,492-494` | wire 格式把三分 kind 编码为 1/2/3 写入制品 |

### 1.2 属性与绑定

| 站点 | 现状 |
|:---|:---|
| `src/asgard/awsl/lower.rs:429-464` | 属性三形态：静态 / 动态表达式源码 / 混合片段；`@x` 与 `on:x` 标事件；组件节点上非标事件的属性标 prop；`:class`/`:style` 指令合并进 `class` |
| `src/asgard/awsl/lower.rs:385-425` | 结构构造：`@if` 指令、`<if condition>` 元素、`<loop items item key>` 元素、`<fragment>` |
| `src/asgard/awsl/abi_index.rs:18-97` | 组件 ABI 校验：`:prop`/`@event` 对照目标组件 script 提取的 ABI（`[property]`、micro 方法）；snake_case 规范化 |
| `src/asgard/codegen/ssg_ovm/admission.rs:29-51` | SSG 准入门：`isActive(...)` 显式拒绝；**`each=`/`:each=` 魔法属性迭代写法硬拒绝**（非语言构造） |
| `src/asgard/awsl/expr_deps.rs` | **硬编码**：响应式依赖靠字符扫描提取；`src/asgard/codegen/v_render/codegen.rs:48` 另有 `get_`/`count_`/`todos(` 字符串探测补依赖 |

### 1.3 发射与 hydration

| 站点 | 现状 |
|:---|:---|
| `src/asgard/codegen/html_render.rs:197-210` | **硬编码**：`map_html_tag`——Intrinsic→HTML（`Text→span`、`Button→button`、`Column/Box/Row/Flex→div`）；Component→`div`（`Link→a`）；HostView→小写透传 |
| `src/asgard/codegen/ssg_ovm/emit.rs:242-253` | **硬编码**：`map_host_tag` 与上表同形，经 `asgard.render` 合同族（`dom_create_element` 等）由 OVM 执行产出静态 HTML |
| `src/asgard/codegen/v_render/codegen.rs:288-291` | **硬编码**：hydration 路径同一映射的第三份拷贝 |
| `src/asgard/codegen/v_render/util.rs:9-18` | **硬编码**：`map_awsl_component_to_host`（`Link/Badge/Avatar/Input/Button` 组件→HTML 标签） |
| `src/asgard/codegen/mp_render.rs:226-243` | **硬编码**：小程序 WXML 映射（`Text→text`、`Button→button`、HostView 白名单、其余落 `view`） |
| `src/asgard/codegen/android_compose_runtime.rs:118-123`、`ios_swiftui_runtime.rs:315-324` | **硬编码**：按 `Column/Row/Text/Button` 名字符串分派 Compose/SwiftUI 控件 |
| `src/asgard/codegen/v_prelude.rs:4-42` | hydration 侧 DOM 操作以 `[js_builtin]` 前导声明（`document.createElement`、`Element.setAttribute`、`addEventListener` 等）；`:44-60` 还混入 `get_all_posts` 等业务占位函数 |
| `src/asgard/codegen/reactive_prelude.rs:5-39` | 响应式信号表经 `[js_builtin("__voa.*")]` 绑定到 `boot.js` |
| `src/asgard/codegen/js_boot.rs` | 浏览器 boot：信号订阅、表达式绑定、事件桥 `awsl_call_*`、island 挂载/卸载作用域 |
| `src/asgard/codegen/expr_eval.rs` | **退役中**：Rust 文本表达式解释器（SSG 旧路），迁移到 `asgard.render` + OVM 后删除 |

### 1.4 V 侧已有资产（本设计的挂靠点）

| 包 | 现状 |
|:---|:---|
| `asgard.render` | DOM 树构建 `[host_contract]` 合同族（`dom_create_element`/`dom_append`/`dom_set_attr`/`dom_set_text` 等），`HostElement` 名义句柄 |
| `asgard.render.host.ovm` | 上述合同的 OVM provider，`[host_provider]` + `[gate(feature = "asgard.ssg.dom")]` 门控，缺位结构化失败 |
| `asgard.ui` | wire 编解码、`UiHost` trait（`mount`/`patch`/`on_event`）、各平台 host shim 骨架、`widgets/intrinsics.v` 仅剩三个标签名占位 |
| `asgard.ui.core` | AWSL 复合组件库（`Btn`/`Card`/`DataTable` 等，由基础元素组合而成） |
| `asgard.bifrost` | 自绘后端骨架（消费共享图形栈） |

**结论**：元素语义当前唯一事实源是 Rust 侧名称表与映射表（同一映射至少四份拷贝），V 侧 `asgard.ui` 的 widget 合同层空缺。本设计把元素语义移入 V 库声明，绑定层取代映射表拷贝。

## 2. 抽象元素分类

分类按**语义角色**而非呈现手段组织。每类给出：抽象名、属性面、状态面、事件面、可访问性语义、布局参与方式。属性拼写（类型、默认值）由正式 V SDK 冻结，此处只定义合同面。

### 2.1 结构 / 容器

| 元素 | 语义 | 必选属性 | 可选属性 | 事件面 | 可访问性 | 布局参与 |
|:---|:---|:---|:---|:---|:---|:---|
| `Column` | 纵向流式排列 | — | 间距、主轴/交叉轴对齐、内边距、子项权重 | 无（容器不产生交互事件） | 默认 group 语义，不抢角色 | 主动方：测量并排列子节点 |
| `Row` | 横向流式排列 | — | 同上 | 无 | 同上 | 同上 |
| `Stack` | 叠层（z 向层叠） | — | 层内对齐 | 无 | 同上 | 主动方：子节点同区域叠放 |
| `Grid` | 二维网格 | 轨道定义 | 间距、子项占位 | 无 | 同上 | 主动方 |
| `Scroll` | 滚动视口 | 单个子节点 | 轴向、滚动条可见性 | 滚动位置变化（意图型，可取消性按平台） | 视口角色 | 双向：对父报价受限，对子放开一轴 |

**为什么不是照 HTML 抄**：HTML 没有布局容器元素，布局靠 `div` + CSS 默认行为反推；把 `div` 改名 `Column` 仍让浏览器默认样式承担布局不算跨平台实现。容器元素在这里是布局语义的**定义方**，DOM 后端的 flexbox/grid 是降低结果，原生/自绘后端各自实现同一测量与排列合同。

### 2.2 文本

| 元素 | 语义 | 必选属性 | 可选属性 | 事件面 | 可访问性 | 布局参与 |
|:---|:---|:---|:---|:---|:---|:---|
| `Text` | 文本块（行内片段的容器） | —（内容为子节点） | 截断、换行策略、选择可用性 | 无 | 静态文本语义 | 被动方：按父约束排版 |
| `Heading` | 标题 | 层级（1–6） | 同 `Text` | 无 | heading 角色 + 层级 | 被动方 |

行内混合与富文本片段是 `Text` 的子结构（带语义的 run：强调、等宽、删除线等作为 run 属性），不是独立元素。文本索引、字素/字形访问走文本层合同，不在元素层定义。

**为什么不抄 HTML**：HTML 把段落（`p`）、行内（`span`）、语义短语（`em/code`）拆成几十个标签且默认样式参杂；抽象层只保留「块 / 标题 / 行内 run」三个语义事实，呈现差异归策略实现。

### 2.3 控件

| 元素 | 语义 | 必选属性 | 可选属性 | 状态面 | 事件面 | 可访问性 | 布局参与 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| `Button` | 激活动作 | —（内容为子节点） | 禁用、kind（普通/提交/危险） | 无内部值状态 | `activate`（激活意图：点击、回车、空格、触摸等价，payload 不预设鼠标事件） | button 角色 | 被动方，自带最小固有尺寸 |
| `TextInput` | 单行文本编辑 | — | 占位、禁用、只读、输入用途（普通/密码/数字…） | **受控优先**：`value` 为输入属性；非受控须显式声明初值 | `input`（编辑中意图）/`change`（提交意图）分离 | textbox 角色 | 被动方 |
| `Select` | 选项集单选 | 选项集 | 占位、禁用 | 受控 `value` | `change` | combobox/listbox 角色 | 被动方 |
| `Switch` | 布尔切换 | — | 禁用 | 受控 `checked` | `change` | switch 角色 | 被动方 |
| `Slider` | 连续/离散数值 | 取值范围 | 步进、禁用 | 受控 `value` | `input`/`change` | slider 角色 | 被动方 |
| `Checkbox` | 布尔勾选 | — | 禁用、三态 | 受控 `checked` | `change` | checkbox 角色 | 被动方 |
| `Radio`/`RadioGroup` | 互斥单选 | 组内选项值 | 禁用 | 受控（在 Group 上） | `change`（Group 上） | radio/radiogroup 角色 | 被动方 |
| `List` | 集合展示（可虚拟化） | 数据源 | 项模板、选中模式 | 选中态受控 | `select` | list/listitem 角色 | 双向：一轴放开 |
| `Table` | 二维数据 | 列定义 + 数据源 | 排序、选中 | 选中/排序受控 | `select`、`sort` | table 角色族 | 被动方 |

**为什么不是照 HTML 抄**：HTML 控件的值语义绑死表单模型与 DOM 事件对象（`MouseEvent`、`submit` 默认行为）；抽象层的值控件是「受控属性 + 意图事件」合同，激活涵盖键盘、触摸、焦点与辅助技术，payload 不含浏览器事件形状。

### 2.4 媒体

| 元素 | 语义 | 必选属性 | 可选属性 | 事件面 | 可访问性 | 布局参与 |
|:---|:---|:---|:---|:---|:---|:---|
| `Image` | 位图/矢量图展示 | 来源、替代文本 | 缩放适配、懒加载 | `load`/`error`（资源意图） | img 角色，替代文本强制 | 被动方，带固有尺寸 |
| `Icon` | 语义命名图标 | 图标名 | 尺寸、色调 | 无 | 默认装饰性（对辅助技术隐藏），须显式声明语义标签才暴露 | 被动方 |
| `Canvas` | 自绘表面逃生口 | 尺寸 | 像素比、色彩空间 | 指针/键盘原始事件（该区域放弃抽象语义） | 须显式提供等价文本/角色，否则标记为纯呈现 | 被动方 |

`Canvas` 同时是浏览器宿主内唯一合法的自绘位置：抽象树在浏览器 × 自绘组合下只允许落在 `Canvas` 子树内。

### 2.5 语义 / 可访问性

可访问性**不是独立元素类**，而是所有元素的强制语义面，三个正交属性面：

- `role`：覆盖默认角色（默认角色由元素语义给出，见各表；`role` 是显式覆盖口）；
- `label`：可读名（未提供时从内容推导，推导规则归策略实现）；
- `state`：语义状态（展开/选中/ busy…），与控件值状态分离。

另设少量语义元素：`Region`（landmark 区域：导航/主区/补充/页脚）、`Link`（导航意图，link 角色；与 `Button` 的语义边界是「导航 vs 动作」）。

**原生对齐方式**：引擎托管策略按 HTML-AAM 思路由 DOM 标签 + ARIA 反射承载；系统控件策略由平台控件自带的无障碍接口承载（UIA / AXAPI / AT-SPI），元素默认角色即映射依据；自绘策略须自建无障碍桥（责任缺口，见矩阵）。

## 3. 后端能力矩阵

完整二维矩阵（宿主 × 策略 × 逐元素 × 责任分工）在 [元素能力矩阵](element-capability-matrix.md)。矩阵是数据：每格标「平台原生对应物 / 近似实现（注明缺口）/ 不支持（结构化诊断代码）」，共享代码不按后端写分支特判——分支只允许出现在各策略的 provider 包内。

## 4. 绑定机制

与 std 的 `[host_contract]`（合同 + 可选默认实现）/ `[host_provider]`（目标 provider）同构，分三层：

### 4.1 三层事实

1. **抽象元素声明（合同侧，归 `asgard.ui`）**：每个抽象元素是普通 V `widget` 声明，携带属性、事件、slot、布局与可访问性默认语义。用户 `using asgard.ui` 后按普通声明解析参与重载与覆盖；未声明的元素名在模板中即未解析引用，结构化失败。
2. **策略实现声明（provider 侧，归各适配包）**：绑定单元是 **(元素身份, 渲染策略, 目标条件) → 实现**。三类实现形态：
   - **引擎托管**：元素 → DOM 标签 / 角色 / 属性映射 / 事件映射的**数据表**，由 V 包持有（DOM 适配包），DOM codegen 消费该已冻结数据，不再内嵌名称表；
   - **系统控件**：元素 → 平台控件身份 + 属性桥 + 事件桥，经 `asgard.host.*` 宿主合同族调用（创建/属性/销毁/事件订阅），控件生命周期遵循「创建 → 属性同步 → 事件回传 → 拆除」四段；
   - **自绘**：元素 → 消费共享图形栈的 V 实现（`asgard.bifrost` 线）。
3. **选择（编译期）**：与 host provider 同一套规则——按正式 target registry 投影环境，`when`/`gate` 表达条件；候选唯一才绑定，多候选报歧义，无候选 fail-closed。

### 4.2 fail-closed 口径

- 任一抽象元素在目标（宿主 × 策略）下无实现：**编译期结构化诊断**（元素身份、策略、目标、缺失面），构建失败；**不静默落到某个默认渲染**（例如不许把未知元素降成 `div`/`view`）。
- 同一（元素, 策略, 目标）出现多个实现：歧义诊断；不允许并行语义。
- 默认实现只有经合同明确定义才可参与选择（同 std host contract 的默认实现规则）。

### 4.3 逃生口：HTML / 自定义元素

- 小写 HTML 标签（`div`、`h1`、…）与 custom element **不是抽象元素**，属引擎托管策略的私有面。
- 合法条件二合一：**显式 capability import**（`using asgard.web` 一类）**且**目标策略为引擎托管；其余目标编译期结构化拒绝，指出该用法绑死引擎文档模型。
- 自定义元素 / 第三方组件接入方式：在该 capability 包内做**声明式注册**（标签名、属性表、事件表、表单关联、默认角色），注册数据只喂养引擎托管后端；抽象层与其它策略不出现其痕迹。
- SVG 同口径：独立 capability 包，不混入抽象元素集。

### 4.4 用户组件

用户 `.awsl` widget 是抽象层的**组合体**（抽象元素 + 用户 widget 构成树），组件识别只由 frontend 已解析声明身份——名称表与大小写启发式都在清退之列。组件 ABI（`[property]`、事件、slot）校验已有雏形（`abi_index.rs`），迁入正式 frontend 事实。

## 5. 宿主能力合同（与元素渲染正交）

以下为**宿主层**合同族，不是元素，不进能力矩阵：系统窗口、多窗口、托盘、菜单栏、文件对话框、剪贴板、通知、GPU 直通、进程生命周期与退出。native 宿主可提供，浏览器宿主仅能提供引擎 API 子集（如通知经 Web API）；缺位同样 fail-closed。

**webview 宿主合同族**是其中一族，覆盖：窗口与事件循环、embed webview（平台 webview 控件由 provider 封装，抽象层不出现 WebView2/WKWebView/WebKitGTK 名词）、本地资源装载（产物映射到 webview 可访问的虚拟主机名，路径/摘要/MIME 由打包合同冻结）、JS↔native IPC 桥（窄、类型化、可取消）、生命周期与退出（关闭/崩溃/重载的取消与清理）。该族不含任何控件映射——渲染语义与浏览器宿主同一套引擎托管。

合同形态复用 `[host_contract]` + 每平台 provider；浏览器目标对窗口类能力无 provider 即结构化失败，不静默降级。

## 6. 与现有语法的关系

- `<loop>`、`<if>`、`<fragment>` 是合法**结构指令节点**（条件与列表 region、key 语义归响应式合同），不是元素，不参与本绑定机制。
- 把语义藏进属性名的指令式写法（`each=` 一类）**已判定非法**：SSG 准入门已硬拒绝（`ssg_ovm/admission.rs:39-51`），本设计不为其留任何位置；集合渲染经 `<loop>` 或 `List`/`Table` 的数据源属性合同表达。
- `@event` / `:prop` / `{expr}` 首轮视图沿用；事件必须引用已编译声明，不放内联匿名片段。

## 7. 可组合性与扩展

### 7.1 新增 widget 检查表

1. 在 `asgard.ui` 以普通 widget 声明：属性（必选/可选、受控形态）、事件、slot、布局参与方式、默认角色；
2. 为每个目标策略提供实现或显式缺口声明（引擎托管映射表行 / 系统控件桥 / 自绘实现）；
3. 能力矩阵加行，标注各格实现方式与责任分工；
4. 复合组件优先放 `asgard.ui.core`（纯组合，不动核心）；
5. 验收：缺实现的组合按 §4.2 fail-closed；DOM 链既有行为不变。

改动面：合同包 + 每个要支持的策略适配包 + 矩阵数据。**不动** frontend、codegen 共享代码。

### 7.2 新增后端（策略或平台）检查表

1. 明确（宿主 × 策略）组合身份，注册进正式 target registry 投影；
2. 提供该组合下全部抽象元素的实现（或让缺失按 §4.2 显式失败）；
3. 引擎托管类后端：消费 V 侧 DOM 映射数据表 + `asgard.render` 合同族的宿主绑定；
4. 系统控件类后端：实现控件生命周期四段 + 属性/事件桥 + 平台无障碍接口对接；
5. 自绘类后端：实现绘制、命中测试、文本排版、无障碍桥、IME 候选框、主题与 DPI 六项责任，缺项在矩阵标为缺口；
6. 宿主能力合同族（窗口/IPC/生命周期…）逐族给出 provider 或显式拒绝；
7. 验收：同一跨平台 fixture 页在该后端真实运行，逐元素核对矩阵承诺。

## 8. 迁移路径

按 **抽象层 → DOM 后端 → 最小 native 宿主层 → 原生控件映射** 的顺序；每步不破坏已工作的 DOM 交付链。

- **第 0 步｜冻结合同（本轮）**：本文 + 能力矩阵落盘；不改代码。兼容性影响：无。诊断策略：无。
- **第 1 步｜V 侧抽象元素声明**：在 `asgard.ui` 建立 §2 元素集的 widget 声明与默认角色/状态/事件合同；DOM 映射数据表迁入 V 包。验收：每元素有可解析声明身份与 V 侧 ABI；模板消费未声明元素即结构化失败。兼容性：作者面不变（仍写 `<Column>` 等）；诊断新增「未知元素」错误。
- **第 2 步｜lowering 消费声明身份，清退名称表**：模板降级改由 frontend 已解析身份识别组件与元素；删除 §1.1/§1.3 列出的全部名称表、PascalCase 启发式与四份映射拷贝，DOM 各 codegen 改读 V 侧映射数据。验收：跨平台正向 fixture 与静态构建套件全绿；浏览器交互链（事件→状态→DOM）逐场景回归；`html_render`/`expr_eval` 退役线随消费方迁移关闭。兼容性：DOM 产物可观察行为不变；诊断从「名字未命中落小写透传」改为「未解析引用失败」。
- **第 3 步｜最小 native 宿主层（webview 路径真跑起来）**：定义 §5 的 webview 宿主合同族，选定一个平台一个壳技术实现 provider；桌面 target 沿用减枝后直接生成未分割产物。验收：打包应用干净安装冷启动、真实点击/键盘事件往返、全部资源本地可装载（虚拟主机名映射）、离线启动、窗口关闭的取消与 dispose、禁止远程导航与未授权宿主调用。**此步即 webview 路径可运行点**——元素渲染复用引擎托管策略，本步不含任何控件映射。兼容性：浏览器交付链不变；新增桌面 target 的合法组合。
- **第 4 步｜原生控件映射（系统控件策略）**：按能力矩阵逐元素为一个代表平台提供系统控件 provider，其余组合保持显式失败。验收：逐元素核对绘制/命中/无障碍/IME/主题责任由平台承载的证据（平台无障碍检查器、输入法候选框实测）；缺项元素显式拒绝而非近似冒充。兼容性：不影响 DOM/webview 链。
- **第 5 步｜自绘策略**：`asgard.bifrost` 线按矩阵六项责任逐项关闭（无障碍桥与 IME 为独立验收门）。验收含截图比对以外的行为断言。

每步的退出都含「未完成组合按 §4.2 显式失败」，不以旧名称表兜底。

## 9. 外部借鉴与放弃

逐条注明借鉴点、放弃点与理由（来源均为官方规范/文档，未核实处明示）：

1. **W3C Web Components**：借鉴 customized built-in「保留内建行为」思路——抽象元素自带默认角色/状态语义，作者可显式覆盖（同 `ElementInternals` 默认 role 可被页面作者覆盖的模型）；放弃 shadow DOM 封装作为跨平台合同——它是引擎托管私有机制，系统控件与自绘策略无对应物。（html.spec.whatwg.org/multipage/custom-elements.html）
2. **WAI-ARIA 1.2 / HTML-AAM**：借鉴 role/state/property 三元本体作为 §2.5 语义面模型，借鉴 HTML-AAM 逐平台映射表的形态建模能力矩阵的无障碍维度；放弃把 HTML 标签当语义来源——HTML-AAM 整份规范正是「从标签反推语义」的工作，证明标签不是语义真相源。（w3.org/TR/wai-aria-1.2、w3.org/TR/html-aam）
3. **XAML / WinUI**：借鉴 `Control` 基类几乎无行为、外观归模板的分离——抽象元素只携带语义与状态面，呈现归策略实现；借鉴依赖属性系统对值变化的统一追踪（与响应式合同同构）；放弃 `{Binding}`/`{x:Bind}` 双轨并存——单一绑定语义，不养两套。（learn.microsoft.com WinUI Control / dependency properties / x:Bind 文档）
4. **SwiftUI `UIViewRepresentable`**：借鉴 `makeUIView`/`updateUIView`/`dismantleUIView` + `Coordinator` 事件回传——§4.1 系统控件实现的生命周期四段直接对应（macOS 侧 `NSViewRepresentable` 正文未核实，按同族处理）；放弃其「框架接管 frame、业务直改为未定义行为」的含糊边界——Asgard 要求每个元素显式声明布局参与方式（§2 各表）。（developer.apple.com/documentation/swiftui/uiviewrepresentable）
5. **Flutter**：借鉴「控件由框架自绘、行为与 OS 版本解耦」作为自绘策略的定位论据；借鉴 platform view 三模式的无障碍教训（texture layer 丢失无障碍，hybrid composition 才正确）——嵌入与自绘的无障碍在矩阵中是显式责任项而非默认存在；放弃不可变 widget + `build()` 重跑模型——Asgard 是编译期静态结构 + 已编译绑定更新，不做整树重建。（docs.flutter.dev architectural-overview / platform-views）
6. **Qt QML**：借鉴属性绑定的依赖自动追踪（与 reads/writes 失效传播同构）与 `QML_ELEMENT` 显式注册 + 元数据交换的类型暴露方式（§4.4 声明式注册同思路）；放弃「JS 语句赋静态值静默解除绑定」的语义——Asgard 状态面必须显式声明受控/非受控。（doc.qt.io qtquick / qtqml-cppintegration / propertybinding）
7. **React Native（Fabric）**：借鉴 Codegen 以声明为单一事实源生成两端强类型绑定、props 不匹配即构建错误——§4.2 的 fail-closed 与「绑定由声明生成」直接对应；借鉴 JSI 取代 JSON 序列化桥的方向（ABI 类型化，「bridgeless」术语未核实）；放弃 Yoga 作为共享布局合同——布局语义归抽象层合同，各策略自实现。（reactnative.dev architecture/fabric-renderer、fabric-native-components）
8. **Jetpack Compose / Compose Multiplatform**：借鉴「@Composable 发射 UI 而非构造对象、recomposition 跳过未变部分」与 region 级绑定更新的同构性；借鉴 `AndroidView`/`AndroidViewBinding` 逃逸舱口的显式性（对应 §4.3）；放弃 Compose Multiplatform 「单一渲染引擎覆盖全平台」的取向（其 iOS/Web 映射细节未核实）——Asgard 三策略并存、逐格诚实标缺口。（developer.android.com compose mental-model / views-in-compose；jetbrains.com compose-multiplatform）
