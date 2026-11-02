namespace template;

using std.types::{Option};

# template — Valkyrie 模板渲染核心包（只做渲染，不含解析）。
#
# 输入是 `std.data.text` 的公共模板 AST（由 `std.data.text.<dialect>` 方言包的
# 三段管线产出），输出为纯内存求值文本：
#
#   template_render(document, context, settings) -> DataOutcome<utf8>
#
# 渲染侧配置（本包职责）：上下文帧栈与作用域查找顺序、表达式求值、过滤器/函数/测试
# 注册表与内建集合、HTML 转义与安全文本、真值判定、undefined 严格模式、
# 循环元数据（`forloop`）绑定。本包不读文件、不访问网络、不取当前时间；
# partial 装配与 loader 尚未接入。
