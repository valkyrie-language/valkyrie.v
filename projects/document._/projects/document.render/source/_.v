namespace document.render;

# document.render — `document.*` 核心渲染管线。
#
# 管线（R16）：`document_validate` 预检 → `document_index` 编号 → 目标发射；
# 任一硬失败即 `Fail`，不产半成品。输出目标以具体渲染器函数提供
# （HTML / 纯文本 / Markdown），trait 抽象在消费方出现后落地。
#
# 输出约定：
# - HTML 目标是连续流，不分页（R17）；属性一律单引号拼写，与
#   `document.vector` 的矢量输出同政策；文本与属性值按 R18 转义。
# - 纯文本目标按 R21：列表标记 `-`/`1.`、缩进 2 空格/级、表格字符网格、
#   代码块 fenced、hard break 换行、soft break 空格、脚注与参考文献各自成区。
# - 输出是确定性文本：同输入同字节；元素间不写多余空白。
