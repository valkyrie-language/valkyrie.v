# CLR 后端

CLR 的 IL、metadata 与托管对象表示由目标私有计划表达，不改变语言语义或当前题目矩阵范围。

## 输入合同

```text
Canonical + RepresentationPlan → CLR BackendPrivatePlan
  → pre-encode validation → PE/CLI format encoding → assembly
```

linker 冻结 adaptor/import，表示规划冻结 carrier/layout；backend 安排 token、方法体和程序集数据。语言 nominal instance、field/variant、复制语义与 evidence 由上游提供，不按宿主类型名或字段形状补全。

runtime 只消费产物，不依赖 AST/frontend；正式编译不能以 body_source 重解析、宿主代编译或类型名特判绕过 Compiler。

## 验收

缺调用、签名、layout 或能力在所属边界失败。程序集格式正确不代表真实入口与题意通过；须执行实际产物。专题合同不宣称完整 CLR 或自举已经实现。
