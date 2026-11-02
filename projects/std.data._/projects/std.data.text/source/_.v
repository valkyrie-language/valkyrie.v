namespace std.data.text;

# std.data.text — 文本格式公共模型层。
#
# 只承载跨格式共享的文本语义结构（当前：公共模板 AST 模型）。本包不含任何
# 具体格式的词法/语法知识，不含渲染/求值；三段管线归 std.data.text.<dialect>，
# 渲染归 template.* 生态。
