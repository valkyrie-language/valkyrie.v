namespace panduck;

# panduck — 文档转换编排（Valkyrie 实现）
#
# 转换管线：read → 文档 IR → transform passes → write，产出 `panduck.report/v0`
# 诚实损失报告。格式解析归 `std.data.*`，文档 IR 归 `notedown`；
# 本包拥有转换路由、transform 编排与 report 线格式模型。
