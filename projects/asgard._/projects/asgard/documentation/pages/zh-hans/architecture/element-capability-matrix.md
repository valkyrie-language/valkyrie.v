# 元素能力矩阵

本表是 [跨平台元素体系与后端绑定合同](element-contract.md) 的配套数据。两个独立轴：**宿主**（浏览器 / native 应用）× **渲染策略**（引擎托管 / 系统控件 / 自绘）。抽象元素层在两轴之上；同一棵抽象树按合法组合分别降低。

## 1. 组合合法性

| # | 宿主 | 策略 | 合法性 |
|:---:|:---|:---|:---|
| C1 | 浏览器 | 引擎托管（DOM 直出） | ✅ 主形态 |
| C2 | 浏览器 | 自绘 | ⚠️ 仅限 `Canvas` 元素子树内（GPU/2D 画布） |
| C3 | 浏览器 | 系统控件 | ✗ 不可用——模板含系统控件专属能力时编译期结构化拒绝 |
| C4 | native | 引擎托管（webview） | ✅ 与 C1 同一套 DOM 语义；宿主层走 webview 宿主合同族 |
| C5 | native | 系统控件 | ✅ 主形态（控件绑定层，后补于 webview 路径） |
| C6 | native | 自绘（GPU/画布表面） | ✅ `asgard.bifrost` 线 |

## 2. 责任分工基准（按策略）

五项责任：**绘制 / 命中测试 / 无障碍语义 / 输入法与文本度量 / 主题与 DPI**。`平台` = 平台引擎或平台控件承担；`框架` = Asgard 运行时承担。

| 责任 | 引擎托管 | 系统控件 | 自绘 |
|:---|:---|:---|:---|
| 绘制 | 平台（浏览器引擎） | 平台（控件自绘） | **框架** |
| 命中测试 | 平台 | 平台 | **框架** |
| 无障碍语义 | 平台（元素→角色映射经引擎无障碍树暴露） | 平台（UIA / AXAPI / AT-SPI 由控件自带） | **框架**（须自建无障碍桥，重缺口） |
| 输入法与文本度量 | 平台 | 平台 | **框架**（IME 候选框定位为已知缺口） |
| 主题与 DPI | 平台 | 平台 | **框架** |

逐元素的例外缺口见 §4。任一元素在某策略下缺任一项责任，即构成该格的明确缺口，不允许含糊成「支持」。

## 3. 元素 × 组合主表

格子内容：**原生对应物**（系统控件列给 WinUI / AppKit / Android 代表）｜**近似实现**（注明缺口）｜**不支持 → 结构化诊断**。引擎托管两格（C1/C4）语义同一套，统一写 DOM 降低结果；C4 的差异只在宿主层（窗口/资源装载/IPC），不在元素层。

