# yydb

`yydb` 是单机数据库：嵌入式、本地优先、带 KV 高速缓存能力。

## 定位

- 存储内核复用 `yyds.kv` 的分片合同
- 可作为 `yyds` 的 sidecar 高速缓存，但与 `yyds` 物理拆包

## 当前状态

规划中，待 `database` 抽象层与 `yyds.kv` 内核稳定后开工。
