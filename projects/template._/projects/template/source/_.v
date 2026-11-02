namespace template;

using std.types::{Option};

# template — Valkyrie 模板渲染核心包（只做渲染与装配，不含解析）。
#
# 输入是 `std.data.text` 的公共模板 AST（由 `std.data.text.<dialect>` 方言包的
# 三段管线产出），输出为纯内存求值文本：
#
#   template_render(document, context, settings) -> DataOutcome<utf8>
#   template_render_catalog(root, path, catalog, context, settings) -> DataOutcome<utf8>
#
# 渲染侧配置（本包职责）：上下文帧栈与作用域查找顺序、表达式求值、过滤器/函数/测试
# 注册表与内建集合、HTML 转义与安全文本、真值判定、undefined 严格模式、
# 循环元数据（`forloop`）绑定。装配侧配置（本包职责）：path-v1 引用策略（loader）、
# 模板源窄接口（source，待 std.vfs 落地后替换其内存目录实现）、继承链展开与
# 宏表登记（assemble）、合并表达式 arena。
# 本包不读文件、不访问网络、不取当前时间；非内存 root 一律 fail-closed。