| 元素 | C1 浏览器·引擎托管 | C2 浏览器·自绘 | C4 native·引擎托管 | C5 native·系统控件 | C6 native·自绘 |
|:---|:---|:---|:---|:---|:---|
| `Column` | 块级容器 + flex 列向（数据表） | ✗ 诊断：容器不入画布 | 同 C1 | `StackPanel`（纵向）/ `NSStackView` / `LinearLayout` | 框架纵向布局原语 |
| `Row` | 块级容器 + flex 行向 | ✗ 同上 | 同 C1 | `StackPanel`（横向）/ `NSStackView` / `LinearLayout` | 框架横向布局原语 |
| `Stack` | 容器 + 层叠定位 | ✗ 同上 | 同 C1 | 近似：`Grid` 同格叠放 / `NSView` 子视图叠放 / `FrameLayout`（缺口：层序语义须显式） | 框架叠层原语 |
| `Grid` | CSS grid 容器 | ✗ 同上 | 同 C1 | 近似：`Grid` 行列定义 / 无直接对应（`NSGridView` 近似）/ `GridLayout` | 框架网格原语 |
| `Scroll` | 溢出滚动容器 | ✗ 同上 | 同 C1 | `ScrollViewer` / `NSScrollView` / `ScrollView` | 框架视口 + 剪裁（缺口：惯性/回弹曲线须合同化） |
| `Text` | 文本节点/块容器 + 行内 run | Canvas 内文本绘制（放弃选择/无障碍树，须显式等价文本） | 同 C1 | `TextBlock` / `NSTextField`（只读）/ `TextView` | 框架文本排版（缺口：整形/双向/字体回退全自重） |
| `Heading` | `h1`–`h6`（层级 → 角色） | 同上 | 同 C1 | 近似：`TextBlock` + `AutomationProperties.HeadingLevel` / 同左近似 / `TextView` + 无障碍标注 | 同 `Text`，角色经无障碍桥 |
| `Link` | `a[href]` | ✗ 诊断：交互相元素不入画布（画布内须自绘命中，放弃） | 同 C1 | 近似：`HyperlinkButton` / 带手势 `NSButton` / 带点击 `TextView`（缺口：导航语义须桥接） | 框架命中 + 导航意图 |
| `Region` | landmark 元素 + `role` | ✗ 诊断 | 同 C1 | 近似：容器控件 + UIA landmark 属性（缺口：AppKit/Android 无对等 landmark，须桥） | 框架区域 + 无障碍桥 |
| `Button` | `button` | 画布自绘（命中/焦点/键盘全自重，缺口整组） | 同 C1 | `Button` / `NSButton` / `Button` | 框架按钮（缺口：五项责任全自重） |
| `TextInput` | `input[type=text]` 等 | ✗ 诊断：IME 候选框与文本度量不可在画布内合格自建（浏览器内） | 同 C1 | `TextBox` / `NSTextField` / `EditText` | 框架输入（**重缺口**：IME 候选框、选择、光标、度量全自重） |
| `Select` | `select` | ✗ 同上 | 同 C1 | `ComboBox` / `NSPopUpButton` / `Spinner` | 框架弹层 + 列表（缺口：弹层窗管） |
| `Switch` | 近似：`button[role=switch]` + 状态样式（缺口：无原生标签） | 同 `Button` 口径 | 同 C1 | `ToggleSwitch` / `NSSwitch` / `SwitchMaterial` | 框架开关 |
| `Slider` | `input[type=range]` | 同 `Button` 口径 | 同 C1 | `Slider` / `NSSlider` / `SeekBar` | 框架滑杆 |
| `Checkbox` | `input[type=checkbox]` | 同上 | 同 C1 | `CheckBox` / `NSButton`（switch 形）/ `CheckBox` | 框架勾选 |
| `Radio`/`RadioGroup` | `input[type=radio]` + `fieldset` | 同上 | 同 C1 | `RadioButton` 组 / `NSButton`（radio 形）/ `RadioGroup` | 框架互斥组 |
| `List` | 近似：`ul/li` + `role=listbox` 或虚拟化容器（缺口：虚拟化须框架补） | ✗ 诊断 | 同 C1 | `ListView` / `NSTableView`（单列）/ `RecyclerView` | 框架虚拟化列表（缺口：回收/预取策略自重） |
| `Table` | `table` 元素族 | ✗ 诊断 | 同 C1 | 近似：`DataGrid`（工具包控件）/ `NSTableView` / 无原生（组合 `RecyclerView`，缺口：列模型桥接） | 框架网格数据控件（缺口整组） |
| `Image` | `img[alt]`（替代文本强制） | 画布位图绘制（缺口：解码/缓存自重） | 同 C1 | `Image` / `NSImageView` / `ImageView` | 框架解码 + 绘制（缺口：格式解码矩阵须合同化） |
| `Icon` | 近似：字体/矢量 + 默认对辅助技术隐藏（缺口：语义标签须显式） | 同 `Image` 口径 | 同 C1 | 近似：字体图标/矢量资源（缺口：语义命名到平台资源的映射表） | 同左 |
| `Canvas` | `canvas`（2D/GPU 上下文） | —（即本策略入口） | 同 C1 | 近似：`SwapChainPanel`/Win2D / 自绘 `NSView` / `SurfaceView`（缺口：合成层级与生命周期桥） | —（即本策略入口） |

## 4. 逐元素例外与缺口说明

- **C2（浏览器·自绘）** 只覆盖 `Canvas` 子树与 `Text`/`Image`/`Icon` 的有限自绘场景；交互控件落入 C2 一律结构化诊断（命中/焦点/键盘/无障碍树在画布内无法达合同）。
- **`TextInput` 在 C6（native·自绘）是最大缺口**：IME 候选框定位、选中区、光标的全部责任在框架；该格在 IME 桥闭合前只可作为显式声明的受限能力交付。
- **无障碍在 C6 全线自重**：须自建对接 UIA/AXAPI/AT-SPI 的无障碍桥；Flutter platform view 的 texture-layer 模式丢失无障碍是前车之鉴（hybrid composition 因原生视图留在系统视图层级才正确）——故嵌入原生控件的呈现模式选择以无障碍正确性为门禁。
- **`Region`/landmark 在 AppKit/Android 无对等概念**：系统控件格以近似 + 桥接标注，不作为阻塞；无桥接前该组合显式降级诊断。
- **`Table` 在 Android 无原生对应物**：近似实现须声明列模型桥接缺口；不接受用 `List` 冒充 `Table`。
- **未知/未声明元素**在所有组合下统一 fail-closed：编译期诊断指出元素身份、目标组合与缺失实现，不静默落默认渲染。

## 5. 宿主能力合同（独立一节，不在矩阵内打混）

系统窗口、多窗口、托盘、菜单栏、文件对话框、剪贴板、通知、GPU 直通、进程生命周期与退出属**宿主层合同**（`asgard.host.*` 合同族 + 每平台 provider），与元素渲染策略正交：同一宿主能力在任何渲染策略下可用性一致。浏览器宿主只能提供引擎 API 子集；webview 宿主经 webview 合同族获得窗口/资源装载/IPC/生命周期。缺位一律 fail-closed。

## 6. 数据化说明

本表后续可机械转为数据文件（元素 × 组合 × 实现方式 × 责任分工五元组），供编译期绑定选择与诊断生成共用同一份事实，避免矩阵文档与实现漂移。
