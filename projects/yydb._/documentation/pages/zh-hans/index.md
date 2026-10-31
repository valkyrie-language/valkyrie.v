# yydb 单机数据库 workspace

`yydb._` 是 `yydb` 的产品 workspace，与 `yyds._`（分布式数据库）物理分离。

## 产品特性

- 单机数据库
- 嵌入式、本地优先，适合 sidecar 与缓存场景
- 带 KV 高速缓存能力

## 边界约束

- `yydb` 可作为 `yyds` 的 sidecar 高速缓存，但不被视为 `yyds` 的一部分
- 二者可升降级、迁移、复制与数据搬运，但必须物理拆包，避免退化成单体数据库
