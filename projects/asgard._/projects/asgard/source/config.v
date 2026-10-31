namespace asgard;

# Asgard 配置 SDK：有类型配置模型的 V 端正式定义（设计 15 §3/§6、设计 16 §5，V2 工作项）。
#
# 本文件是「Asgard 配置类型面」这一事实的唯一所有者。字段集合与 Rust 侧
# `asgard::config_model::resolve_static_config` 已冻结的白名单逐层对齐：
# 根层 artifact/assets/build/serve/dev；artifact 层 target/entry/output/base/chunks；
# chunks 层 boundaries/budgets；boundary 层 component/preload/prefetch；
# budgets 层 entry_bytes/chunk_bytes；build 层 minify/source_map；serve/dev 层 host/port。
# Rust 侧只能消费本合同，不得再维护第二份字段表。
#
# 可选性约定：作者可以整体缺席、且默认值属于工具链的节（`assets`、`build`、`serve`、
# `dev`、`target`、`output`、`base`、`chunks`）以 `Option<T>` 表达；端点内可逐字段缺席
# 的 `host`/`port` 同样以 `Option<T>` 表达。SDK 不硬编码任何默认值，缺省补全属于配置
# 校验器（Rust `resolve_static_config` 的默认值面：output=dist、base=/、target=static、
# 端点 host=127.0.0.1、port=3000）。
#
# 注意：本包 `legion.von` 的包名已迁移为 `asgard`；Asgard 定义合同以 `asgard`
# 为目标命名空间（设计 16 §2/§5），包身份与本文件命名空间一致。

using core::types::{Option, Some, None};

# 产物类型。首轮唯一取值 `static`（浏览器静态站点），其它产物类型明确拒绝；缺省也是
# `static`。这是配置内的产物类型，不是 CLI/N-API 参数，也不是 V 编译器 target triple。
# 待规范：作者面拼写——设计 15 §3 示例写字符串 `"static"`，有类型路径是枚举构造子还是
# 字符串字面量须经 C0 配置求值探针冻结后进入正式规范，本文件不预先二选一。
unite ArtifactTarget {
    Static
}

# 一个可分割的组件/路由边界。`component` 必须是非空文本的稳定组件标识；
# `preload`/`prefetch` 分别控制入口 chunk 预加载与已知下一步预取，作者未声明时按
# false 处理（缺省补全属于校验器）。边界只描述允许的分包切分点，不生成任何 wasm
# 文件名或 JS import 路径。
structure ChunkBoundary {
    component: utf8
    preload: bool
    prefetch: bool
}

# 分包体积预算，单位为压缩后字节数，必须非负。未配置的维度保持缺席，SDK 与校验器
# 都不臆造数值。待规范：超预算时构建失败还是按显式警告策略报告，属构建报告合同
# （设计 15 §6.2「预算与报告」），尚未定案。
structure ChunkBudgets {
    entry_bytes: Option<usize>
    chunk_bytes: Option<usize>
}

# 分包计划：DOM static 的首屏与按需加载合同。`boundaries` 未配置时为不填充任何
# 伪边界的空列表；未配置 `chunks` 整体时不得退回无条件单体包，而应使用 DOM target
# 的默认入口/共享/按需分析策略（设计 15 §6）。
structure ChunkPlan {
    boundaries: [ChunkBoundary]
    budgets: ChunkBudgets
}

# `artifact` 层：产物种类、入口、输出位置、URL 基址与分包合同。
# `entry` 是单一根组件文件的显式相对路径（相对项目根），首轮只接受 `.w` / `.awsl`
# 后缀（同格式同语义，不做后缀优先级猜测），且必须存在。
# `output` 缺省 `dist`；`base` 是目录形 URL 基址，缺省 `/`。
structure ArtifactConfig {
    target: Option<ArtifactTarget>
    entry: utf8
    output: Option<utf8>
    base: Option<utf8>
    chunks: Option<ChunkPlan>
}

# `build` 层：优化、压缩与 source map 策略。`None` 表示作者未声明，由构建命令在配置
# 求值之后按 production/development 模式决定（development 默认关闭压缩并开启
# source map，production 相反）；求值阶段不套用模式默认。
structure BuildConfig {
    minify: Option<bool>
    source_map: Option<bool>
}

# `serve` 层：静态预览的监听端点，属于工具运行配置，不改变产物种类/入口/输出。
# 默认只监听本机（127.0.0.1:3000，补全属于校验器）。待规范：端口有效范围
# 1..=65535 的区间校验由配置校验器执行，类型面不表达区间。
structure ServeConfig {
    host: Option<utf8>
    port: Option<usize>
}

# `dev` 层：开发服务的监听端点，属于工具运行配置，不改变产物种类/入口/输出。
# 监听语义（配置/helper、`.v`、`.w`、`.awsl`、样式与资源；成功重建后整页刷新）
# 属于 dev 命令编排，不由本类型面承载。
structure DevConfig {
    host: Option<utf8>
    port: Option<usize>
}

# 根配置对象。未知字段、重复字段、错误类型与未知枚举值一律拒绝，不回退默认配置。
# `assets` 是可选静态资源目录（相对项目根），显式声明的目录不存在时报错，重名冲突
# 拒绝。不含包级 `name/version/dependencies/workspace/lock`——那些归 Legion。
structure AsgardConfig {
    artifact: ArtifactConfig
    assets: Option<utf8>
    build: Option<BuildConfig>
    serve: Option<ServeConfig>
    dev: Option<DevConfig>
}

# `asgard.config.v` 的作者入口：这是配置 SDK 提供的普通 V 函数，不是关键字、不是
# DSL、不是 CLI。参数在 V frontend 普通类型检查阶段按 `AsgardConfig` 检查，返回值
# 即文件最后表达式求出的 Valkyrie 配置对象（身份函数）。它不执行构建、不读取
# manifest、不展开版本宏、不接收 argv；名字只在配置模块最后表达式位置经 SDK 绑定
# 确认身份，不得扩展成业务 lowering 的名称特判。
# 待规范：`define_config({...})` 裸对象实参的类型导向构造须经 C0 求值探针验证；
# 探针通过前本文件只冻结声明面，不宣称求值已可运行。
micro define_config(config: AsgardConfig) -> AsgardConfig {
    return config
}
