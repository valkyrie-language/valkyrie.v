namespace document.markdown;

# document.markdown — markdown 子集：源文本 → `document` 模型 → HTML。
#
# 解析：行级块扫描 + 行内扫描，错误容许（未闭合行内标记按字面量处理）。
# 编排：标准块/行内发射委托 `document.render`；扩展点经模型的开放扩展面
# （`classes`/`attributes`）承载——mermaid 代码块按 `language` 拦截，
# 数学片段按 `classes` 含 `math`/`math-display` 拦截（`attributes` 的 `tex`
# 键携带源文本）。失败走 `std.data` 三态 + `std.diagnostic`，不 panic。
