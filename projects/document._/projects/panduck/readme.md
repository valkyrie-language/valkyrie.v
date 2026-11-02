# panduck

文档转换编排（Valkyrie 实现）。

## 定位

- 转换管线：read → 文档 IR → transform passes → write，输出 `panduck.report/v0` 诚实损失报告
- 报告是正式产物：哪些语义存活、哪些丢失，读报告先于交付

## 边界

- 不拥有格式解析：格式 lexer/parser/builder 归 `std.data.*`
- 不拥有文档 IR：归 `notedown`
- 转换路由、transform 编排与 report 模型归本包

## 当前状态

骨架落位。`panduck.report/v0` 声明层模型已起稿。
